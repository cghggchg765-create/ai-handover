# AI 交接记录 · AI Handover Records

> **Bridging AI sessions. Seamlessly.**
> 确保任何 AI 接手后能在 **1 分钟内**了解项目全貌。

<p align="center">
  <img src="https://img.shields.io/badge/version-4.1-brightgreen" alt="Version 4.1">
  <img src="https://img.shields.io/badge/Darwin%20Score-82.7%20(%2B3.3)-blue" alt="Darwin Score 82.7">
  <img src="https://img.shields.io/badge/IRON%20RULE-8%20rules%20enforced-red" alt="8 IRON RULES">
  <img src="https://img.shields.io/badge/platform-OpenCode_%7C_Claude_Code_%7C_Cursor_%7C_Codex_CLI-purple" alt="Multi-platform">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License">
  <img src="https://img.shields.io/badge/eval-15%20scenarios-ff69b4" alt="15 evaluation scenarios">
</p>

---

## 核心能力

| | | |
|:---:|:---:|:---:|
| **IRON RULE 强制合规**<br>8 条不可协商的 P0 铁律<br>涵盖交接/元数据/Trailer/状态机/锁<br>违反即任务未完成 | **三层记忆**<br>`wiki/` 持久知识沉淀<br>`agents/` 跨会话学习<br>`messages/` 实时协调 | **Git 同步**<br>4 种强制 git trailer<br>validate.sh 提交前校验<br>`Coding-Agent` / `Model` / `Constraint` / `Rejected-Alternatives` |

---

## IRON RULE 8 条 快速一览

| # | 规则 | 后果 | 检测机制 |
|:-:|:-----|:----:|:--------:|
| 1 | 完成任务必须写 AI 交接记录 | 拒收结果，标记未完成 | 调用方前置检查 |
| 2 | YAML frontmatter 必填字段不可缺失 | 责令按模板重写 | 正则校验 + Schema 验证 |
| 3 | 提交必须包含 4 种强制 trailer | `validate.sh` 拒绝 commit | `validate.sh` + git hook |
| 4 | Co-authored-by 不可替代 Coding-Agent/Model trailers | `validate.sh` 拒绝 commit | trailer 白名单检查 |
| 5 | Lane 状态机禁止跳过 review（in-progress → needs-review → resolved） | 回退 + 警告输出 | `validate.sh` 状态机检查 |
| 6 | 并行写同一文件必须声明文件锁 | 第二个写入阻塞/冲突标记 | `.locks/` 锁检测 |
| 7 | 分支命名必须遵循 `<agent-type>/<task-summary>` 格式 | 不合规分支被拒绝合并 | git hook 分支名校验 |
| 8 | 新 Agent 必须按入职流程恢复上下文 | 跳过步骤视为违规 | 入职顺序检查器 |

---

## 架构全景

```
项目根目录/
├── AI交接记录/
│   ├── 索引.md                         ← 时间倒序总览（自动更新）
│   ├── 统计.md                         ← 全局统计
│   ├── 2026-05-17_121836_数据库迁移/    ← YAML frontmatter 执行记录
│   │   ├── 执行记录.md                  ← 完整交接内容（含 prev_handover_id）
│   │   └── review-response.md           ← 评审反馈
│   └── 2026-06-10_093000_API限流修复/
│       └── 执行记录.md
├── .locks/
│   ├── src/config.yaml.lock             ← 文件锁（并行写入保护）
│   └── ...
├── wiki/
│   ├── hot.md                           ← 高频模式/热点知识
│   └── bugs.md                          ← 已知 bug 模式库
├── agents/
│   └── coder-001/                       ← 跨会话 agent 学习记录
│       └── 学习记录.md
├── messages/
│   └── inbox.jsonl                      ← agent 间异步消息队列
├── lanes/
│   └── current.yaml                     ← 任务状态机（pending / in-progress / needs-review / resolved）
├── active.md                            ← 当前活跃任务列表
├── references/
│   └── templates/
│       ├── software.md
│       ├── academic.md
│       ├── docs.md
│       └── ops.md
├── validate.sh                          ← IRON RULE 合规校验脚本
└── branches/
    └── policy.yaml                      ← 分支命名策略定义
```

---

## 快速开始

### 3 步安装

```bash
# Step 1: 安装技能文件到 OpenCode
mkdir -p ~/.config/opencode/skills/ai-handover
cp -r SKILL.md references ~/.config/opencode/skills/ai-handover/

# Step 2: 注册 validate.sh 作为 git hook
cp validate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Step 3: 初始化项目交接目录
mkdir -p AI交接记录 .locks wiki agents messages lanes
touch AI交接记录/索引.md lanes/current.yaml active.md
echo "[]" > messages/inbox.jsonl
```

### 30 秒使用

```markdown
# 完成任务后自动触发
skill("ai-handover")

# 或自然语言：
"把这次迁移交接给reviewer"
"记录这个bug模式到wiki"
"新agent入职，先读hot和索引"
```

---

## 核心设计

### IRON RULE 系统

v4.1 引入 **8 条 IRON RULE**，每条规则对应一个强制合规检查点：

| 规则 | 触发阶段 | 对应组件 |
|:----:|:--------:|:--------:|
| #1 交接记录 | 任务完成时 | 调用方检查器 |
| #2 YAML Schema | 交接记录创建时 | frontmatter 验证器 |
| #3 Git Trailers | git commit 时 | `validate.sh` |
| #4 Trailer 禁用别名 | git commit 时 | `validate.sh` |
| #5 Lane 状态机 | lane 状态变更时 | `validate.sh` |
| #6 文件锁 | 并发写入时 | `.locks/` 锁管理器 |
| #7 分支命名 | 创建分支时 | git hook |
| #8 Agent 入职 | 新 agent 加入时 | 入职顺序检查器 |

违反任何 IRON RULE 都会导致任务被标记为未完成。规则不可绕过、不可协商、不可豁免。

### YAML Frontmatter Schema（v4.1）

每份执行记录开头必须包含标准化的 YAML 元信息：

```yaml
---
title: 数据库迁移脚本重构
agent: coder
agent_version: glm-5.2
type: handover
status: completed
lane: needs-review
created_at: 2026-06-25T14:30:00+08:00
prev_handover_id: 2026-06-25_120000_API设计     # 上一交接记录（链式追溯）
tags:
  - database
  - migration
  - schema
revisions: 1
---
```

| 字段 | 必填 | v4.1 新增 | 说明 |
|------|:----:|:---------:|------|
| `title` | ✅ | | 任务简述 |
| `agent` | ✅ | | 执行 agent 类型 |
| `agent_version` | ✅ | | agent 模型标识 |
| `type` | ✅ | | handover / progress / decision |
| `status` | ✅ | | completed / blocked / partial |
| `lane` | ✅ | | in-progress / needs-review / resolved |
| `created_at` | ✅ | | ISO 8601 时间戳 |
| `prev_handover_id` | | ✅ | 上一交接记录目录名，用于链式追溯 |
| `tags` | ✅ | | 分类标签 |
| `revisions` | ✅ | | 修订版本号 |

### 三层记忆

```
Layer 1: wiki/       ← 持久知识（bug 模式、最佳实践、hot 热点）
  ├── bugs.md        — 已知 bug 模式库，含描述+示例+修复建议
  └── hot.md         — 高频热点知识，自动发现并记录

Layer 2: agents/     ← 跨会话学习（每个 agent 独立目录）
  └── coder-001/
      └── 学习记录.md — 经验、偏好、失败模式

Layer 3: messages/   ← 实时协调（agent 间异步通讯）
  └── inbox.jsonl    — JSONL 格式，支持 review_request / review_response / handoff 等消息类型
```

### Lane 状态机

```
         ┌──────────┐
         │  pending  │
         └────┬─────┘
              │ 开始执行
              ↓
      ┌───────────────┐
      │  in-progress   │
      └───────┬───────┘
              │ 任务完成
              ↓
     ┌──────────────────┐
     │  needs-review     │ ← IRON RULE #5: 非法跳过此步则拒绝+回退
     └────────┬─────────┘
              │ 评审通过
              ↓
        ┌────────────┐
        │  resolved   │
        └────────────┘
```

**非法状态迁移检测（validate.sh）**：
- `in-progress → resolved`：❌ IRON RULE #5 违规，拒绝变更
- `needs-review → in-progress`：⚠️ 退回修改，允许
- `resolved → needs-review`：⚠️ 重新评审，允许

### Git Trailers 协议

每次提交自动附加结构化 trailers，实现全链路追溯：

```
commit abc123def456
Author: coder <agent@ai-handover>
Date:   Thu Jun 25 14:30:00 2026 +0800

    fix: API rate limiter overflow (#42)

    Coding-Agent: glm-5.2
    Model: v4.1
    Constraint: compatible with Python 3.8+
    Rejected-Alternatives: Redis (avoids new dependency)
```

| Trailer | 必填 | IRON RULE | 说明 |
|---------|:----:|:---------:|------|
| `Coding-Agent` | ✅ | #3 | 执行编码的 agent 标识 |
| `Model` | ✅ | #3 | 模型版本号 |
| `Constraint` | ✅ | #3 | 关键约束条件 |
| `Rejected-Alternatives` | ✅ | #3 | 已排除的方案及理由 |

**禁止**：使用 `Co-authored-by` 或其他非标准 trailer 替代上述 4 种强制 trailer（IRON RULE #4）。

---

## 调用方拒绝协议

> **调用方（主 agent）在发现以下情况时必须拒绝接受子 agent 的返回结果：**

```
┌─────────────────────────────────────────────────────┐
│  违反 IRON RULE #1 → 缺交接记录 → 拒收             │
│  违反 IRON RULE #2 → YAML 缺字段  → 责令重写       │
│  违反 IRON RULE #3 → 缺 trailers → 拒绝 commit     │
│  违反 IRON RULE #5 → 非法跳转    → 回退 + 警告     │
│  违反 IRON RULE #6 → 锁冲突      → 标记冲突        │
│  子 agent 返回空  → 重新委托/简化/换 agent         │
│  连续 2 次失败    → 升级给用户                     │
└─────────────────────────────────────────────────────┘
```

**底线**：调用方**禁止**绕过拒绝协议自己动手修改子 agent 的输出。必须重新委托或升级处理。

---

## 文件锁 + 分支策略

### 文件锁（IRON RULE #6）

并行 Agent 写同一文件时，必须先声明文件锁：

```bash
# Agent A 获取锁
echo "coder-001" > .locks/src/config.yaml.lock

# Agent B 尝试获取锁（失败）
cat .locks/src/config.yaml.lock  # → "coder-001"
# → 输出警告：文件已被 coder-001 锁定，等待释放

# Agent A 释放锁
rm .locks/src/config.yaml.lock
```

### 分支策略（IRON RULE #7）

所有分支命名必须遵循 `<agent-type>/<task-summary>` 格式：

| 分支名 | 合规 | 说明 |
|:-------|:----:|:-----|
| `coder/fix-auth-token` | ✅ | agent 类型 + 任务描述 |
| `reviewer/review-auth-module` | ✅ | reviewer 分支 |
| `fix-bug` | ❌ | 缺少 agent 类型前缀 |
| `main` | ✅ | 受保护分支，规则豁免 |

---

## Darwin 进化历程

本技能经过 **Darwin 进化引擎** 4 轮自动化优化与架构升级：

| 轮次 | 分数 | 变化 | 改进内容 |
|:----:|:----:|:----:|---------|
| baseline | 74.5 | — | 初始版本 v3.1 |
| Round 1 | 78.7 | +4.2 | 集中式失败 if-then 表 + 3 处工作流显式检查点 |
| Round 2 | 79.4 | +0.7 | 精简 frontmatter + 版本号一致性修复 |
| **v4.0** | **79.4** | **—** | **YAML结构 + 三层记忆 + Lane状态机 + Git Trailers + 多Agent消息协议** |
| **v4.1** | **82.7** | **+3.3** | **IRON RULE系统 + 文件锁 + validate.sh + 分支策略 + 扩展评估集至15场景** |

**9 维度评分明细（v4.1）**：

```
结构完整性    ██████████████░░  84%  (+5)
命名规范性    █████████████░░░  80%  (+2)
元数据完备    ████████████████  86%  (+4)
触发准确度    ██████████████░░  82%  (+6)
流程清晰度    ███████████████░  87%  (+4)
反模式覆盖    ███████████████░  87%  (+6)
可维护性      ██████████████░░  81%  (+4)
版本管理      ████████████████  85%  (+3)
平台兼容性    ███████████████░  87%  (+1)
```

---

## 评估集

`test-prompts.json` 包含 **15 个测试场景**（P0 覆盖 + v4.0 多Agent + v4.1 IRON RULE）：

| ID | 场景 | 验证内容 | 归属版本 |
|:--:|:----|:--------|:--------:|
| 1 | 完成修复后正常记录 | 完整交接流程（文件夹+执行记录+索引） | v3.x |
| 2 | 子 agent 未写交接 | 调用方验证责任 + 责令补写 | v3.x |
| 3 | 子 agent 返回空结果 | 禁止调用方上手 + 重新委托流程 | v3.x |
| 4 | 多Agent交接 | YAML frontmatter + lane更新 + inbox消息 + 索引 | v4.0 |
| 5 | 跨Agent消息协议 | 消息链读取 + review-response 生成 + 状态 resolved | v4.0 |
| 6 | Lane状态机校验 | 非法状态迁移检测 + 警告输出 | v4.0 |
| 7 | Git Trailers | Coding-Agent / Model / Constraint / Rejected-Alternatives | v4.0 |
| 8 | Wiki知识提取 | bugs.md 新增 + hot.md 更新 | v4.0 |
| 9 | IRON RULE #1 测试 | 缺交接记录 → 调用方拒收 + 责令补写 | v4.1 |
| 10 | IRON RULE #2 测试 | YAML 缺字段 → 调用方拒收 + 列出缺失字段 | v4.1 |
| 11 | IRON RULE #3+#4 测试 | Co-authored-by 替代 trailers → validate.sh 拒绝 | v4.1 |
| 12 | IRON RULE #5 测试 | lane 跳过 review → validate.sh 回退 + 警告 | v4.1 |
| 13 | IRON RULE #6 测试 | 并行写文件 + 锁冲突 → 阻塞 + 冲突标记 | v4.1 |
| 14 | 跨任务链测试 | 3 Agent 交接链完整性 → prev_handover_id 链无断裂 | v4.1 |
| 15 | IRON RULE #8 测试 | 新 Agent 入职 → 按序恢复上下文 | v4.1 |

---

## v3.x vs v4.0 vs v4.1 对比

| 能力 | v3.x | v4.0 | v4.1 |
|:-----|:----:|:----:|:----:|
| 基本交接流程 | ✅ | ✅ | ✅ |
| 模块选择矩阵 | ✅ | ✅ | ✅ |
| 失败处理表 | ✅ | ✅ | ✅ |
| **YAML Frontmatter** | ❌ | ✅ 强制校验 | ✅ 新增 prev_handover_id |
| **IRON RULE 系统** | ❌ | ❌ | ✅ 8 条强制规则 |
| **三层记忆 (wiki/agents/messages)** | ❌ | ✅ 持久化 | ✅ 持久化 |
| **Lane 状态机** | ❌ | ✅ 含非法迁移检测 | ✅ validate.sh 自动校验 |
| **Git Trailers** | ❌ | ✅ 4 种强制 trailer | ✅ validate.sh commit 检查 |
| **多Agent 消息协议** | ❌ | ✅ inbox.jsonl | ✅ inbox.jsonl |
| **跨Agent 评审闭环** | ❌ | ✅ review闭环 | ✅ review闭环 |
| **Wiki 知识提取** | ❌ | ✅ bugs.md + hot.md | ✅ bugs.md + hot.md |
| **文件锁机制** | ❌ | ❌ | ✅ `.locks/` 并发保护 |
| **分支命名策略** | ❌ | ❌ | ✅ git hook 校验 |
| **调用方拒绝协议** | ❌ | ❌ | ✅ 正式定义 |
| **validate.sh 合规脚本** | ❌ | ❌ | ✅ git hook + 状态机校验 |
| 评估场景数 | 3 | 8 | **15** |
| Darwin 评分 | 79.4 | 79.4+ | **82.7** |

---

## 平台兼容

| 平台 | 安装路径 | 自动识别 | v4.1 兼容 |
|------|---------|:--------:|:--------:|
| **OpenCode** | `~/.config/opencode/skills/ai-handover/` | ✅ | ✅ |
| **Claude Code** | `~/.claude/skills/ai-handover/` | ✅ | ✅ |
| **Cursor** | `~/.cursor/skills/ai-handover/` | ✅ | ✅ |
| **Codex CLI** | `~/.codex/skills/ai-handover/` | ✅ | ✅ |

---

## 变更记录

| 版本 | 日期 | 变更 |
|:----:|:----:|:-----|
| **4.1** | 2026-06-26 | **IRON RULE 系统升级**：8 条不可协商的 P0 铁律；validate.sh 合规校验脚本（trailer 检查 + 状态机校验 + 分支名检查）；`.locks/` 文件锁机制支持并行 Agent 安全写入；`prev_handover_id` 字段实现交接链完整追溯；正式定义调用方拒绝协议；分支命名策略 git hook；`active.md` 活跃任务追踪；新 Agent 入职流程（IRON RULE #8）；评估场景从 8 扩展至 15；Darwin 评分 79.4 → 82.7 |
| **4.0** | 2026-06-26 | 多Agent协作完整升级：YAML Frontmatter Schema + 三层记忆（wiki/agents/messages）+ Lane 状态机 + Git Trailers 协议 + 跨Agent 消息队列 + Wiki 知识提取；评估场景扩展至 8 个 |
| **3.2** | 2026-06-24 | Darwin 进化：集中式失败 if-then 表 + 3 处工作流检查点 + frontmatter 优化，评分 74.5 → 79.4 |
| **3.1** | 2026-06-24 | P0 强制触发（执行方必须写交接）+ 任务完成报告格式 + 调用方验证责任 + 空返回/失败处理 + 反模式更新 |
| **3.0** | 2026-06-05 | 智能识别、模板库（references/templates/）、全局统计、标签系统 |
| **2.0** | 2026-06-05 | 参数系统、项目类型适配、模块选择、降级策略、JSON 输出、平台兼容 |
| **1.0** | — | 初始版本：4 步标准化流程 |

---

## 许可 + 贡献

MIT License © 2026 AI Handover Contributors

欢迎提 Issue 或 PR 改进本技能。核心原则：

> **让任何 AI 在 1 分钟内了解项目全貌。**

---

<div align="center">
  <strong>AI 交接记录 · v4.1</strong> · IRON RULE 8 条强制合规 · Darwin 评分 82.7/100 · MIT License
  <br>
  <sub>Made for AI agents, by AI agents.</sub>
</div>
