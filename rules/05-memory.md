---
metadata:
  title: AI Handover — 三层记忆规范
  version: 1.0.0
  component: ai-handover
  status: active
  valid_at: 2026-06-26
  provenance: "ai-handover v4.1 — IRON RULE #7/#8"
  dependencies:
    - SKILL.md §三层记忆架构
    - rules/00-core.md
    - rules/01-handover.md
    - references/templates/wiki/hot.md
    - references/templates/agents/profile.md
    - references/templates/messages/handoff.md
---

# 三层记忆规范

## 1. 概述

三层记忆架构解决跨会话知识丢失问题。每一层服务于不同目的：

| 层 | 名称 | 目的 | 存储位置 |
|----|------|------|---------|
| Wiki | User Memory | 显式知识、决策、偏好、坑 | `wiki/` 目录 |
| Agents | Agent Memory | 学习到的模式、人格维护 | `agents/` 目录 |
| Messages | Cross-Agent | 实时消息传递 | `messages/` 目录 |

IRON RULE #7 和 #8 强制执行更新和入职协议。

---

## 2. Wiki 层 — User Memory（IRON RULE #7）

### 2.1 hot.md 模板

`references/templates/wiki/hot.md` 定义标准格式：

```yaml
last_updated: 2026-06-26T10:00:00Z
updated_by: agent-build-v1
current_phase: 设计阶段 / 实现阶段 / 审查阶段 / 部署阶段
active_decisions:
  - database: PostgreSQL (原因: 团队熟悉, 无需额外授权)
active_files:
  - src/main.py (状态: 修改中)
known_pits:
  - "热更新时需重启 worker 进程"
next_steps:
  - 完成 API 接口设计
  - 编写单元测试
```

### 2.2 IRON RULE #7：hot.md 强制更新

> **每次交接后必须更新 hot.md。** 交接记录必须包含"hot.md 已更新"确认项。

- **触发时机**：交接记录写入后、索引更新前
- **验证方式**：检查 `wiki/hot.md` 的 `last_updated` 时间戳是否晚于交接记录的 `created_at`
- **违规处理**：索引更新标记 `hot_stale: true`，下个 Agent 入职时强制提示

### 2.3 decisions.md

ADR 格式，遵循 Lore 风格：

```markdown
## ADR-001: 选择 PostgreSQL 作为主数据库

- **日期**: 2026-06-01
- **状态**: 已接受
- **背景**: 需要支持复杂查询和事务
- **决策**: 使用 PostgreSQL 15
- **Constraints**: 必须兼容 pgvector
- **Rejected-Alternatives**: MySQL（缺少向量支持）、MongoDB（事务能力弱）
- **Agent-Directives**: 所有 schema 变更必须通过 migration 脚本
```

### 2.4 patterns.md

跨项目模式注册。每条需包含：名称、上下文、问题、解决方案、适用条件。

```markdown
## Pattern: 热更新安全策略

- **上下文**: 生产环境热更新
- **问题**: 热更新时请求中断
- **解决方案**: 先拉流量再重启，逐步放量
- **适用条件**: 有负载均衡器
```

### 2.5 preferences.md

仅记录用户显式声明的偏好：

```markdown
- Python 项目优先使用 Poetry 而非 pip
- 代码注释使用英文
- PR 标题必须含 JIRA 单号
```

### 2.6 bugs.md

已知 bug 跟踪：

```markdown
## BUG-001: 并发写入导致数据不一致

- **发现日期**: 2026-06-15
- **影响范围**: `/api/order` 高并发场景
- **复现步骤**: 同时发起 100+ 写入请求
- **状态**: 观察中 ← 活跃 / 已修复 / 观察中 / 绕过中
- **临时方案**: 加分布式锁
- **责任人**: @user
```

---

## 3. Agent 层 — Agent Memory

### 3.1 profile.md 格式

`references/templates/agents/profile.md` 定义：

```yaml
agent_id: agent-build-v1
role: build（主编排 Agent）
authority_boundaries:
  - 可编辑任意非 C 盘文件
  - 不可操作生产数据库
  - 不可删除未确认的文件
preferences:
  - 优先使用 task() 而非直接编辑
  - 每个步骤输出三段式
learned_lessons:
  - "task(coder) 处理 LaTeX 时需先加载 latex-guard"
  - "超过 3 步的任务必须用 todowrite"
known_weaknesses:
  - 长文本摘要时可能遗漏细节
  - 对 Windows 路径转义不敏感
```

### 3.2 history.jsonl 格式

append-only JSONL，每行一个学习记录：

```jsonl
{"type":"lesson","key":"latex_guard_before_coder","insight":"task(coder)处理LaTeX前必须加载latex-guard","confidence":0.9,"source":"实际失败","files":["main.tex"],"timestamp":"2026-06-20T14:00:00Z","handover_id":"20260620_140000_latex_fix"}
{"type":"pattern","key":"multi_step_todo","insight":"超过2+步骤必须用todowrite","confidence":1.0,"source":"IRON RULE","files":[],"timestamp":"2026-06-18T09:00:00Z","handover_id":"20260618_090000_rule_enforce"}
{"type":"bug","key":"hot_reload_worker","insight":"热更新时worker进程不会自动重启","confidence":0.7,"source":"运营反馈","files":["deploy/scripts/reload.sh"],"timestamp":"2026-06-15T16:30:00Z","handover_id":"20260615_163000_deploy_hotfix"}
```

字段说明：

| 字段 | 必需 | 说明 |
|------|------|------|
| `type` | 是 | key / lesson / pattern / bug / preference |
| `key` | 是 | 唯一标识符 |
| `insight` | 是 | 学习内容（必填） |
| `confidence` | 否 | 0.0-1.0 可信度 |
| `source` | 推荐 | 来源（实际失败 / 用户要求 / IRON RULE / 运营反馈） |
| `files` | 否 | 相关文件路径列表 |
| `timestamp` | 推荐 | ISO 8601 时间戳 |
| `handover_id` | 推荐 | 关联的交接 ID |

### 3.3 跨会话 Agent 人格维护

新会话启动时，Agent 按以下顺序加载 Agent 记忆：

1. 读取 `agents/profile.md` → 恢复角色定义
2. 读取 `agents/history.jsonl` → 恢复学习记录
3. 检查 `wiki/hot.md` → 恢复当前上下文

---

## 4. Messages 层 — Cross-Agent

### 4.1 5 条铁律（来自 SKILL.md §3.3）

| # | 铁律 | 说明 |
|---|------|------|
| 1 | **直接寻址** | 每条消息必须指定明确的 `from` 和 `to` |
| 2 | **一次响应** | 每条消息最多产生 1 条响应，禁止多轮链式对话 |
| 3 | **无环境监听** | Agent 不得自动响应未寻址给自己的消息 |
| 4 | **超时清理** | 超过 30 分钟未处理的消息标记为 `timeout` |
| 5 | **非对称删除** | 读后即删，不保留已处理消息 |

### 4.2 inbox.jsonl 格式

`references/templates/messages/handoff.md` 定义消息结构：

```jsonl
{"msg_id":"msg-001","type":"handoff","priority":"high","from":"agent-build-v1","to":"agent-coder-v1","subject":"完成API路由实现","task_id":"task-api-routes","handover_id":"20260626_100000_api_routes","status":"pending","in_reply_to":null}
{"msg_id":"msg-002","type":"query","priority":"normal","from":"agent-coder-v1","to":"agent-build-v1","subject":"确认路由参数命名规范","task_id":null,"handover_id":null,"status":"in_progress","in_reply_to":"msg-001"}
```

字段说明：

| 字段 | 必需 | 说明 |
|------|------|------|
| `msg_id` | 是 | 唯一消息 ID |
| `type` | 是 | handoff / query / notify / alert |
| `priority` | 是 | critical / high / normal / low |
| `from` | 是 | 发送方 agent_id |
| `to` | 是 | 接收方 agent_id（可用 `*` 广播） |
| `subject` | 推荐 | 简短主题 |
| `task_id` | 否 | 关联任务 ID |
| `handover_id` | 否 | 关联交接记录 ID |
| `status` | 是 | pending / in_progress / resolved / timeout |
| `in_reply_to` | 否 | 回复的父消息 ID |

### 4.3 消息生命周期

```
pending ──→ in_progress ──→ resolved
   │                           ↑
   └──→ timeout ──────────────┘
```

- **pending**: 消息已写入，等待目标 Agent 读取
- **in_progress**: 目标 Agent 已取走，正在处理
- **resolved**: 处理完成
- **timeout**: 超过 30 分钟未处理

### 4.4 反循环控制

| 规则 | 值 |
|------|-----|
| 每条消息最大响应数 | 1 |
| 是否允许环境监听 | 否 |
| 超时时限 | 30 分钟 |
| 超时行为 | 标记 `timeout`，通知主 Agent |
| 循环检测 | 连续 3 条同类消息触发警报 |

---

## 5. 新 Agent 入职流程（IRON RULE #8）

新 Agent 首次进入项目时，必须按以下顺序完成入职：

### 5.1 7 步入职顺序

| 步 | 动作 | 读取文件 | 目的 |
|----|------|---------|------|
| 1 | 🔴 hot.md | `wiki/hot.md` | 了解当前阶段和活跃状态 |
| 2 | 🔴 索引.md | `AI交接记录/索引.md` | 获取项目全局时间线 |
| 3 | 🔴 git log | 最近 10 条 commit | 了解代码变更历史 |
| 4 | 🔴 handover-IDs | `AI交接记录/` 最近 3 条交接 | 了解最近任务上下文 |
| 5 | 🔴 锁状态 | `wiki/locks.md`（如存在） | 检查是否有活跃锁 |
| 6 | 🟡 active.md | `wiki/active.md`（如存在） | 了解活跃任务清单 |
| 7 | 🟡 messages | `messages/inbox.jsonl` | 检查是否有待处理消息 |

- 🔴 = 必须执行，缺失视为违规
- 🟡 = 推荐执行，缺失记录但可通过

### 5.2 跳过步骤的处理

| 场景 | 处理方式 | 违规标记 |
|------|---------|---------|
| hot.md 不存在 | 创建空 hot.md，标记 `onboarding_missing_hot` | P1 |
| 索引.md 不存在 | 创建新索引.md | P1 |
| git log 无法读取 | 记录 `onboarding_no_git` | P2 |
| handover-IDs 不足 3 条 | 创建首个交接记录 | 无 |
| 锁文件无法读取 | 视为无锁 | 无 |

### 5.3 入职状态示例

```markdown
## 入职状态报告

- **Agent**: agent-build-v2
- **入职时间**: 2026-06-26T10:00:00Z
- **步骤检查**:
  - ✅ hot.md → 已读取（阶段: 实现阶段）
  - ✅ 索引.md → 已读取（12 条记录）
  - ✅ git log → 已读取（最近 10 条 commit）
  - ✅ handover-IDs → 已读取（最近 3 条）
  - ⚠️ locks.md → 不存在（无锁）
  - ⚠️ active.md → 不存在（跳过）
  - ✅ messages → 已读取（2 条待处理）
- **违规记录**: 无
```

---

## 6. Changelog

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| 1.0.0 | 2026-06-26 | 初始版本，随 ai-handover v4.1 发布 |
