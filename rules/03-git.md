---
metadata:
  title: AI Handover — Git 同步规范
  version: 1.0.0
  component: ai-handover
  status: active
  valid_at: 2026-06-26
  provenance: "ai-handover v4.1 — IRON RULE #3/#9"
  dependencies:
    - SKILL.md §Git Trailers 协议
    - SKILL.md §并行 Agent 协调
    - rules/00-core.md
    - rules/02-coordination.md
    - scripts/commit-with-trailers.sh
    - scripts/validate.sh
---

# Git 同步规范

## 1. Overview

Git 是 AI Agent 之间的协调层。每个 commit 携带结构化元数据（trailers），使所有 agent 的操作可审计、可恢复。

两条 IRON RULE 驱动本规范：
- **IRON RULE #3**：每个 commit 必须包含 `Handover-Id`、`Coding-Agent`、`Model` 三个 trailer
- **IRON RULE #9**：每个 agent 必须使用独立分支工作，禁止直接向 main 提交

## 2. 分支策略（IRON RULE #9）

### 2.1 命名规范

```
agent-<agent_id>/<type>-<description>
```

| 部分 | 规则 | 示例 |
|------|------|------|
| `agent_id` | agent 标识，含 `@` 分隔主/子 agent | `coder@build` |
| `type` | 小写连字符，限 `feat/fix/docs/refactor/chore/test` | `feat` |
| `description` | 小写连字符，2–6 个英文词 | `session-timeout` |

**完整示例**：
- `agent-coder@build/feat-session-timeout`
- `agent-researcher@build/docs-api-ref`
- `agent-orchestrator@build/fix-race-condition`

### 2.2 生命周期

```
main → git checkout -b → 本地开发 → git push → gh pr create → squash merge → git branch -d
```

| 阶段 | 操作 | 说明 |
|------|------|------|
| **创建** | `git checkout -b agent-xxx/type-desc main` | 始终从 main 最新 commit 创建 |
| **开发** | 多次 commit，每次带 trailer | 可 push 到远端备份 |
| **PR** | `gh pr create` 指向 main | PR 标题 = commit 主题 |
| **合并** | squash merge 到 main | 保持 main 线性历史 |
| **清理** | `git branch -d` 本地 + `git push origin --delete` 远端 | 合并后立即清理 |

### 2.3 隔离规则

- 每个 agent **一次只在一个分支上工作**
- 子 agent 不创建自己的分支，使用主 agent 的分支
- 不同任务必须使用不同分支名
- 禁止在 main 上直接 commit（紧急 hotfix 需经 orchestrator 批准）

### 2.4 分支名校验

```bash
# 验证分支名是否符合规范
if ! [[ "$branch" =~ ^agent-[a-zA-Z0-9@._-]+/(feat|fix|docs|refactor|chore|test)-[a-z][a-z0-9.-]{1,50}$ ]]; then
  echo "ERROR: 分支名不符合规范"
  exit 1
fi
```

## 3. Commit Trailers（IRON RULE #3）

### 3.1 完整格式

```
<主题行>

<正文（可选）>

Handover-Id: <ai-handover-handover-id>
Coding-Agent: <agent名称> <版本>
Model: <模型名称>
[Constraint: <约束条件>]
[Rejected-Alternatives: <被否方案>]
[Agent-Directive: <指令引用>]
[Verification: <验证方式>]
[Scope-Risk: <影响范围/风险等级>]
[Confidence: <置信度>]
```

### 3.2 REQUIRED Trailers（3 个）

| Trailer | 格式 | 示例 | 说明 |
|---------|------|------|------|
| `Handover-Id` | `<ai-handover-id>` | `Handover-Id: 2026-06-26_143022_fix-login` | 对应 `AI交接记录/` 目录名，不加路径 |
| `Coding-Agent` | `<工具名> <版本>` | `Coding-Agent: OpenCode v1.2.0` | **必须**，不可用 `Co-authored-by` 替代 |
| `Model` | `<模型名>` | `Model: Claude Sonnet 4` | 写代码的模型，非编排模型 |

#### IRON RULE #3 强制要求

- 缺少任何一个 REQUIRED trailer → `scripts/validate.sh` 拒绝该 commit
- trailer 必须放在 commit 消息末尾，空行与正文隔开
- `Co-authored-by` 不得用于标记 AI agent（见 §4）

### 3.3 RECOMMENDED Trailers（6 个）

| Trailer | 填写时机 | 示例 |
|---------|---------|------|
| `Constraint` | 受限于上下文窗口或 token 预算 | `Constraint: context-window-200K` |
| `Rejected-Alternatives` | 放弃了某个方案 | `Rejected-Alternatives: Redis-pubsub (latency-unacceptable)` |
| `Agent-Directive` | 来自主 agent 的指令引用 | `Agent-Directive: build-plan-§3.2` |
| `Verification` | 验证方式 | `Verification: npm-test-passed` |
| `Scope-Risk` | 影响范围和风险等级 | `Scope-Risk: auth-module/HIGH` |
| `Confidence` | 对变更正确性的信心 | `Confidence: 0.85` |

### 3.4 好与坏的示例

#### ✅ 好 commit

```
feat: add session timeout handler

Implement token refresh logic for expired sessions.

Handover-Id: 2026-06-26_143022_fix-login
Coding-Agent: Coder v1.0.0
Model: Claude Sonnet 4
Constraint: context-window-200K
Verification: npm-test-passed
Confidence: 0.92
```

#### ❌ 坏 commit（缺少 trailer / 格式错误）

```
add session timeout handler
```
— **拒绝**：无 Handover-Id、无 Coding-Agent、无 Model

```
feat: add session timeout

Co-authored-by: AI <ai@bot.com>
```
— **拒绝**：用 `Co-authored-by` 代替 `Coding-Agent`；无 `Handover-Id`

### 3.5 使用脚本

```bash
# 交互式输入
bash scripts/commit-with-trailers.sh

# 直接传参
bash scripts/commit-with-trailers.sh \
  -m "feat: add session timeout" \
  -b "Implement token refresh logic." \
  -i "2026-06-26_143022_fix-login" \
  -a "OpenCode v1.2.0" \
  -d "Claude Sonnet 4"
```

## 4. Agent Attribution

### 4.1 原则

| 字段 | 值 | 说明 |
|------|----|------|
| `Coding-Agent` | 工具名 + 版本 | 如 `OpenCode v1.2.0`、`Claude Code v0.8.0` |
| `Model` | 模型名称 | 如 `Claude Sonnet 4`、`GPT-4o` |

### 4.2 为什么不用 `Co-authored-by`

| 问题 | 说明 |
|------|------|
| **需要 GitHub email** | AI agent 没有有效的 GitHub email |
| **GitHub 统计污染** | 计入 contributions，产生虚假归属 |
| **没有 AI 署名标准** | GitHub 不支持 "AI-generated commit" 标记 |
| **混淆人类/AI 贡献** | 无法区分是人类还是 AI 写的代码 |

✅ 正确做法：始终在 commit trailers 中标注，而不是 `Co-authored-by`。

## 5. Handover-Id 查询命令

```bash
# 查找某个任务的全部 commit
git log --grep="Handover-Id: 2026-06-26_143022_fix-login"

# 列出所有 commit 及其 Handover-Id
git log --format="%H %s %(trailers:key=Handover-Id)"

# 查找某个 agent 的所有工作
git log --grep="Coding-Agent: OpenCode"

# 查找某个模型的 commit
git log --grep="Model: Claude Sonnet 4"

# 带时间过滤
git log --after="2026-06-25" --grep="Handover-Id: 2026-06-26"
```

## 6. Git 事件 → Lane 状态映射

每个 Git 操作会触发 Lane 状态转换（Lane 定义见 `rules/02-coordination.md`）。

| Git 事件 | 前状态 | 后状态 | 说明 |
|----------|--------|--------|------|
| `git checkout -b` | `idle` | `in-progress` | 分支创建表示开始工作 |
| `git commit` | 不变 | 不变 | commit 不改变 Lane 状态 |
| `git push` | `in-progress` | `needs-review` | push 表示工作完成，等待审查 |
| `gh pr create` | `needs-review` | `needs-review` | PR 创建后仍为 needs-review |
| `gh pr review --approve` | `needs-review` | `ready-for-merge` | review 通过 |
| `gh pr merge` (squash) | `ready-for-merge` | `resolved` | 合并到 main，Lane 关闭 |
| `git push origin --delete` | `resolved` | — | 清理远端分支 |
| `git branch -d` | — | — | 清理本地分支 |

### 6.1 状态停留时间警戒线

| 状态 | 最长停留 | 超时处理 |
|------|---------|---------|
| `in-progress` | 2 小时 | 输出警告，建议 checkpoint |
| `needs-review` | 4 小时 | 自动指派 reviewer |
| `ready-for-merge` | 1 小时 | 自动 merge（若配置了 auto-merge） |

## 7. 跨会话恢复协议

新 agent 进入项目时（或当前 agent 恢复会话时），按以下 7 步恢复上下文：

```
步骤 1:  读取 AI交接记录/<最新>/hot.md           → 最新进展
步骤 2:  读取 AI交接记录/索引.md                   → 项目全景
步骤 3:  git log -5 --format="%h %s"              → 最近 5 个 commit
步骤 4:  git log --grep="Handover-Id: <hot中的ID>" → 查看对应 commit
步骤 5:  检查 AI交接记录/锁/ 目录                   → 检查文件锁
步骤 6:  cat AI交接记录/active.md                  → 当前活跃任务
步骤 7:  cat AI交接记录/inbox.jsonl                 → 待办事项
```

### 7.1 恢复检查清单

```bash
# 一键恢复检查
echo "=== 1. hot.md ===" && cat AI交接记录/*/hot.md 2>/dev/null || echo "(无)"
echo "=== 2. 索引 ===" && cat AI交接记录/索引.md 2>/dev/null | head -20 || echo "(无)"
echo "=== 3. 最近 commit ===" && git log -5 --oneline
echo "=== 4. 活跃任务 ===" && cat AI交接记录/active.md 2>/dev/null || echo "(无)"
echo "=== 5. 待办 ===" && cat AI交接记录/inbox.jsonl 2>/dev/null || echo "(无)"
```

## 8. 冲突解决

### 8.1 文件冲突检测

```bash
# 在合并前检测冲突
git merge --no-commit --no-ff $branch
if [ $? -ne 0 ]; then
  echo "冲突检测到，进入解决流程"
  git merge --abort
fi
```

### 8.2 优先级规则

当多个 agent 修改同一文件时，按以下优先级裁决：

| 优先级 | Agent 类型 | 说明 |
|--------|-----------|------|
| **高** | Orchestrator | 编排层的文件修改优先 |
| **中** | Primary Agent | 主 agent 覆盖子 agent |
| **低** | Worker Agent | 子 agent 之间按 Handover-Id 时间戳裁决 |

### 8.3 解决流程

```
冲突发生
  │
  ├─ 自动部分：git 三路合并处理非重叠修改
  │
  └─ 手动部分（重叠修改）：
      1. orchestrator 读取冲突双方的最后一次 commit
      2. 比较 Handover-Id 时间戳
      3. 保留时间戳较新的版本
      4. 在文件中标注冲突来源
      5. git add + git commit（带 Conflict-Resolved trailer）
```

### 8.4 冲突后 commit

```bash
git commit -m "fix: resolve merge conflict in auth.ts

Handover-Id: 2026-06-26_150012_conflict-auth
Coding-Agent: Orchestrator v1.0.0
Model: Claude Sonnet 4
Conflict-Resolved: coder@build vs researcher@build
Resolution: keep-coder@build-newer-timestamp"
```

### 8.5 冲突升级路径

若自动仲裁无法解决（双方 timestamp 相同或逻辑矛盾）：

```
orchestrator 自行判断 → 仍无法解决 → [ESCALATE] P0
  → 输出到 AI交接记录/<today>/conflict-report.md
  → 等待人工介入
```

## 9. Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-06-26 | 初始版本，替代旧版 `rules/05-git-coordination.md`。 |
