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
- **项目类型**：academic
- **文献来源**：[参考的论文/资料]
- **开始时间**：YYYY-MM-DD HH:mm
- **结束时间**：YYYY-MM-DD HH:mm

## 研究方法
- **采用方法**：[方法名]
- **参数设置**：[关键参数]
- **基线对比**：[对比对象]

## 产出物
- **实验报告**：`path/to/report.md`
- **数据/图表**：`path/to/figure.png`
- **代码**：`path/to/script.py`

## 遗留问题
| # | 问题 | 严重度 | 建议 |
|---|------|--------|------|
| 1 | [问题] | 🔴/🟡/🟢 | [建议] |

## 下一步计划
- [ ] [具体动作]
