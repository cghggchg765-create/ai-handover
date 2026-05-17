# AI Handover Records (AI 交接记录)

> 标准化 AI Agent 交接文档管理技能 — 确保任何 AI 接手后能在 **1 分钟内** 了解项目全貌

[![OpenCode](https://img.shields.io/badge/platform-OpenCode-blue)](https://opencode.ai)
[![Skill Version](https://img.shields.io/badge/version-1.0-green)]()

## 📖 简介

`ai-handover` 是一个面向 OpenCode 平台的 Agent Skill，将 AI 交接记录这一最佳实践标准化为可复用的技能文件，解决多 AI 协作中的"失忆症"问题。

### 痛点

当不同 AI 模型或不同会话之间切换时，新接手的 AI 面临：

- ❌ 不知道有哪些活跃项目
- ❌ 不知道上次做到哪了
- ❌ 不知道去哪找历史记录
- ❌ 不知道执行记录需要哪些字段
- ❌ 不知道文件夹命名规范
- ❌ 写完记录后忘记更新索引

### 解决

本技能提供开箱即用的 4 步标准化流程：

```
创建时间戳文件夹 → 编写执行记录 → 更新索引 → 自检
```

## 🎯 触发条件

| 优先级 | 条件 |
|--------|------|
| 🔴 强制 | 完成一个独立功能/修复 |
| 🔴 强制 | 会话结束前 |
| 🟡 建议 | 任务中途发现重大问题 |
| 🟡 建议 | 用户说"记录/交接/handover" |

## 📁 生成的目录结构

```
项目根目录/
└── AI交接记录/
    ├── 索引.md                          ← 时间倒序任务总览
    ├── 2026-05-17_121836_任务A/
    │   └── 执行记录.md                  ← 9 字段标准化记录
    └── 2026-05-17_150000_任务B/
        └── 执行记录.md
```

## 📋 执行记录模板（9 个必填字段）

```markdown
# [任务简述]

## 基本信息
- 任务名称、执行 AI、开始/结束时间、前置状态

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

## ✅ 自检清单（6 项）

| # | 检查项 | 通过标准 |
|---|--------|----------|
| 1 | 文件夹命名 | `YYYY-MM-DD_HHmmss_中文简述` |
| 2 | 字段完整 | 全部 9 个字段 |
| 3 | 索引更新 | 新条目在顶部 |
| 4 | 时间精确 | 到分钟 |
| 5 | 问题分级 | 🔴🟡🟢 标记 |
| 6 | 计划可执行 | 具体动作 |

## 🔧 安装

### OpenCode 平台

将 `SKILL.md` 复制到 OpenCode 技能目录：

```bash
# 全局安装（推荐）
mkdir -p ~/.config/opencode/skills/ai-handover
cp SKILL.md ~/.config/opencode/skills/ai-handover/

# 项目级安装
mkdir -p .opencode/skills/ai-handover
cp SKILL.md .opencode/skills/ai-handover/
```

重启 OpenCode 后，技能即可通过 `skill("ai-handover")` 加载。

### 其他平台（Claude Code / Codex / Cursor）

```bash
# Claude Code
cp SKILL.md ~/.claude/skills/ai-handover/

# OpenAI Codex
cp SKILL.md ~/.codex/skills/ai-handover/
```

## 🚫 反模式

| ❌ 禁止 | ✅ 正确 |
|---------|--------|
| 不写记录就切换任务 | 每个任务完成后立即记录 |
| 只更新记录不更新索引 | 两者同步，索引在顶部 |
| 遗留问题不标严重度 | 🔴🟡🟢 三级标记 |
| "下一步"写"继续开发" | 写具体动作："实现 POST /api/users" |
| 文件夹缺秒级时间 | 完整 `HHmmss` |

## 📄 许可

MIT License

## 🤝 贡献

欢迎提 Issue 或 PR 改进本技能。核心原则：**让任何 AI 在 1 分钟内了解项目全貌**。
