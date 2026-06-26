---
last_updated: 2026-06-26T15:00:00-07:00
updated_by: coder@build
---

# HOT — 当前热缓存

> ⚠️ **新 Agent 入职第一步：先读此文件。** 这是项目的"前台大脑"，展示全部活跃上下文。
> 每次任务结束后必须更新此文件，确保下一 Agent 拿到最新快照。

## 当前阶段

- **项目**: user-auth-feature（用户认证系统升级）
- **阶段**: implementation（完成 ~40%）
- **活跃 Lane**: feature/user-auth → in-progress
- **活跃 Agent**: coder@build（实现中）、reviewer@build（待唤醒）

## 活跃决策

| 决策 | 方案 | 否决项 |
|------|------|--------|
| 认证方案 | JWT（15min）+ Refresh Token（7天） | Session-only（不支持移动端） |
| Token 存储 | Redis（带 TTL） | 本地存储（不安全）、DB（性能差） |
| API 风格 | RESTful | GraphQL（超出本期范围） |
| 密码哈希 | bcrypt（cost=12） | argon2（兼容性问题） |

## 活跃文件

| 文件 | 状态 | 说明 |
|------|------|------|
| `src/auth/login.ts` | 🔴 修改中 | 登录端点重构，预计 2 个 task |
| `src/auth/session.ts` | 🟢 稳定 | ⚠️ 42-48 行有 Agent-Directive |
| `src/auth/token.ts` | 🟢 稳定 | 🔒 禁止修改 `generate()` 签名 |
| `src/middleware/error.ts` | 🟡 待优化 | 统一错误处理待接入 |
| `test/auth/session.test.ts` | 🟡 覆盖率不足 | 缺少集成测试 |

## 已知坑

| # | 坑 | 影响 | 状态 |
|---|----|------|------|
| 1 | 测试环境 Redis mock 启动耗时 >500ms | 测试慢 | 已绕过（见 wiki/bugs.md） |
| 2 | CI 超时阈值 5min（当前测试需 ~7min） | CI 偶发失败 | 等待 Ops 调整 |
| 3 | `src/auth/token.ts:generate()` 依赖全局 config | 测试隔离差 | 计划提取为依赖注入 |

## 下一步

- [ ] reviewer 审查 src/auth/session.ts:42-48
- [ ] 补充 session 集成测试
- [ ] 合并 feat/user-auth → dev
- [ ] 合并后更新 hot.md（删除已完成项，更新阶段状态）
