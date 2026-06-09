# echo_canceller3_config_unittest

## 概述

`echo_canceller3_config_unittest` 是 `EchoCanceller3Config::Validate()` 方法的单元测试文件，验证配置校验逻辑的正确性。

## 测试用例

| 测试名 | 验证内容 |
|--------|----------|
| `ValidConfigIsNotModified` | 默认配置调用 Validate() 后不修改任何参数，返回 true |
| `InvalidConfigIsCorrected` | 将 `echo_model.min_noise_floor_power` 设为负值（-1600000.0），Validate() 返回 false 并将该参数修正回非负值，其他参数不变 |
| `ValidatedConfigsAreValid` | 先设置无效值 `delay.down_sampling_factor = 983`（仅支持 4/8），Validate() 第一次返回 false 并修正，再次调用返回 true |

## 关键验证点

- **幂等性**：修正后的配置再次调用 Validate() 应返回 true（即不会反复修正）。
- **精确回退**：只有越界的参数被修正，其余参数保持不变。
- **边界值**：Validate() 能正确处理各种极端值（负值、超大值）。
