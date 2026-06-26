#!/usr/bin/env python3
"""
message-relay.py — ai-handover v4.0 Message Relay

Reads messages from an inbox JSONL file and sends them to Slack or Discord
webhooks.  Tracks processed messages via a .processed file to avoid duplicates.

Usage:
    python message-relay.py                          # uses .ai-handover.json
    python message-relay.py --config /path/to/config.json
    python message-relay.py --inbox ./messages/inbox.jsonl
    python message-relay.py --min-priority high
    python message-relay.py --dry-run                # preview only
    python message-relay.py --help

Config file (.ai-handover.json) structure:
    {
        "webhooks": {
            "slack": "https://hooks.slack.com/services/...",
            "discord": "https://discord.com/api/webhooks/..."
        },
        "messages": {
            "inbox_path": "messages/inbox.jsonl",
            "processed_path": "messages/.processed"
        }
    }

Inbox JSONL format (one JSON object per line):
    {"id": "msg_001", "type": "review_request",   "priority": "high",    "text": "..."}
    {"id": "msg_002", "type": "blocker_raised",   "priority": "blocking", "text": "..."}
    {"id": "msg_003", "type": "status_report",    "priority": "normal",  "text": "..."}
    {"id": "msg_004", "type": "proposal",         "priority": "normal",  "text": "..."}

Message type → emoji mapping:
    review_request  → 🔍
    blocker_raised  → 🚫
    status_report   → 📊
    proposal        → 💡
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# ---------------------------------------------------------------------------
# Emoji mapping
# ---------------------------------------------------------------------------
TYPE_EMOJI = {
    "review_request": "\U0001F50D",
    "blocker_raised": "\U0001F6AB",
    "status_report": "\U0001F4CA",
    "proposal": "\U0001F4A1",
}

PRIORITY_ORDER = {"normal": 0, "high": 1, "blocking": 2}


# ---------------------------------------------------------------------------
# Config loading
# ---------------------------------------------------------------------------
def load_config(config_path: str | None) -> dict:
    if config_path:
        path = Path(config_path)
    else:
        config_candidates = [".ai-handover.json", ".ai-handover/config.json"]
        for candidate in config_candidates:
            p = Path.cwd() / candidate
            if p.exists():
                path = p
                break
        else:
            print(f"ERROR: config file not found (tried: {config_candidates})", file=sys.stderr)
            sys.exit(1)

    with open(path, encoding="utf-8") as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Inbox reading
# ---------------------------------------------------------------------------
def read_inbox(inbox_path: str) -> list[dict]:
    path = Path(inbox_path)
    if not path.exists():
        print(f"ERROR: inbox not found: {inbox_path}", file=sys.stderr)
        sys.exit(1)

    messages = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    messages.append(json.loads(line))
                except json.JSONDecodeError as e:
                    print(f"WARNING: skipping malformed line: {e}", file=sys.stderr)
    return messages


# ---------------------------------------------------------------------------
# Processed ID tracking
# ---------------------------------------------------------------------------
def load_processed(processed_path: str) -> set[str]:
    path = Path(processed_path)
    if path.exists():
        with open(path, encoding="utf-8") as f:
            return {line.strip() for line in f if line.strip()}
    return set()


def save_processed(processed_path: str, ids: set[str]) -> None:
    path = Path(processed_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        for mid in sorted(ids):
            f.write(mid + "\n")


# ---------------------------------------------------------------------------
# Webhook senders
# ---------------------------------------------------------------------------
def send_slack(webhook_url: str, payload: dict) -> bool:
    body = json.dumps({"text": payload["text"]}).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status == 200
    except (urllib.error.URLError, urllib.error.HTTPError, OSError) as e:
        print(f"ERROR: Slack webhook failed: {e}", file=sys.stderr)
        return False


def send_discord(webhook_url: str, payload: dict) -> bool:
    body = json.dumps({"content": payload["text"]}).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status in (200, 204)
    except (urllib.error.URLError, urllib.error.HTTPError, OSError) as e:
        print(f"ERROR: Discord webhook failed: {e}", file=sys.stderr)
        return False


SENDERS = {
    "slack": send_slack,
    "discord": send_discord,
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="ai-handover v4.0 Message Relay — send inbox messages to Slack/Discord"
    )
    parser.add_argument("--config", help="Path to .ai-handover.json config")
    parser.add_argument("--inbox", help="Override path to inbox.jsonl")
    parser.add_argument(
        "--min-priority",
        choices=["normal", "high", "blocking"],
        default="normal",
        help="Minimum priority threshold (default: normal)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview without sending")
    args = parser.parse_args()

    # Load config
    config = load_config(args.config)
    webhooks = config.get("webhooks", {})
    msg_config = config.get("messages", {})

    inbox_path = args.inbox or msg_config.get("inbox_path", "messages/inbox.jsonl")
    processed_path = msg_config.get("processed_path", "messages/.processed")

    # Read inbox
    messages = read_inbox(inbox_path)
    if not messages:
        print("No messages in inbox.")
        return

    # Filter by priority
    min_level = PRIORITY_ORDER.get(args.min_priority, 0)
    filtered = [
        m
        for m in messages
        if PRIORITY_ORDER.get(m.get("priority", "normal"), 0) >= min_level
    ]

    if not filtered:
        print(f"No messages at priority >= {args.min_priority}.")
        return

    # Load processed IDs
    processed_ids = load_processed(processed_path)

    # Process
    new_ids: set[str] = set()
    sent_count = 0
    skipped_count = 0

    for msg in filtered:
        mid = msg.get("id", "")
        if not mid:
            print("WARNING: message without id, skipping", file=sys.stderr)
            continue

        if mid in processed_ids:
            skipped_count += 1
            continue

        msg_type = msg.get("type", "status_report")
        emoji = TYPE_EMOJI.get(msg_type, "\u2753")
        text = f"{emoji} **{msg_type}**  [{msg.get('priority', 'normal')}]\n{msg.get('text', '')}"

        payload = {"text": text}

        if args.dry_run:
            print(f"[DRY-RUN] Would send {mid} ({msg_type})")
            new_ids.add(mid)
            continue

        # Send to configured webhooks
        success = False
        for channel, url in webhooks.items():
            if not url:
                continue
            if not url.startswith("http"):
                print(f"WARNING: Skipping {channel}: invalid webhook URL", file=sys.stderr)
                continue
            sender = SENDERS.get(channel)
            if sender and sender(url, payload):
                success = True
                print(f"Sent {mid} via {channel}")
            elif sender:
                print(f"WARNING: failed to send {mid} via {channel}", file=sys.stderr)

        if success:
            new_ids.add(mid)
            sent_count += 1
        else:
            print(f"WARNING: {mid} not sent to any webhook", file=sys.stderr)

        # Throttle
        time.sleep(0.5)

    # Persist processed IDs
    if new_ids and not args.dry_run:
        processed_ids.update(new_ids)
        save_processed(processed_path, processed_ids)
    elif new_ids and args.dry_run:
        print(f"\n[DRY-RUN] Would mark {len(new_ids)} messages as processed.")

    # Summary
    print(
        f"\nDone. sent={sent_count}, skipped={skipped_count}, "
        f"new={len(new_ids)}, total_processed={len(processed_ids)}"
    )


if __name__ == "__main__":
    main()
