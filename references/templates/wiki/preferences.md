---
last_updated: 2026-06-20T09:00:00-07:00
updated_by: coder@build
---

# 用户偏好记录

> ⚠️ **重要原则**：偏好来源于用户**显式声明**，绝不从代码行为推断。
> 每项偏好必须记录首次提出的来源 Handover-ID。

## 技术栈偏好

| 偏好 | 值 | 来源 | Handover-ID |
|------|----|------|-------------|
| 语言 | TypeScript（strict mode） | 用户声明："必须上 TS strict" | `2026-06-10_project-init` |
| Node 版本 | >= 18 LTS | 用户声明 | `2026-06-10_project-init` |
| 包管理器 | pnpm | 用户声明："不要再看到 node_modules 占几个 G" | `2026-06-12_toolchain-setup` |

## 命名约定

| 偏好 | 值 | 来源 | Handover-ID |
|------|----|------|-------------|
| 文件命名 | kebab-case（如 `user-auth.ts`） | 用户声明 | `2026-06-10_project-init` |
| 变量命名 | camelCase | 项目规范 | `2026-06-10_project-init` |
| 类型定义 | 优先 `type` 而非 `interface` | 用户声明："受 TS 官方推荐影响" | `2026-06-15_code-review` |
| 常量命名 | `UPPER_SNAKE_CASE` | 用户声明 | `2026-06-15_code-review` |

## 测试框架

| 偏好 | 值 | 来源 | Handover-ID |
|------|----|------|-------------|
| 框架 | vitest（拒绝 jest） | 用户声明："jest 太慢了，vitest 快 10 倍" | `2026-06-12_toolchain-setup` |
| 断言风格 | expect + toBe/toEqual | 项目规范 | `2026-06-12_toolchain-setup` |
| Mock 策略 | vi.mock 全局 mock（拒绝局部 mock） | 用户声明 | `2026-06-15_code-review` |
| 覆盖率门槛 | branches >= 80%, lines >= 90% | 用户声明 | `2026-06-12_toolchain-setup` |

## 代码风格

| 偏好 | 值 | 来源 | Handover-ID |
|------|----|------|-------------|
| 分号 | 必须（eslint: semi:error） | 用户声明 | `2026-06-10_project-init` |
| 引号 | 单引号（prettier singleQuote） | 用户声明 | `2026-06-10_project-init` |
| 缩进 | 2 空格 | 项目规范 | `2026-06-10_project-init` |
| 尾逗号 | always | 用户声明 | `2026-06-15_code-review` |

## 工具链

| 偏好 | 值 | 来源 | Handover-ID |
|------|----|------|-------------|
| 格式化工具 | prettier（CI 中检查） | 用户声明 | `2026-06-10_project-init` |
| Linter | eslint + typescript-eslint | 项目规范 | `2026-06-10_project-init` |
| Commit 规范 | conventional commits（`feat:` / `fix:` / `chore:`） | 用户声明："不要给我乱七八糟的 commit message" | `2026-06-12_toolchain-setup` |
| Git 分支命名 | `feat/` `fix/` `chore/` 前缀 | 用户声明 | `2026-06-12_toolchain-setup` |
