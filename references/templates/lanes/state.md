# Lane 状态机

## 状态图

```
                          ┌──────────────────────────────────────┐
                          │                                      │
                          v                                      │
    ┌─────────┐     ┌────────────┐     ┌──────────────┐     ┌────┴───────┐
    │  idle   │────→│in-progress │────→│ needs-review │────→│ready-for- │
    │         │     │            │     │              │     │   merge    │
    └─────────┘     └────────────┘     └──────────────┘     └────────────┘
         │                │                  │                     │
         │                │                  │                     │
         │                v                  │                     │
         │         ┌───────────┐            │                     │
         └────────→│  blocked  │←───────────┘                     │
                   │           │                                  │
                   └───────────┘                                  │
                        │                                         │
                        │                                         │
                        v                                         v
                   ┌──────────────┐                      ┌──────────────┐
                   │   cancelled  │                      │   resolved   │
                   └──────────────┘                      └──────────────┘

                          ┌──────────────────┐
                          │ changes-requested │
                          │                  │
                          └──────────────────┘
                                  │
                                  v
                          ┌──────────────────┐
                          │  in-progress     │
                          └──────────────────┘
```

## 状态表

| 状态 | 描述 | Owner | 前置条件 | 允许的下一个状态 |
|------|------|-------|---------|----------------|
| `idle` | Lane 空闲，无活跃任务 | — | — | `in-progress` |
| `in-progress` | 任务正在执行 | `coder@build` | `idle` | `needs-review`, `blocked`, `cancelled` |
| `needs-review` | 完成任务，等待审查 | `reviewer@build` | `in-progress` | `ready-for-merge`, `changes-requested`, `blocked` |
| `changes-requested` | 审查发现问题，需修改 | `coder@build` | `needs-review` | `in-progress` |
| `ready-for-merge` | 审查通过，可合并 | `human` | `needs-review` | `resolved` |
| `blocked` | 任务被阻塞，等待外部 | `build` | `in-progress`, `needs-review` | `in-progress`, `cancelled` |
| `cancelled` | 任务被取消 | `build` | `in-progress`, `blocked` | —（终止态） |
| `resolved` | 任务完成并合入 | `human` | `ready-for-merge` | —（终止态） |

## SLA 表

| 指标 | 值 | 超时处理 |
|------|----|---------|
| 心跳间隔 | 60 s | 3 次未心跳 → lane 标记 stale，通知 build |
| Idle 回收 | 120 s | Lane 无任务超过 120s → 自动回收，agent 释放 |
| 单任务超时 | 30 min | 超时 → 强制输出状态报告，build 决定继续/取消 |
| 审查超时 | 15 min | 超时 → 自动升级到 `build`，请求人工介入 |

## 状态转换验证

### 通用规则

1. 每个状态转换必须记录在 `transitions` 日志数组中
2. 禁止跳越状态（如 `in-progress` → `resolved`）
3. 从 `blocked` 只能回到 `in-progress` 或进入 `cancelled`
4. `idle` 状态下不允许有未完成任务
5. 终止态（`resolved`, `cancelled`）不可再转换

### 转换字段要求

每次转换必须包含：
```yaml
- from: "needs-review"
  to: "changes-requested"
  by: "reviewer@build"
  at: "2026-06-26T07:58:00Z"
  reason: "2 minor issues found — 见 MSG-20260626-0002"
  task_id: "T-2026-06-26-001"
```

### 有效 / 无效转换示例

| 转换 | 是否有效 | 原因 |
|------|---------|------|
| `idle` → `in-progress` | ✅ | 正常开始 |
| `in-progress` → `needs-review` | ✅ | 完成执行 |
| `in-progress` → `blocked` | ✅ | 遇到阻塞 |
| `needs-review` → `ready-for-merge` | ✅ | 审查通过 |
| `needs-review` → `changes-requested` | ✅ | 需修改 |
| `ready-for-merge` → `resolved` | ✅ | 合并完成 |
| `in-progress` → `resolved` | ❌ | 跳过审查 |
| `idle` → `needs-review` | ❌ | 无任务直接审查 |
| `needs-review` → `in-progress` | ❌ | 如为修改应走 `changes-requested` |
| `resolved` → `in-progress` | ❌ | 终止态不可逆 |
| `cancelled` → `resolved` | ❌ | 终止态不可逆 |
