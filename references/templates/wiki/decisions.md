---
last_updated: 2026-06-26T14:30:00-07:00
updated_by: coder@build
---

# 架构决策记录

> 采用 **Lore 风格** 撰写——每条 ADR 记录完整的决策上下文、约束条件和否决选项。
> **每一条 ADR 一旦定稿即不可修改**。如需变更，新建 ADR 并在 `superseded_by` 中引用新记录。

## ADR-001: JWT + Refresh Token 认证方案

- **日期**: 2026-06-26
- **Decision**: 采用 JWT（15min 过期）+ Refresh Token（7天过期）双 token 方案
- **superseded_by**: _（本记录仍在生效）_
- **supersedes**: ADR-000（Session-only 方案）

### Constraints
- 必须向后兼容 v1.x token 格式，不得强制用户重新登录
- 不能引入新的第三方依赖（已有 jsonwebtoken + cookie-parser）
- Refresh Token 必须支持撤销（处理泄露场景）

### Rejected-Alternatives

| 方案 | 否决原因 |
|------|----------|
| Session-only 认证 | 无法支持移动端和第三方 API 调用 |
| OAuth 2.0 集成 | 超出本期范围，复杂度过高 |
| 单 JWT 长期有效（如 7 天） | Token 泄露后无法撤销，安全违规 |
| 双 JWT（access + refresh 均为 JWT） | Refresh Token 需要无状态校验，增加复杂度 |

### Verification
- `npm test -- --grep auth` — 全部通过（47 tests）
- `npm run security:audit` — 无新增漏洞
- 手动测试 Token 刷新流程 — 5 种边界场景通过

### Agent-Directives
- **禁止**修改 `src/auth/token.ts:generate()` 的函数签名
- Refresh Token 必须使用 secure + httpOnly cookie（禁止 localStorage）
- JWT payload 中禁止包含敏感信息（如密码、手机号）
- 撤销 Token 时必须在 Redis 中标记，不可仅依赖 TTL

### Confidence
- **high** — 方案经过团队评审 + 安全团队确认

### Handover-Ids
- `2026-06-26_143052_user-auth`
- `2026-06-26_091500_auth-redesign`

---

## ADR-002: Redis Token 存储方案

- **日期**: 2026-06-27
- **Decision**: 使用 Redis 6.2+ 存储 Refresh Token，key 格式 `refresh_token:{userId}:{tokenHash}`
- **superseded_by**: _（本记录仍在生效）_
- **supersedes**: _（无）_

### Constraints
- 最大 TTL 7 天（与 Refresh Token 过期时间一致）
- Redis Cluster 模式下必须确保 key 分布均匀

### Rejected-Alternatives

| 方案 | 否决原因 |
|------|----------|
| PostgreSQL 存储 | 读延迟高，需频繁清理过期 token，增加 DB 压力 |
| 本地内存存储 | 多实例部署时无法共享，水平扩展受限 |
| 无存储（仅校验签名） | Token 泄露后完全无法撤销 |

### Verification
- 集成测试覆盖 Token 创建/刷新/撤销全流程
- 并发测试：100 次并发刷新请求，未出现竞态条件

### Agent-Directives
- 禁止直接暴露 Redis 连接给业务层，必须通过 `TokenRepository` 封装
- Token 撤销操作必须记录审计日志

### Confidence
- **medium** — 生产环境高并发场景下的 Redis Cluster 行为需持续观察

### Handover-Ids
- `2026-06-27_103000_token-storage`
