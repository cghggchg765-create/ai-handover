---
metadata:
  title: AI Handover — YAML Frontmatter 与执行记录规范
  version: 1.0.0
  component: ai-handover
  status: active
  valid_at: 2026-06-26
  provenance: "ai-handover v4.1 — IRON RULE #2/#4"
  dependencies:
    - SKILL.md §YAML Frontmatter Schema
    - rules/00-core.md
    - references/templates/exec-record.md
    - references/schemas/handover.schema.json
---

# AI Handover — YAML Frontmatter 与执行记录规范

## 1. Overview

执行记录（execution record）是 ai-handover 的核心产出物，由 AI 在当前任务完成后创建，供后续 AI 无缝接手。

格式采用双轨制（dual-track）：

| 轨道 | 格式 | 用途 | 解析对象 |
|------|------|------|---------|
| YAML frontmatter | YAML | 机器可读 | AI + 自动工具 |
| Markdown body | Markdown | 人类可读 | 开发者 + AI |

**IRON RULE #2**：每个执行记录必须同时包含 YAML frontmatter 和 Markdown body，缺一不可。

---

## 2. YAML Frontmatter 完整 Schema

### 2.1 必须字段（12 个）

| # | 字段 | 类型 | 格式/枚举 | 示例 | 说明 |
|---|------|------|-----------|------|------|
| 1 | `handover_id` | string | `YYYY-MM-DD_HHmmss_description` | `2026-06-25_143022_fix-login` | 唯一标识，见 §3 命名规则 |
| 2 | `prev_handover_id` | string | `"init"` 或上一个 `handover_id` | `2026-06-25_142015_init-project` | **IRON RULE #4**，见 §4 |
| 3 | `agent_id` | string | `role@runtime` | `coder@build.20260625` | 执行 agent 身份 |
| 4 | `agent_role` | enum | `primary` / `orchestrator` / `worker` / `reviewer` / `validator` | `worker` | 角色类型 |
| 5 | `coding_agent` | string | `tool name + version` | `opencode v1.2.0` | 使用的工具 |
| 6 | `model` | string | `model name` | `glm-5.2` | 模型标识 |
| 7 | `status` | enum | `idle` / `in-progress` / `needs-review` / `ready-for-merge` / `resolved` / `blocked` / `changes-requested` / `cancelled` | `needs-review` | 状态机 |
| 8 | `branch` | string | `agent-xxx/feat-yyy` | `agent-007/feat-login` | git branch |
| 9 | `files_modified` | array[string] | 文件路径列表 | `["src/login.tsx", "src/auth.ts"]` | 修改的文件 |
| 10 | `verification` | array[string] | `"cmd:status"` | `["npm run lint:passed"]` | 验证结果 |
| 11 | `next_action` | string | 必须包含 `@agent` 引用 | `@reviewer: review login flow` | 下一步 |
| 12 | `lock_files` | array[string] | 文件路径列表 | `["src/login.tsx"]` | 锁定文件 |

### 2.2 可选字段

| 字段 | 类型 | 格式/枚举 | 示例 | 说明 |
|------|------|-----------|------|------|
| `previous_status` | string | status 枚举值 | `in-progress` | 变更前的状态 |
| `commit` | string | commit hash | `a1b2c3d` | 最后一次 commit |
| `duration_s` | integer | 秒数 | `342` | 任务耗时 |
| `task_id` | string | 项目内唯一 | `TASK-42` | 任务追踪 ID |
| `parent_plan` | string | plan 文件路径 | `plans/2026-06-25-login.md` | 关联 plan |
| `task_type` | string | 自由文本 | `bugfix` | 任务类型标签 |
| `handover_type` | enum | `standard` / `checkpoint` / `recovery` / `final` | `checkpoint` | 交接类型 |
| `risks` | array[string] | 风险描述 | `["auth token 可能过期"]` | 已知风险 |
| `blockers` | array[string] | 阻塞描述 | `["等待 PR #42 合并"]` | 阻塞项 |
| `confidence` | integer | 1–10 | `8` | 完成信心分 |
| `notify` | array[string] | `@user` / `@agent` | `["@primary", "@user"]` | 通知对象 |
| `files_added` | array[string] | 文件路径 | `["src/utils.ts"]` | 新增文件 |
| `files_deleted` | array[string] | 文件路径 | `["src/old.ts"]` | 删除文件 |
| `started_at` | datetime | ISO 8601 | `2026-06-25T14:20:15Z` | 开始时间 |
| `ended_at` | datetime | ISO 8601 | `2026-06-25T14:30:22Z` | 结束时间 |

### 2.3 Schema 验证规则

```yaml
# 完整示例
handover_id: "2026-06-25_143022_fix-login"
prev_handover_id: "2026-06-25_142015_init-project"
agent_id: "coder@build.20260625"
agent_role: "worker"
coding_agent: "opencode v1.2.0"
model: "glm-5.2"
status: "needs-review"
branch: "agent-007/feat-login"
files_modified:
  - "src/login.tsx"
  - "src/auth.ts"
verification:
  - "npm run lint:passed"
  - "npm test login:passed"
next_action: "@reviewer: review login flow"
lock_files:
  - "src/login.tsx"
```

---

## 3. handover_id 命名规则

### 3.1 格式

```
YYYY-MM-DD_HHmmss_description
```

| 段 | 格式 | 示例 | 说明 |
|---|------|------|------|
| 日期 | `YYYY-MM-DD` | `2026-06-25` | ISO 日期 |
| 时间 | `_HHmmss` | `_143022` | 24 小时制，下划线前缀 |
| 描述 | `_description` | `_fix-login` | 小写 + 连字符，≤20 字符 |

### 3.2 示例

| 正确 | 错误 | 原因 |
|------|------|------|
| `2026-06-25_143022_fix-login` | `2026-06-25-143022-fix-login` | 时间前必须用下划线 |
| `2026-06-25_143022_init-project` | `2026/06/25_143022_init` | 日期必须用连字符 |
| `2026-06-25_143022_add-api` | `2026-06-25_143022_AddAPI` | 必须小写+连字符 |
| `2026-06-25_143022_bugfix-crash` | `2026-06-25_143022_这是一个很长的描述超过二十个字符` | 描述超长 |

### 3.3 时间精度

- 精确到秒，24 小时制
- 使用任务**开始时间**，而非完成时间（便于按时间轴排序）

---

## 4. 交接链（IRON RULE #4）

### 4.1 规则

每个执行记录必须通过 `prev_handover_id` 指向其前驱任务，形成一条可追溯的交接链。

```
handover_id                         prev_handover_id
2026-06-25_140000_init-project  →   "init"
2026-06-25_141000_setup-env    →   2026-06-25_140000_init-project
2026-06-25_142000_impl-login   →   2026-06-25_141000_setup-env
2026-06-25_143000_review-login →   2026-06-25_142000_impl-login
```

### 4.2 起点

一个项目/会话中的**第一个**交接记录，`prev_handover_id` 固定为 `"init"`。

### 4.3 链断裂处理

| 场景 | 处理方式 |
|------|---------|
| 前驱 handover_id 不存在 | 标记为 `"orphan"`，在 body 中说明原因 |
| 跨会话恢复 | 搜索 `AI交接记录/索引.md` 找到最后一个记录作为前驱 |
| 并行分支 | 使用 `"fork:<handover_id>"` 格式标记分支来源 |

### 4.4 父子关系

当任务被分解为子任务时：

- 父任务在 `next_action` 中引用子任务的开始
- 子任务的 `prev_handover_id` 指向父任务
- 子任务完成后，父任务更新 `status` 并创建新的交接记录

---

## 5. 索引维护规则

### 5.1 索引文件

文件位置：`AI交接记录/索引.md`

### 5.2 更新时机

**每次**创建、更新或删除交接记录后，必须同步更新索引。

### 5.3 索引格式

```markdown
# AI交接记录索引

最新更新时间: 2026-06-25 14:30

| 序号 | handover_id | status | agent | 摘要 |
|------|-------------|--------|-------|------|
| 1 | 2026-06-25_143022_fix-login | needs-review | coder | 修复登录页 token 过期问题 |
| 2 | 2026-06-25_142015_init-project | resolved | primary | 项目初始化完成 |
```

### 5.4 规则

- 最新记录**始终**在第一行
- 不允许手动编辑排序
- 每条索引对应一个 `执行记录.md` 文件

---

## 6. 模板使用规则

### 6.1 引用位置

执行记录模板位于 `references/templates/exec-record.md`。

### 6.2 何时使用

| 场景 | 必须使用模板？ |
|------|--------------|
| 创建新的执行记录 | ✅ 是 |
| 更新已有执行记录 | ❌ 否（编辑已有文件） |
| 任务 checkpoint | ✅ 是 |
| 任务恢复 | ✅ 是 |

### 6.3 规则

| 规则 | 说明 |
|------|------|
| ✅ 必须填充所有 mandatory 字段 | 12 个必须字段 + body 中的 4 个必需章节 |
| ✅ 可省略 optional 字段 | 如果无相关信息则不填 |
| ❌ 禁止添加自定义字段 | 不允许在 YAML 中新增 Schema 未定义的顶层字段 |
| ✅ 可在 body 中添加自定义章节 | Markdown body 可自由扩展 |
| ❌ 禁止删除 YAML frontmatter | 双轨制必须保留 |

---

## 7. 执行记录 Markdown 正文结构

每个执行记录的 Markdown body 必须包含以下 4 个必需章节，顺序固定。

### 7.1 必需章节

```markdown
## 执行摘要

简要描述本次任务的目标、范围与完成情况。2–5 句话。

示例：
> 实现登录页的 token 过期自动刷新功能。已完成 useRefreshToken hook 编写，
> 单元测试覆盖 3 个边界场景，lint 通过。

## 产出物

列出本次任务创建/修改的文件与关键结果。

- `src/hooks/useRefreshToken.ts` — 新增，token 刷新逻辑
- `src/__tests__/useRefreshToken.test.ts` — 新增，单元测试
- `src/auth.ts` — 修改，集成 refresh token 流程

## 遗留问题

使用优先级标记：

| 优先级 | 标记 | 说明 |
|--------|------|------|
| 🔴 高 | `🔴 <问题>` | 必须在下个任务处理 |
| 🟡 中 | `🟡 <问题>` | 建议处理，可推迟 |
| 🟢 低 | `🟢 <问题>` | 已知限制，可忽略 |

示例：

🔴 useRefreshToken 在 StrictMode 下触发两次请求，需增加防抖
🟡 缺少 E2E 测试覆盖
🟢 token 刷新时 50ms 的短暂闪烁为已知 UI 限制

## 下一步计划

明确指定后续任务及负责人（需与 YAML `next_action` 一致）。

示例：
> 1. `@reviewer` 审查 useRefreshToken hook 实现
> 2. `@primary` 合入 main 分支
> 3. `@user` 确认最终效果
```

### 7.2 可选章节

可根据需要扩展，例如：

- `## 决策记录` — 关键设计决策与理由
- `## 验证详情` — 验证执行的详细输出
- `## 风险与缓解` — 风险评估与应对策略
- `## 参考资源` — 相关文档、PR、issue 链接

### 7.3 禁止行为

| ❌ 禁止 | 原因 |
|--------|------|
| 移除必需章节（4 个） | 破坏格式契约 |
| 在 YAML 中含敏感信息（密码、key） | 交接记录可能被共享 |
| 遗留问题标记为空而不说明 | 误导接手方 |
| `next_action` 与 body 中下一步不一致 | 双重信号冲突 |

---

## 8. Changelog

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| 1.0.0 | 2026-06-26 | 初始版本，配套 ai-handover v4.1，定义完整 YAML Schema（12 个必须字段）与执行记录规范 |

---

*本文件是 ai-handover 的核心规范文档。详细模板和 schema 请分别参阅 `references/templates/exec-record.md` 和 `references/schemas/handover.schema.json`。*
