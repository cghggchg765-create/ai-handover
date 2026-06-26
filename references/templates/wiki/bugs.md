---
last_updated: 2026-06-26T14:00:00-07:00
updated_by: coder@build
---

# 已知 Bug 注册表

> 记录所有已知 Bug，包括严重度、当前状态和临时绕过方案。
> `Handover-ID` 字段关联到首次记录该 Bug 的交接记录。

## 状态枚举

| 状态 | 含义 |
|------|------|
| 活跃 | 尚未修复 |
| 已修复 | 已合入修复，需验证 |
| 观察中 | 偶现，原因未确定 |
| 绕过中 | 有临时绕过方案，正式修复待排期 |

## Bug 清单

| ID | 文件 | 描述 | 严重度 | 状态 | 绕过方案 | Handover-ID |
|----|------|------|--------|------|----------|-------------|
| BUG-001 | `test/setup.ts` | 测试环境 Redis mock 启动耗时 >500ms，导致 `beforeAll` 超时。根因：ioredis mock 库在 CI 冷启动时加载过多 polyfill。 | 🟡 中等 | 绕过中 | 在 jest 全局 setup 中预热 Redis mock：`globalThis.__REDIS_MOCK__ = new MockRedis();`，各测试 suite 复用此实例 | `2026-06-24_002_redis-mock` |
| BUG-002 | `src/auth/session.ts:85` | Session 并发刷新时偶现 `ERR_TOKEN_EXPIRED` 错误。根因：竞态条件——两个请求同时检查 refresh token 有效但只有一个能成功刷新。 | 🔴 严重 | 观察中 | 在刷新端点加 Redis 分布式锁 + 重试机制。锁定时间 <200ms 对用户体验无影响 | `2026-06-26_091500_auth-redesign` |
| BUG-003 | `ci/config.yml` | CI 超时阈值设置为 5min，但完整测试套件运行需要约 7min，导致 CI 偶发失败。 | 🟢 轻微 | 绕过中 | 已通知 Ops 团队调整阈值为 10min，变更生效前在 CI 配置中临时注释掉耗时较长的集成测试 | `2026-06-25_ci-timeout` |

## 使用规则

1. 发现新 Bug → 追加到本表末尾（ID 递增）
2. 修复后 → 将状态改为 `已修复`，并关联修复的 Handover-ID
3. 确认修复有效 → 可移出此表或保留为历史记录
4. 如果绕过方案长期存在 → 考虑创建正式技术债 Item
