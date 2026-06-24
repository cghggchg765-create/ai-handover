# AI Handover Records (AI 交接记录)

> 标准化 AI 交接文档管理技能 — 确保任何 AI 接手后能在 **1 分钟内** 了解项目全貌

[![OpenCode](https://img.shields.io/badge/platform-OpenCode-blue)](https://opencode.ai)
[![Claude Code](https://img.shields.io/badge/platform-Claude%20Code-purple)]()
[![Cursor](https://img.shields.io/badge/platform-Cursor-green)]()
[![Skill Version](https://img.shields.io/badge/version-3.1-brightgreen)]()

## 📖 简介

`ai-handover` 是一个平台无关的 AI 交接记录技能，将 AI 协作中的上下文传递最佳实践标准化为可复用的技能文件。**v3.1** 强化规则升级：新增 P0 强制触发（执行方必须写交接）、任务完成报告格式、调用方验证责任、执行方返回空/失败处理。**纯 Markdown 技能，平台无关，适用于任何 AI 协作架构**。

支持多种记录类型（交接/进度/决策）和项目类型（软件/学术/文档/运维），解决多 AI 协作中的"失忆症"问题。

### 痛点

当不同 AI 模型或不同会话之间切换时，新接手的 AI 面临：

- ❌ 不知道有哪些活跃项目
- ❌ 不知道上次做到哪了
- ❌ 不知道去哪找历史记录
- ❌ 不知道执行记录需要哪些字段
- ❌ 不知道文件夹命名规范
- ❌ 写完记录后忘记更新索引
- ❌ 需要手动计算时间戳和校验格式

### 解决

v3.1 提供开箱即用的标准化流程（纯 Markdown，无外部脚本依赖）：

```
智能识别参数 → 创建时间戳文件夹 → 按模块选择矩阵选字段 → 编写执行记录 → 更新索引 → 生成统计 → 自检
```

## 🆕 v3.1 新增能力

| 新增 | 说明 |
|------|------|
| 🔴 P0 强制触发 | 执行方完成任务后必须写交接记录，调用方必须验证 |
| 📋 任务完成报告 | 执行方返回结果的标准格式（含产出物/交接路径/操作摘要/遗留问题） |
| ✅ 调用方验证 | 调用方收到执行结果后必须检查交接完整性 |
| 🚫 空返回处理 | 执行方返回空/失败时的正确处理流程（重新委托，禁止调用方上手） |

## 🧠 智能识别

无需显式指定参数，AI 从自然语言自动推断：

| 用户表述 | 推断参数 |
|---------|---------|
| "简单记一下" | detail=summary |
| "详细记录" | detail=full |
| "进度更新" | type=progress |
| "决策记录" | type=decision |
| 提到 git/coding | project_type=software |
| 提到 paper/实验 | project_type=academic |
| 提到 deployment/配置 | project_type=ops |

## 📚 模板库

`references/templates/` 目录提供 4 种预设模板：

| 模板 | 适用场景 |
|------|----------|
| `software.md` | 软件开发（代码变更、架构决策） |
| `academic.md` | 学术研究（文献来源、方法选择） |
| `docs.md` | 文档写作（结构、版本变更） |
| `ops.md` | 运维部署（配置变更、部署步骤） |

## 🎛️ 参数系统

通过参数控制行为，适应不同场景：

| 参数 | 说明 | 默认值 | 可选值 |
|------|------|--------|--------|
| `type` | 记录类型 | handover | handover / progress / decision |
| `project_type` | 项目类型 | auto | auto / software / academic / docs / ops |
| `detail` | 详细程度 | full | full / summary / minimal |
| `output` | 输出格式 | markdown | markdown / json |

- **type=handover**：完整交接记录（所有模块）
- **type=progress**：进度更新（基本信息 + 产出物 + 下一步）
- **type=decision**：决策记录（基本信息 + 技术决策 + 理由）
- **detail=summary**：精简版，仅关键字段
- **detail=minimal**：极简版，仅任务名称 + 状态 + 产出

## 🎯 触发条件

| 优先级 | 条件 |
|--------|------|
| 🔴 P0 强制 | AI agent 完成一个独立任务 |
| 🔴 P0 强制 | 完成一个独立功能/修复 |
| 🔴 P0 强制 | 会话结束前 |
| 🟡 建议 | 任务中途发现重大问题 |
| 🟡 建议 | 用户说"记录/交接/handover" |

## 📁 模块选择矩阵

根据记录类型和详细程度自动选择模块组合：

| 模块 | handover | progress | decision | summary | minimal |
|------|----------|----------|----------|---------|---------|
| 基本信息 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 执行过程 | ✅ | ✅ | ❌ | ✅ | ❌ |
| 产出物 | ✅ | ✅ | ❌ | ✅ | ✅ |
| 技术决策 | ✅ | ❌ | ✅ | ❌ | ❌ |
| 环境信息 | ✅ | ❌ | ❌ | ❌ | ❌ |
| 遗留问题 | ✅ | ✅ | ❌ | ✅ | ❌ |
| 下一步计划 | ✅ | ✅ | ❌ | ✅ | ❌ |

## 🏗️ 项目类型适配

| 项目类型 | 模板差异 |
|---------|---------|
| software | 默认模板，关注代码变更、架构决策 |
| academic | 强调文献来源、方法选择、实验参数 |
| docs | 强调文档结构、版本变更、审阅记录 |
| ops | 强调配置变更、环境变量、部署步骤 |

## 🏷️ 标签系统

每个执行记录可添加标签用于快速检索：

```markdown
## 基本信息
- **标签**：#bug #feature #refactor
```

常用标签：`#bug` `#feature` `#refactor` `#docs` `#test` `#perf` `#security` `#breaking`

## 📁 生成的目录结构

```
项目根目录/
├── AI交接记录/
│   ├── 索引.md                          ← 时间倒序任务总览（自动生成）
│   ├── 统计.md                          ← 全局统计（自动生成）
│   ├── 2026-05-17_121836_任务A/
│   │   └── 执行记录.md                  ← 按模块选择矩阵选字段
│   └── 2026-05-17_150000_任务B/
│       └── 执行记录.md
└── references/                          ← 参考资料
    └── templates/
        ├── software.md
        ├── academic.md
        ├── docs.md
        └── ops.md
```

## 📋 执行记录模板

```markdown
# [任务简述]

## 基本信息
- 任务名称、执行 AI、开始/结束时间、前置状态、标签

## 执行过程
- 关键操作、遇到的问题、技术决策

## 产出物
- 文件/目录清单及说明

## 后置状态
- 项目状态、环境信息（venv路径、依赖变更等）

## 遗留问题
- 问题列表（含严重程度 🔴🟡🟢）

## 下一步计划
- 具体可执行的动作清单
```

**详细模板**：见 `references/templates/` 下的 4 种项目类型模板。

## ✅ 自检清单

| # | 检查项 | 通过标准 |
|---|--------|----------|
| 1 | 文件夹命名 | `YYYY-MM-DD_HHmmss_中文简述` |
| 2 | 字段完整 | 按模块选择矩阵包含对应字段 |
| 3 | 索引更新 | 新条目在顶部 |
| 4 | 时间精确 | 到分钟 |
| 5 | 问题分级 | 🔴🟡🟢 标记 |
| 6 | 计划可执行 | 具体动作 |
| 7 | 标签完整 | 关键任务已添加标签 |

## 🛡️ 降级策略

| 缺失信息 | 处理方式 |
|---------|---------|
| Git 变更记录 | 标注「无 Git 信息」，手动描述 |
| 环境配置 | 记录已知部分，未知标注「待补充」|
| 前置状态 | 若无记录，标注「首次记录」|
| 开始时间 | 以当前时间作为近似起点 |
| 项目类型 | 默认为 software |

## 🔧 安装

### OpenCode 平台

```bash
# 全局安装（推荐）
mkdir -p ~/.config/opencode/skills/ai-handover
cp -r SKILL.md references ~/.config/opencode/skills/ai-handover/

# 项目级安装
mkdir -p .opencode/skills/ai-handover
cp -r SKILL.md references .opencode/skills/ai-handover/
```

重启 OpenCode 后，技能即可通过 `skill("ai-handover")` 加载。

### Claude Code

```bash
mkdir -p ~/.claude/skills/ai-handover
cp -r SKILL.md references ~/.claude/skills/ai-handover/
```

### Cursor

```bash
mkdir -p ~/.cursor/skills/ai-handover
cp -r SKILL.md references ~/.cursor/skills/ai-handover/
```

### 其他平台 (Codex CLI)

```bash
mkdir -p ~/.codex/skills/ai-handover
cp -r SKILL.md references ~/.codex/skills/ai-handover/
```

## 🚫 反模式

| ❌ 禁止 | ✅ 正确 |
|---------|--------|
| 不写记录就切换任务 | 每个任务完成后立即记录 |
| 只更新记录不更新索引 | 两者同步，索引在顶部 |
| 遗留问题不标严重度 | 🔴🟡🟢 三级标记 |
| "下一步"写"继续开发" | 写具体动作："实现 POST /api/users" |
| 文件夹缺秒级时间 | 完整 `HHmmss` |
| 无视降级策略导致空字段 | 标注「待补充」而非留空 |
| 关键任务无标签 | 添加 `#bug` `#feature` 等标签 |
| 仅对话输出不写文件 | 必须写入 `AI交接记录/` 目录 |
| 执行方返回无交接路径 | 返回结果必须含路径引用 |
| 调用方收到空结果自己动手 | 重新委托/简化重试/换执行方 |

## 📄 许可

MIT License

## 📜 变更记录

| 版本 | 日期 | 变更 |
|------|------|------|
| 3.1 | 2026-06-24 | P0强制触发 + 任务完成报告格式 + 调用方验证责任 + 空返回处理 + 反模式更新 |
| 3.0 | 2026-06-05 | 智能识别、模板库（references/templates/）、全局统计、标签系统 |
| 2.0 | 2026-06-05 | 参数系统、项目类型适配、模块选择、降级策略、JSON 输出、平台兼容 |
| 1.0 | - | 初始版本：4 步标准化流程 |

## 🤝 贡献

欢迎提 Issue 或 PR 改进本技能。核心原则：**让任何 AI 在 1 分钟内了解项目全貌**。
