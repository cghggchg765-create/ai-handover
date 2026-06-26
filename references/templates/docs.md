---
handover_id: YYYY-MM-DD_HHmmss_任务简述
prev_handover_id: "init"
agent_id: agent@runtime
agent_role: worker
coding_agent: OpenCode v1.x
model: model-name
task_id: T-YYYY-MM-DD-NNN
task_type: feature                        # feature/fix/refactor/docs/research/review
handover_type: handover                   # handover/progress/decision
status: needs-review
branch: agent-xxx/feat-description
files_modified:
  - path/to/file1
  - path/to/file2
lock_files: []
verification:
  - "test command:pass"
risks: []
blockers: []
next_action: "@reviewer 请审查"
confidence: high
started_at: YYYY-MM-DDTHH:MM:SS-07:00
ended_at: YYYY-MM-DDTHH:MM:SS-07:00
---

# [任务简述]

## 基本信息
- **任务名称**：[一句话描述]
- **项目类型**：docs
- **文档版本**：[v1.0/v2.0]
- **开始时间**：YYYY-MM-DD HH:mm
- **结束时间**：YYYY-MM-DD HH:mm

## 文档变更
- **新增章节**：[章节名]
- **修改章节**：[章节名]
- **删除章节**：[章节名]

## 审阅记录
- **审阅人**：[姓名]
- **审阅意见**：[主要意见]
- **采纳情况**：[已采纳/已拒绝/待讨论]

## 产出物
- **文档**：`path/to/doc.md`
- **变更说明**：`path/to/changelog.md`

## 下一步计划
- [ ] [具体动作]
