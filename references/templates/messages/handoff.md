# 跨 Agent 消息格式

## 消息类型

| 类型 | 方向 | 用途 | 期望响应 |
|------|------|------|---------|
| `review_request` | coder / writer → reviewer | 请求代码/文档审查 | `review_response` |
| `review_response` | reviewer → coder / writer | 审查结果 | action / reply |
| `blocker_raised` | any → any | 上报阻塞问题 | `answer` / 重新规划 |
| `question` | any → any | 技术/流程疑问 | `answer` |
| `answer` | any → any | 回复疑问 | — |
| `status_report` | any → build | 任务状态更新 | — |
| `proposal` | any → build / human | 建议/决策请求 | `answer` / 审批 |

## 优先级

| 级别 | 标签 | 响应时限 | 场景 |
|------|------|---------|------|
| blocking | 🔴 | 立即 | 阻断性错误，无法继续 |
| high | 🟠 | 15 min | 关键路径阻塞 |
| normal | 🟡 | 2 h | 常规问题/审查 |
| low | 🟢 | 24 h | 信息性通知 |

## 字段表

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `msg_id` | string | ✓ | 全局唯一，格式 `MSG-{YYYYMMDD}-{XXXX}` |
| `type` | enum | ✓ | 见消息类型表 |
| `priority` | enum | ✓ | 见优先级表 |
| `from` | string | ✓ | 发送方 agent_id |
| `to` | string | ✓ | 接收方 agent_id |
| `subject` | string | ✓ | 简短标题（≤80 字） |
| `task_id` | string | ✓ | 关联任务 ID |
| `handover_id` | string | | 关联交接记录 ID |
| `branch` | string | | 关联分支名 |
| `files` | string[] | | 关联文件路径 |
| `body` | string | ✓ | 消息正文（Markdown） |
| `created_at` | ISO 8601 | ✓ | 创建时间 |
| `status` | enum | | pending / read / responded / resolved |
| `in_reply_to` | string | | 回复的原 msg_id |

## 示例对话

### review_request → review_response

```yaml
msg_id: "MSG-20260626-0001"
type: "review_request"
priority: "high"
from: "coder@build"
to: "reviewer@build"
subject: "请审查 auth refactor — 4 文件变更"
task_id: "T-2026-06-26-001"
handover_id: "2026-06-26_075100_auth-refactor"
branch: "feature/auth-refactor"
files:
  - "src/auth/login.ts"
  - "src/auth/session.ts"
  - "src/lib/validate.ts"
  - "src/auth/__tests__/login.test.ts"
body: |
  ## 审查请求

  Auth 模块重构完成。关键变更：
  1. 验证逻辑抽取到 validate.ts
  2. Session TTL 从 24h → 8h
  3. 单元测试覆盖率 92%

  请在 15 分钟内完成审查。
created_at: "2026-06-26T07:51:00Z"
status: "pending"
```

```yaml
msg_id: "MSG-20260626-0002"
type: "review_response"
priority: "high"
from: "reviewer@build"
to: "coder@build"
subject: "Re: 请审查 auth refactor — 2 个 minor 问题"
task_id: "T-2026-06-26-001"
handover_id: "2026-06-26_075100_auth-refactor"
branch: "feature/auth-refactor"
files:
  - "src/auth/login.ts"
  - "src/lib/validate.ts"
body: |
  ## 审查结果

  ### ✅ 通过（需修复以下 minor 问题）

  1. **src/auth/login.ts:45** — `error.message` 可能为 undefined，建议用 `error?.message ?? "Unknown error"`
  2. **src/lib/validate.ts:22** — 函数签名缺少 `readonly`，`input: Credentials` → `input: Readonly<Credentials>`

  ### 总体评价
  - 架构合理，拆分方向正确
  - 测试覆盖充分（边缘 case 已覆盖）
  - TTL 变更已确认与安全要求一致

  ### 修复后可直接合并，无需二次审查。
created_at: "2026-06-26T07:58:00Z"
in_reply_to: "MSG-20260626-0001"
status: "responded"
```

## 铁的规则

### Rule 1: @mention = 触发
在 body 中使用 `@agent_id` 表示该 agent 需要处理。例：`@coder@build 请修复 line 45 的 null safety 问题`。

### Rule 2: 每轮一条回复
每个 `msg_id` 只产生一个 `in_reply_to`。如需多轮讨论，请使用新的 `msg_id` 并引用原始消息。

### Rule 3: Human Gates
涉及以下操作必须等待人类审批，不可自动执行：
- 合并 PR 到 main
- 修改生产环境配置
- 删除数据
- 引入外部依赖

### Rule 4: Agents Have Lanes
每个 agent 有专用 lane。消息投递 = 写入目标 lane 的文件。Agent 轮询自己的 lane 发现新消息。

### Rule 5: File-Based Artifacts
所有消息必须是 `.md` 或 `.yaml` 文件，存储在 lanes/ 目录下。禁止通过对话上下文传递结构化消息。
