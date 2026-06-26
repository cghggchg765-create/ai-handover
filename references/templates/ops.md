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
- **项目类型**：ops
- **环境**：[dev/staging/prod]
- **开始时间**：YYYY-MM-DD HH:mm
- **结束时间**：YYYY-MM-DD HH:mm

## 配置变更
- **环境变量**：[变量名=值]
- **配置文件**：[配置文件路径]
- **依赖变更**：[新依赖]

## 部署步骤
1. [步骤一] → [结果]
2. [步骤二] → [结果]
3. [回滚方案] → [如何回滚]

## 产出物
- **配置文件**：`path/to/config.yml`
- **部署脚本**：`path/to/deploy.sh`
- **变更记录**：[记录位置]

## 遗留问题
| # | 问题 | 严重度 | 建议 |
|---|------|--------|------|
| 1 | [问题] | 🔴/🟡/🟢 | [建议] |

## 下一步计划
- [ ] [具体动作]
