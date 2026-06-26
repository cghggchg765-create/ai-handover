# AI 交接记录 · AI Handover Records

> **Bridging AI sessions. Seamlessly.**
> 确保任何 AI 接手后能在 **1 分钟内**了解项目全貌。

<p align="center">
  <img src="https://img.shields.io/badge/version-4.1-brightgreen" alt="Version 4.1">
  <img src="https://img.shields.io/badge/Darwin%20Score-82.7%20(planned)-orange" alt="Darwin Score 82.7 (planned)">
  <img src="https://img.shields.io/badge/IRON%20RULE-9%20rules%20enforced-red" alt="9 IRON RULES">
  <img src="https://img.shields.io/badge/platform-OpenCode_%7C_Claude_Code_%7C_Cursor_%7C_Codex_CLI-purple" alt="Multi-platform">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License">
  <img src="https://img.shields.io/badge/eval-17%20scenarios-ff69b4" alt="17 evaluation scenarios">
</p>

---

## 核心能力

| | | |
|:---:|:---:|:---:|
| **IRON RULE 强制合规**<br>9 条不可协商的 P0 铁律<br>涵盖交接/元数据/Trailer/状态机/锁/分支<br>违反即任务未完成 | **三层记忆**<br>`wiki/` 持久知识沉淀<br>`agents/` 跨会话学习<br>`messages/` 实时协调 | **Git 同步**<br>3 种强制 git trailer<br>validate.sh 提交前校验<br>`Handover-Id` / `Coding-Agent` / `Model` |

---

## IRON RULE 9 条 快速一览

| # | 规则 | 后果 | 检测机制 |
|:-:|:-----|:----:|:--------:|
| 1 | 强制写交接记录 | 拒收结果，标记未完成 | 调用方前置检查 |
| 2 | 模板格式强制（YAML双轨制） | 责令按模板重写 | 正则校验 + Schema 验证 |
| 3 | Git trailers 强制（Coding-Agent + Model + Handover-Id） | `validate.sh` 拒绝 commit | `validate.sh` + git hook |
| 4 | 交接链强制（prev_handover_id 必填） | 链断裂标记，责令补充 | `validate.sh` 链完整性检查 |
| 5 | 串行状态门控（不可跳过 needs-review） | 回退 + 警告输出 | `validate.sh` 状态机检查 |
| 6 | 并行文件锁 | 第二个写入阻塞/冲突标记 | `.ai-handover/locks/` 锁检测 |
| 7 | hot.md 强制更新 | 未更新视为任务未完成 | `validate.sh` check 7 |
| 8 | 新 Agent 入职流程 | 跳过步骤视为违规 | 入职顺序检查器 |
| 9 | 分支策略强制（agent-xxx/type-yyy 格式） | 不合规分支被拒绝合并 | git hook 分支名校验 |

---

## 架构全景

```
项目根目录/
├── AI交接记录/
│   ├── agents/                           ← Layer 2: 跨会话学习
│   ├── lanes/                            ← 状态机
│   ├── messages/
│   │   └── archive/                      ← 已处理归档
│   └── wiki/                             ← Layer 1: 持久知识
├── .ai-handover/
│   ├── config.json                       ← 运行时配置
│   └── locks/                            ← 文件锁（IRON RULE #6 并行保护）
├── examples/
│   ├── 01-single-agent-fix.md
│   ├── 02-multi-agent-feature.md
│   ├── 03-cross-session-handoff.md
│   ├── 04-parallel-agents-coordination.md
│   ├── 05-fork-merge-git-handoff.md
│   └── 06-cross-task-chain.md
├── references/
│   ├── schemas/
│   │   └── handover.schema.json          ← YAML Schema 定义
│   └── templates/                        ← 交接记录模板
│       ├── academic.md
│       ├── agents/
│       ├── docs.md
│       ├── exec-record.md
│       ├── lanes/
│       ├── locks/
│       ├── messages/
│       ├── ops.md
│       ├── software.md
│       └── wiki/
├── rules/
│   ├── 00-core.md                          ← P0 铁律系统（9 条 IRON RULE）
│   ├── 01-handover.md                      ← YAML Frontmatter 与执行记录规范
│   ├── 02-coordination.md                  ← 多 Agent 协调（串行/并行/状态机）
│   ├── 03-git.md                           ← Git 同步（分支/trailers/恢复协议）
│   ├── 04-validation.md                    ← 验证规则（8 项检查/schema）
│   └── 05-memory.md                        ← 三层记忆（wiki/agents/messages）
├── scripts/
│   ├── commit-with-trailers.sh           ← Git trailers 自动附加
│   ├── message-relay.py                  ← 消息中继处理
│   └── validate.sh                       ← IRON RULE 合规校验脚本
├── README.md
├── results.tsv
├── SKILL.md
└── test-prompts.json
```
> 📌 `AI交接记录/` 目录及内部文件由 AI agent 在首次任务完成后自动创建。也可手动运行初始化脚本。

---

## 快速开始

### 3 步安装

```bash
# Step 1: 安装技能文件到 OpenCode
mkdir -p ~/.config/opencode/skills/ai-handover
cp -r SKILL.md references ~/.config/opencode/skills/ai-handover/

# Step 2: 注册 validate.sh 作为 git hook
cp scripts/validate.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Step 3: 初始化项目交接目录
mkdir -p AI交接记录/wiki AI交接记录/agents AI交接记录/messages/archive AI交接记录/lanes .ai-handover/locks references/templates references/schemas
touch AI交接记录/索引.md AI交接记录/lanes/active.md AI交接记录/lanes/reviews.md AI交接记录/messages/inbox.jsonl
```
> 💡 Windows 用户：使用 Git Bash 或 WSL 运行上述命令。PowerShell 用户可将 `cp -r` 替换为 `Copy-Item -Recurse`，`chmod +x` 可跳过。

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

v4.1 引入 **9 条 IRON RULE**，每条规则对应一个强制合规检查点：

| 规则 | 触发阶段 | 对应组件 |
|:----:|:--------:|:--------:|
| #1 强制写交接记录 | 任务完成时 | 调用方检查器 |
| #2 模板格式强制 | 交接记录创建时 | frontmatter 验证器 |
| #3 Git Trailers | git commit 时 | `validate.sh` |
| #4 交接链强制 | 交接记录创建时 | `validate.sh` 链检查 |
| #5 串行状态门控 | lane 状态变更时 | `validate.sh` |
| #6 并行文件锁 | 并发写入时 | `.ai-handover/locks/` 锁管理器 |
| #7 hot.md 强制更新 | 交接完成后 | `validate.sh` |
| #8 新 Agent 入职流程 | 新 agent 加入时 | 入职顺序检查器 |
| #9 分支策略强制 | 创建分支时 | git hook |

违反任何 IRON RULE 都会导致任务被标记为未完成。规则不可绕过、不可协商、不可豁免。

### YAML Frontmatter Schema（v4.1）

每份执行记录开头必须包含标准化的 YAML 元信息（双轨制——YAML frontmatter 机器可解析 + Markdown 正文人类可阅读）：

```yaml
---
# === Agent 身份 ===
handover_id: 2026-06-26_143052_user-auth   # 唯一 ID：<日期>_<时间>_<任务简述>
prev_handover_id: init                       # 前一个交接 ID，首次填 "init"
agent_id: coder@build                         # Agent 唯一标识：<角色>@<会话>
agent_role: worker                            # 枚举：primary / orchestrator / worker / reviewer / validator
coding_agent: OpenCode v1.2.3                 # 工具层
model: claude-opus-4-6                        # 模型层

# === 任务标识 ===
task_type: feature                            # 枚举：feature / fix / refactor / docs / research / review
handover_type: handover                       # 枚举：handover / progress / decision

# === 状态机 ===
status: needs-review                          # 枚举：idle / in-progress / needs-review / ready-for-merge / resolved / blocked
previous_status: in-progress                  # 上一个状态（审计用）
branch: feat/user-auth                        # 当前分支

# === 变更证据 ===
files_modified:                               # 修改的文件列表
  - src/auth/login.ts
  - src/auth/session.ts
lock_files:                                    # IRON RULE #6: 文件锁列表
  - .ai-handover/locks/src-auth-session.json
verification:                                 # 验证结果 [命令]:[状态]
  - "npm test -- --grep session:pass"

# === 风险与后续 ===
next_action: "@reviewer please review src/auth/session.ts:42-48"
confidence: high                              # 枚举：low / medium / high
---
```

| 字段 | 必填 | v4.1 新增 | 说明 |
|------|:----:|:---------:|------|
| `handover_id` | ✅ | ✅ | 全局唯一 ID，`<日期>_<时间>_<任务简述>` |
| `prev_handover_id` | ✅ | ✅ | 前一个交接 ID，首次填 `init`（IRON RULE #4）|
| `agent_id` | ✅ | ✅ | `角色@会话` 格式，如 `coder@build` |
| `agent_role` | ✅ | ✅ | primary / orchestrator / worker / reviewer / validator |
| `coding_agent` | ✅ | ✅ | 使用的 AI 工具 |
| `model` | ✅ | ✅ | 模型名称 |
| `status` | ✅ | | 当前 Lane 状态 |
| `branch` | ✅ | ✅ | 当前分支 |
| `files_modified` | ✅ | ✅ | 至少 1 个 |
| `verification` | ✅ | ✅ | 至少 1 个 |
| `lock_files` | ✅ | ✅ | 文件锁列表（IRON RULE #6 强制）|
| `next_action` | ✅ | ✅ | 指定下一个 Agent 的动作 |

> 🔴 IRON RULE #2 强制：以上 12 个字段为必填，不可省略。

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
          │   idle   │
          └────┬─────┘
               │ 开始执行
               ↓
       ┌───────────────┐
       │  in-progress   │
       └───┬───────┬───┘
           │       │ (阻塞)
           ↓       ↓
   ┌──────────────────┐     ┌──────────┐
   │  needs-review     │ ←── │ blocked  │
   └───┬──────────┬───┘     └──────────┘
       │ (通过)    │ (不通过)
       ↓           ↓
 ┌─────────────────┐    ┌──────────────────┐
 │ ready-for-merge  │    │ changes-requested  │
 └────────┬────────┘    └────────┬─────────┘
          │ 合并                  │ 返回修改
          ↓                      ↓
    ┌──────────┐          ┌───────────────┐
    │ resolved │          │  in-progress   │
    └──────────┘          └───────────────┘

另外支持：idle → cancelled（取消）
```

**非法状态迁移检测（validate.sh）**：
- `in-progress → resolved`：❌ IRON RULE #5 违规，拒绝变更
- `in-progress → ready-for-merge`：❌ 跳过 needs-review，拒绝
- `needs-review → in-progress`：⚠️ 退回修改，允许（changes-requested 后）
- `resolved → needs-review`：⚠️ 重新评审，允许

### Git Trailers 协议

每次提交自动附加结构化 trailers，实现全链路追溯：

```
commit abc123def456
Author: coder@build <agent@ai-handover>
Date:   Thu Jun 25 14:30:00 2026 +0800

    feat(auth): add session timeout

    Implement 30-min idle session timeout to match security policy.

    Handover-Id: 2026-06-26_143052_user-auth
    Coding-Agent: OpenCode v1.2.3
    Model: claude-opus-4-6
    Constraint: must not break mobile refresh flow
    Rejected-Alternatives: JWT-only validation | double crypto surface
    Verification: npm test -- --grep session:pass
    Confidence: high
```

| Trailer | 必填 | IRON RULE | 说明 |
|---------|:----:|:---------:|------|
| `Handover-Id` | ✅ | #3 | 关联交接记录 ID |
| `Coding-Agent` | ✅ | #3 | 使用的 AI 工具 |
| `Model` | ✅ | #3 | 模型名称 |
| `Constraint` | 🟡 | | 关键约束条件（可重复）|
| `Rejected-Alternatives` | 🟡 | | 已排除的方案及理由（可重复）|
| `Verification` | 🟡 | | 验证命令 + 结果 |
| `Confidence` | 🟡 | | 信心度 |

**禁止**：使用 `Co-authored-by` 或其他非标准 trailer 替代 `Handover-Id` / `Coding-Agent` / `Model`（IRON RULE #3）。

---

## 调用方拒绝协议

> **调用方（主 agent）在发现以下情况时必须拒绝接受子 agent 的返回结果：**

```
┌────────────────────────────────────────────────────────┐
│  违反 IRON RULE #1 → 缺交接记录 → 拒收                 │
│  违反 IRON RULE #2 → YAML 缺字段  → 责令重写           │
│  违反 IRON RULE #3 → 缺 trailers → 拒绝 commit         │
│  违反 IRON RULE #4 → 链断裂      → 责令补充             │
│  违反 IRON RULE #5 → 非法跳转    → 回退 + 警告          │
│  违反 IRON RULE #6 → 锁冲突      → 标记冲突             │
│  违反 IRON RULE #7 → 未更新 hot.md → 责令补写          │
│  违反 IRON RULE #9 → 分支命名不合规 → 拒绝合并          │
│  子 agent 返回空  → 重新委托/简化/换 agent              │
│  连续 2 次失败    → 升级给用户                          │
└────────────────────────────────────────────────────────┘
```

**底线**：调用方**禁止**绕过拒绝协议自己动手修改子 agent 的输出。必须重新委托或升级处理。

---

## 文件锁 + 分支策略

### 文件锁（IRON RULE #6）

并行 Agent 写同一文件时，必须先声明文件锁：

```bash
# Agent A 获取锁
echo "coder@build" > .ai-handover/locks/src-config-yaml.json

# Agent B 尝试获取锁（失败）
cat .ai-handover/locks/src-config-yaml.json  # → "coder@build"
# → 输出警告：文件已被 coder@build 锁定，等待释放

# Agent A 释放锁
rm .ai-handover/locks/src-config-yaml.json
```

### 分支策略（IRON RULE #9）

所有分支命名必须遵循 `agent-<agent_id>/<type>-<description>` 格式：

| 分支名 | 合规 | 说明 |
|:-------|:----:|:-----|
| `agent-coder@build/feat-session-timeout` | ✅ | agent 标识 + 类型 + 任务描述 |
| `agent-reviewer@codex/review-login` | ✅ | reviewer 分支 |
| `my-branch` | ❌ | 缺少 agent 前缀和类型 |
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
| **v4.1** | **82.7 (planned)** | **+3.3** | **IRON RULE系统 + 文件锁 + validate.sh + 分支策略 + 跨任务交接链 + Git 事件 ↔ Lane 状态映射 + 12 条新反模式 + 扩展评估集至17场景** |

> **Note**: v4.1 Darwin 评分 82.7 为计划目标（planned target）。当前处于评估阶段，最终分数以实际 Darwin 评测结果为准。9 维度评分反映设计目标，非实测数据。

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

`test-prompts.json` 包含 **17 个测试场景**（P0 覆盖 + v4.0 多Agent + v4.1 IRON RULE + v4.1 扩展）：

| ID | 场景 | 验证内容 | 归属版本 |
|:--:|:----|:--------|:--------:|
| 1 | 完成修复后正常记录 | 完整交接流程（文件夹+执行记录+索引） | v3.x |
| 2 | 子 agent 未写交接 | 调用方验证责任 + 责令补写 | v3.x |
| 3 | 子 agent 返回空结果 | 禁止调用方上手 + 重新委托流程 | v3.x |
| 4 | 多Agent交接 | YAML frontmatter + lane更新 + inbox消息 + 索引 | v4.0 |
| 5 | 跨Agent消息协议 | 消息链读取 + review-response 生成 + 状态 resolved | v4.0 |
| 6 | Lane状态机校验 | 非法状态迁移检测 + 警告输出 | v4.0 |
| 7 | Git Trailers | Handover-Id / Coding-Agent / Model / Constraint / Rejected-Alternatives | v4.0 |
| 8 | Wiki知识提取 | bugs.md 新增 + hot.md 更新 | v4.0 |
| 9 | IRON RULE #1 测试 | 缺交接记录 → 调用方拒收 + 责令补写 | v4.1 |
| 10 | IRON RULE #2 测试 | YAML 缺字段 → 调用方拒收 + 列出缺失字段 | v4.1 |
| 11 | IRON RULE #3 测试 | 缺 trailers → validate.sh 拒绝 commit | v4.1 |
| 12 | IRON RULE #5 测试 | lane 跳过 review → validate.sh 回退 + 警告 | v4.1 |
| 13 | IRON RULE #6 测试 | 并行写文件 + 锁冲突 → 阻塞 + 冲突标记 | v4.1 |
| 14 | 跨任务链测试 | 3 Agent 交接链完整性 → prev_handover_id 链无断裂 | v4.1 |
| 15 | IRON RULE #8 测试 | 新 Agent 入职 → 按序恢复上下文 | v4.1 |
| 16 | IRON RULE #7 测试 | Agent 完成任务后未更新 hot.md → 合规检查失败 | v4.1 |
| 17 | IRON RULE #9 测试 | Agent 创建不合规分支 → 分支命名校验拒绝 | v4.1 |

---

## v3.x vs v4.0 vs v4.1 对比

| 能力 | v3.x | v4.0 | v4.1 |
|:-----|:----:|:----:|:----:|
| 基本交接流程 | ✅ | ✅ | ✅ |
| 模块选择矩阵 | ✅ | ✅ | ✅ |
| 失败处理表 | ✅ | ✅ | ✅ |
| **YAML Frontmatter** | ❌ | ✅ 强制校验 | ✅ 新增 prev_handover_id |
| **IRON RULE 系统** | ❌ | ❌ | ✅ 9 条强制规则 |
| **三层记忆 (wiki/agents/messages)** | ❌ | ✅ 持久化 | ✅ 持久化 |
| **Lane 状态机** | ❌ | ✅ 含非法迁移检测 | ✅ validate.sh 自动校验（idle/in-progress/needs-review/ready-for-merge/resolved） |
| **Git Trailers** | ❌ | ✅ 3 种强制 trailer | ✅ validate.sh commit 检查 |
| **多Agent 消息协议** | ❌ | ✅ inbox.jsonl | ✅ inbox.jsonl |
| **跨Agent 评审闭环** | ❌ | ✅ review闭环 | ✅ review闭环 |
| **Wiki 知识提取** | ❌ | ✅ bugs.md + hot.md | ✅ bugs.md + hot.md |
| **文件锁机制** | ❌ | ❌ | ✅ `.ai-handover/locks/` 并发保护 |
| **分支命名策略** | ❌ | ❌ | ✅ IRON RULE #9 git hook 校验 |
| **hot.md 强制更新** | ❌ | ❌ | ✅ IRON RULE #7 validate.sh 检查 |
| **调用方拒绝协议** | ❌ | ❌ | ✅ 正式定义 |
| **validate.sh 合规脚本** | ❌ | ❌ | ✅ git hook + 状态机校验 |
| 评估场景数 | 3 | 8 | **17** |
| Darwin 评分 | 79.4 | 79.4+ | **82.7 (planned)** |

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
| **4.1** | 2026-06-26 | **IRON RULE 系统升级**：9 条不可协商的 P0 铁律（#1 强制写交接 / #2 模板格式 / #3 git trailers / #4 交接链 / #5 状态门控 / #6 文件锁 / #7 hot.md 更新 / #8 入职流程 / #9 分支策略）；validate.sh 合规校验脚本（trailer 检查 + 状态机校验 + 分支名检查）；`.ai-handover/locks/` 文件锁机制支持并行 Agent 安全写入；`prev_handover_id` 字段实现交接链完整追溯；正式定义调用方拒绝协议；跨任务交接链与串行验证门控；并行 Agent 协调（依赖图）；Git 事件 ↔ Lane 状态映射；新 Agent 入职流程（IRON RULE #8）；新增 12 条反模式；评估场景从 8 扩展至 17；Darwin 评分 79.4 → 82.7 (planned) |
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
  <strong>AI 交接记录 · v4.1</strong> · IRON RULE 9 条强制合规 · Darwin 评分 82.7 (planned) · MIT License
  <br>
  <sub>Made for AI agents, by AI agents.</sub>
</div>
