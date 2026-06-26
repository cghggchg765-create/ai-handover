---
metadata:
  title: AI Handover — 验证规则
  version: 1.0.0
  component: ai-handover
  status: active
  valid_at: 2026-06-26
  provenance: "ai-handover v4.1 — 质量门控"
  dependencies:
    - SKILL.md §执行流程
    - rules/00-core.md
    - rules/01-handover.md
    - scripts/validate.sh
    - references/schemas/handover.schema.json
---

# 验证规则

## 1. Overview

Validation is the quality gate for ai-handover. Every handover record must pass validation before being accepted. Two levels:

| 层次 | 机制 | 触发时机 | 负责人 |
|------|------|---------|--------|
| 自动化 | validate.sh + handover.schema.json | 每次任务完成后的验收阶段 | build / 子 agent |
| 手动 | 自检清单（10 项） | 提交交接记录前 | 子 agent 自我复核 |

自动化验证失败 → 阻断验收 → 责令子 agent 修复。
手动自检失败 → 不得标记任务完成 → 修正后重新提交。

## 2. validate.sh 8 项检查

检查由 `scripts/validate.sh` 执行，接受目标目录参数：

```bash
./scripts/validate.sh AI交接记录/YYYY-MM-DD_HHmmss_任务简述/
```

### 检查 1：执行记录完整性

| 属性 | 值 |
|------|-----|
| **名称** | Check 1 - 执行记录完整性 |
| **验证内容** | `索引.md` 存在于 `AI交接记录/` 根目录；执行记录的文件夹存在于 `AI交接记录/` 下 |
| **工作方式** | `Test-Path` 检查 `索引.md` 是否存在；`Get-ChildItem` 检查任务目录是否创建 |
| **失败后果** | 缺失 → 验收阻断，责令子 agent 创建目录和索引文件 |

**验证命令示例**：

```powershell
$indexPath = "AI交接记录/索引.md"
$taskDir  = "AI交接记录/YYYY-MM-DD_HHmmss_任务简述"
if (-not (Test-Path $indexPath)) { throw "索引.md 不存在" }
if (-not (Test-Path $taskDir))   { throw "任务目录不存在" }
```

### 检查 2：YAML frontmatter 必填字段

| 属性 | 值 |
|------|-----|
| **名称** | Check 2 - YAML frontmatter 必填字段 |
| **验证内容** | 执行记录文件包含完整 12 个必填字段（见 §3 Schema 验证规则） |
| **工作方式** | 提取 YAML frontmatter 块 → 逐一校验字段存在且非空 |
| **失败后果** | 缺失任一字段 → 责令子 agent 补齐后重新提交 |

### 检查 3：prev_handover_id 链完整性

| 属性 | 值 |
|------|-----|
| **名称** | Check 3 - prev_handover_id 链完整性 |
| **验证内容** | 前驱交接记录存在且 ID 匹配；整个链路无断裂 |
| **工作方式** | 沿 `prev_handover_id` 回溯至 `"init"`，每一步检查目标文件存在性 |
| **失败后果** | 链断裂（非 `"init"` 的 prev_handover_id 指向不存在的记录）→ 阻断验收 |

**链完整性规则**：

- 首个记录：`prev_handover_id` 必须为 `"init"`
- 后续记录：`prev_handover_id` 必须指向一个已存在的执行记录
- 不允许空洞：中间不可跳过未创建的记录

### 检查 4：git trailers 存在性

| 属性 | 值 |
|------|-----|
| **名称** | Check 4 - git trailers 存在性 |
| **验证内容** | 最近一次 git commit 包含三条标准 trailer：`Handover-Id`、`Coding-Agent`、`Model` |
| **工作方式** | `git log --format="%(trailers:key=Handover-Id,key=Coding-Agent,key=Model)" -1` |
| **失败后果** | 缺失任一 trailer → 责令子 agent 补充后重新提交 |

**标准 trailer 格式**：

```
Handover-Id: HO-20260626-XXXXX
Coding-Agent: coder|build|reviewer|researcher|scribe
Model: glm-5.2|gpt-4|claude-sonnet-4
```

### 检查 5：Lane 状态跳转合法性

| 属性 | 值 |
|------|-----|
| **名称** | Check 5 - Lane 状态跳转合法性 |
| **验证内容** | 当前状态相对于前驱记录的跳转在允许转换表中 |
| **工作方式** | 读取前驱记录的 `lane_status` → 查跳转表 → 匹配即合法 |
| **失败后果** | 非法跳转 → 阻断验收，注明跳转路径及允许路径 |

**合法状态跳转表**：

| 当前状态 | 允许的下一个状态 | 说明 |
|---------|----------------|------|
| `planning` | `in_progress` | 规划完成进入执行 |
| `in_progress` | `review`, `blocked` | 执行中可进入审查或阻塞 |
| `review` | `in_progress`, `completed` | 审查后可返回修改或完成 |
| `blocked` | `in_progress`, `abandoned` | 阻塞解除后继续或放弃 |
| `completed` | — | 终态，不可跳转 |
| `abandoned` | — | 终态，不可跳转 |

**非法跳转示例**：

```
planning → completed   ✗ 跳过执行和审查
in_progress → abandoned ✗ 未通过审查直接放弃（需先进入 blocked）
```

### 检查 6：文件锁冲突检测

| 属性 | 值 |
|------|-----|
| **名称** | Check 6 - 文件锁冲突检测 |
| **验证内容** | 同一手写记录未被多个 agent 并发编辑 | | **工作方式** | 检查锁文件 `.lock` 的时间戳；若锁文件存在且未过期则认为冲突 |
| **失败后果** | 过期锁 → 警告并自动清理；活跃锁 → 阻断并提示持有 agent |

**锁文件规范**：

- 位置：`AI交接记录/YYYY-MM-DD_HHmmss_任务简述/.lock`
- 格式：agent 名称 + 时间戳
- 有效期：30 分钟（超时即视为过期锁）

### 检查 7：hot.md 更新检测

| 属性 | 值 |
|------|-----|
| **名称** | Check 7 - hot.md 更新检测 |
| **验证内容** | `hot.md` 文件最后修改时间不晚于执行记录生成时间 |
| **工作方式** | 比较 `hot.md` 与执行记录文件的 `LastWriteTime` |
| **失败后果** | `hot.md` 未同步更新 → 警告（不阻断，要求补更） |

### 检查 8：next_action 格式

| 属性 | 值 |
|------|-----|
| **名称** | Check 8 - next_action 格式 |
| **验证内容** | `next_action` 字段包含 `@agent` 引用 |
| **工作方式** | 正则匹配 `next_action` 值中的 `@` + 合法 agent 名称 |
| **失败后果** | 缺少 `@agent` 或 agent 名称不合法 → 责令修正 |

**合法 agent 引用列表**：

```
@build @coder @reviewer @researcher @scribe @orchestrator @explore
```

**示例**：

```yaml
next_action: "由 @coder 实现后端 API 接口"
# ✅ 合法

next_action: "等待用户反馈后继续"
# ✗ 不合法 — 缺少 @agent 引用
```

## 3. Schema 验证规则

### 3.1 位置与使用

| 项目 | 值 |
|------|-----|
| schema 文件 | `references/schemas/handover.schema.json` |
| 触发方式 | validate.sh 自动调用；也可手动 `python -m jsonschema -i <record.md> <schema>` |
| 验证阶段 | 先于 8 项检查执行 |

### 3.2 12 个必填字段

| # | 字段名 | 类型 | 允许值 / 格式 |
|---|--------|------|-------------|
| 1 | `handover_id` | string | `HO-\d{8}-[A-Z0-9]{5}` |
| 2 | `prev_handover_id` | string | `"init"` 或有效的 `HO-XXXXXXXX-XXXXX` |
| 3 | `timestamp` | string (ISO 8601) | `YYYY-MM-DDTHH:mm:ssZ` |
| 4 | `from_agent` | string | `coder` / `build` / `reviewer` / `researcher` / `scribe` |
| 5 | `to_agent` | string | `coder` / `build` / `reviewer` / `researcher` / `scribe` |
| 6 | `lane` | string | `main` / `hotfix` / `feature/<name>` / `research/<topic>` |
| 7 | `lane_status` | string | `planning` / `in_progress` / `review` / `blocked` / `completed` / `abandoned` |
| 8 | `model` | string | `glm-5.2` / `gpt-4` / `claude-sonnet-4` |
| 9 | `summary` | string | 非空，≤ 500 字符 |
| 10 | `next_action` | string | 含 `@agent` 引用，≤ 300 字符 |
| 11 | `files_created` | array[string] | 每个值为有效相对路径 |
| 12 | `files_modified` | array[string] | 每个值为有效相对路径 |

### 3.3 JSON Schema 验证范围

| 能力 | 支持程度 |
|------|---------|
| 字段存在性检查 | ✅ 完整支持 |
| 类型校验（string / array / object） | ✅ 完整支持 |
| 枚举值约束 | ✅ 完整支持（如 `lane_status` 合法值） |
| 正则表达式格式校验 | ✅ 支持（如 `handover_id` 模式） |
| 链完整性检查 | ❌ 不支持（需要遍历上下文） |
| 文件存在性检查 | ❌ 不支持 |
| 跨记录关系校验 | ❌ 不支持 |
| git metadata 校验 | ❌ 不支持 |

### 3.4 schema 与 validate.sh 的关系

```
graph LR
    A[执行记录.md] --> B{JSON Schema 验证}
    B -->|通过| C{validate.sh 8 项检查}
    B -->|失败| D[阻断 — 格式错误]
    C -->|全部通过| E[✅ 验收通过]
    C -->|1-2 项失败| F[责令子 agent 补写]
    C -->|3 项以上 / 连续失败| G[换 agent 类型]
```

**关系原则**：

- Schema 验证：机器可读、可自动执行，覆盖字段级约束（存在性、类型、格式）
- validate.sh 检查：需要上下文感知的逻辑验证（链完整性、文件存在性、状态跳转）
- 两者互补：schema 验证确保格式一致性，validate.sh 确保记录可追溯性

## 4. 自检清单

以下 10 项手动检查（来自 SKILL.md §执行流程 第十步），由子 agent 在提交前自我复核：

| # | 检查项 | 检查方法 | 通过条件 |
|---|--------|---------|---------|
| 1 | 目录结构正确 | 目视检查 `AI交接记录/` 下目录命名符合规范 | 目录名 = `YYYY-MM-DD_HHmmss_任务简述` |
| 2 | 索引已更新 | 打开 `索引.md` 确认新记录已追加 | 索引含最新记录的时间戳和摘要 |
| 3 | YAML 字段齐全 | 目视检查 frontmatter 12 个字段 | 无字段缺失、无空值 |
| 4 | prev_handover_id 正确 | 检查前驱记录 ID 是否匹配 | 链连续或为 `"init"` |
| 5 | summary 不超过 500 字 | 字数统计 | ≤ 500 字符，清晰概括任务 |
| 6 | next_action 含 @agent | 目视检查 | 包含合法 `@agent` 引用 |
| 7 | files_created/modified 路径存在 | 检查文件路径是否真实 | 路径有效、文件实际存在 |
| 8 | 无敏感信息泄露 | 扫读全文 | 无 token、密钥、密码等 |
| 9 | git commit 含 trailers | `git log -1` 检查 | `Handover-Id`、`Coding-Agent`、`Model` 三条 |
| 10 | hot.md 已同步 | 检查 `hot.md` 更新状态 | 最近的变更已反映在 `hot.md` |

## 5. 验收标准

### 5.1 全部通过

```
✅ 验收通过
动作：标记任务完成，更新索引状态为 completed
交接记录：AI交接记录/YYYY-MM-DD_HHmmss_任务简述/执行记录.md
```

### 5.2 1-2 项不通过

```
⚠️ 有条件通过
动作：责令子 agent 补写不通过项
重试次数：最多 2 次
超出后：按连续失败处理
```

### 5.3 3 项以上不通过或连续 2 次失败

```
❌ 验收失败 — 换 agent 类型
动作：
  1. 记录失败原因到 [ESCALATE] 信号
  2. 选择新 agent 类型重新委托
  3. 原 agent 的结果不予采用
```

**换 agent 路径**：

| 原 agent | 换为 |
|---------|------|
| coder | explore（先探索再重新实现） |
| researcher | general（简化任务） |
| scribe | build（直接编排） |
| 任意 | 人工介入（连续 3 次换 agent 仍失败） |

## 6. 常见的验收失败场景与处理

| # | 失败场景 | 典型原因 | 处理方式 | 严重级别 |
|---|---------|---------|---------|---------|
| 1 | **缺字段** | 子 agent 未完整填写 YAML frontmatter，遗漏必填字段 | 列举缺失字段，责令补写后重新提交 | P1 |
| 2 | **缺文件夹** | 子 agent 未创建 `AI交接记录/` 下的任务目录 | 责令创建目录并移动文件 | P1 |
| 3 | **格式错误** | handover_id 格式不匹配 `HO-XXXXXXXX-XXXXX` 或日期错误 | 责令修正后重新提交。若两次失败，换 agent | P0 |
| 4 | **链断裂** | `prev_handover_id` 指向不存在的记录或拼写错误 | 确认前驱记录 ID，责令修正。若链断裂无法修复 → [ESCALATE] | P0 |
| 5 | **trailers 缺失** | git commit 时未添加标准 trailer | 责令用 `git commit --amend` 追加 trailer 后重新提交 | P1 |
| 6 | **状态跳转非法** | 如 `planning → completed` 跳过中间状态 | 输出允许的跳转路径，责令修正后重新提交 | P1 |

### 紧急处理流程

对于 P0 级别失败（格式错误、链断裂）：

```
[ESCALATE]
严重度: P0
原因: <具体失败原因>
反馈: <失败详情和诊断信息>
新计划: <建议的修复方案>
问题: <向主 agent 描述的问题概要>
```

## 7. Changelog

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| 1.0.0 | 2026-06-26 | initial release with ai-handover v4.1 |
