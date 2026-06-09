# echo_canceller3_config

## 概述

`echo_canceller3_config` 定义了 WebRTC 第三代回声消除器（Echo Canceller 3, AEC3）的全部可调参数配置结构 `EchoCanceller3Config`。AEC3 是 WebRTC 的标准回声消除算法（非移动模式），该配置文件提供了精细化的参数控制，涵盖延迟估计、自适应滤波、ERLE 估计、回声抑制、舒适噪声生成、多声道检测等子系统。

该配置通过 `BuiltinAudioProcessingBuilder::SetEchoCancellerConfig()` 或 `EchoCanceller3Factory` 注入到 AEC3 实例中。

## 头文件接口 (.h)

### 结构体 EchoCanceller3Config

标记为 `RTC_EXPORT`，包含多个嵌套结构体，各子模块独立配置。

| 方法 | 说明 |
|------|------|
| `Validate(config*)` | 校验和修正配置参数到合理范围，返回 true 表示无需修改 |
| `CreateDefaultMultichannelConfig()` | 创建默认多声道配置（适用于非单声道场景） |

### 子配置结构一览

| 子结构 | 核心字段 | 说明 |
|--------|----------|------|
| `buffering` | `excess_render_detection_interval_blocks`, `max_allowed_excess_render_blocks` | 渲染缓冲管理 |
| `delay` | `default_delay`, `down_sampling_factor`, `num_filters`, `delay_headroom_samples`, `hysteresis_limit_blocks`, `fixed_capture_delay_samples`, `delay_estimate_smoothing`, `delay_candidate_detection_threshold`, `delay_selection_thresholds`, `use_external_delay_estimator`, `render_alignment_mixing`, `capture_alignment_mixing`, `detect_pre_echo` | 延迟估计和校正 |
| `filter` | `refined`/`coarse` / `refined_initial`/`coarse_initial` 滤波器的 `length_blocks`, `leakage_converged`, `leakage_diverged`, `error_floor`, `error_ceil`, `noise_gate`, `config_change_duration_blocks`, `initial_state_seconds`, `conservative_initial_phase`, `use_linear_filter`, `export_linear_aec_output` | 自适应线性滤波（精滤波和粗滤波双滤波器架构） |
| `erle` | `min`, `max_l`, `max_h`, `onset_detection`, `num_sections`, `clamp_quality_estimate` | 回声返回损失增强估计 |
| `ep_strength` | `default_gain`, `default_len`, `nearend_len`, `echo_can_saturate`, `bounded_erl` | 回声路径强度参数 |
| `echo_audibility` | `low_render_limit`, `normal_render_limit`, `floor_power`, `audibility_threshold_lf/mf/hf`, `use_stationarity_properties` | 回声可听度检测 |
| `render_levels` | `active_render_limit`, `poor_excitation_render_limit`, `render_power_gain_db` | 渲染信号电平估计 |
| `echo_removal_control` | `has_clock_drift`, `linear_and_stable_echo_path` | 回声移除控制 |
| `echo_model` | `noise_floor_hold`, `min_noise_floor_power`, `stationary_gate_slope`, `noise_gate_power`, `render_pre/post_window_size`, `model_reverb_in_nonlinear_mode` | 回声建模参数 |
| `comfort_noise` | `noise_floor_dbfs` | 舒适噪声生成 |
| `suppressor` | `nearend_average_blocks`, `normal_tuning`, `nearend_tuning`, `dominant_nearend_detection`, `subband_nearend_detection`, `high_bands_suppression`, `high_frequency_suppression`, `floor_first_increase` | 非线性回声抑制器 |
| `multi_channel` | `detect_stereo_content`, `stereo_detection_threshold`, `stereo_detection_timeout_threshold_seconds`, `stereo_detection_hysteresis_seconds` | 多声道内容检测 |

### 关键子配置详细字段

**Delay 配置**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `default_delay` | 5 | 默认延迟（块数） |
| `down_sampling_factor` | 4 | 延迟估计下采样因子（仅支持 4 或 8） |
| `num_filters` | 5 | 延迟自适应滤波器数量 |
| `delay_headroom_samples` | 32 | 延迟裕量（采样点） |
| `fixed_capture_delay_ms` | 0 | 固定采集延迟（ms） |
| `use_external_delay_estimator` | false | 使用外部延迟估计器 |
| `detect_pre_echo` | true | 检测前回声 |

**Filter 配置**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `refined.length_blocks` | 13 | 精滤波器长度（块数） |
| `refined.leakage_converged` | 0.00005 | 收敛态泄漏因子 |
| `refined.leakage_diverged` | 0.05 | 发散态泄漏因子 |
| `coarse.length_blocks` | 13 | 粗滤波器长度 |
| `coarse.rate` | 0.7 | 粗滤波器自适应速率 |
| `use_linear_filter` | true | 是否使用线性滤波器 |
| `export_linear_aec_output` | false | 导出线性 AEC 输出 |

**Suppressor 配置**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `normal_tuning.mask_lf.enr_transparent` | 0.3 | 低频 ENR 透明阈值 |
| `normal_tuning.mask_lf.enr_suppress` | 0.4 | 低频 ENR 抑制阈值 |
| `nearend_tuning.mask_lf.enr_transparent` | 1.09 | 近端调谐低频透明阈值 |
| `dominant_nearend_detection.enr_threshold` | 0.25 | 主导近端检测 ENR 阈值 |
| `dominant_nearend_detection.hold_duration` | 50 | 主导近端保持帧数 |

## 实现文件 (.cc)

### 参数校验 Validate()

`Validate()` 是整个配置模块的核心实现，功能如下：

1. **范围限制（Limit/FloorLimit）**：使用 `SafeClamp` 将每个参数约束在合理的范围内。
2. **特殊值处理**：
   - `delay.down_sampling_factor` 必须为 4 或 8，否则重置为 4。
   - 使用 `std::isfinite()` 检查浮点数有限性。
   - `erle.min` 不能大于 `erle.max_l` 或 `erle.max_h`。
3. **滤波器长度一致性**：
   - `refined_initial.length_blocks` 不能超过 `refined.length_blocks`。
   - `coarse_initial.length_blocks` 不能超过 `coarse.length_blocks`。
4. **子带索引关系**：`first_hf_band` 必须大于等于 `last_lf_band + 1`。
5. **返回值**：所有参数均在范围内时返回 `true`，被修正过的返回 `false`。

使用与（`&`）操作累积所有校验结果，确保每一行校验都被执行。

### CreateDefaultMultichannelConfig()

```cpp
EchoCanceller3Config EchoCanceller3Config::CreateDefaultMultichannelConfig() {
  EchoCanceller3Config cfg;
  // 使用更短、自适应更快的粗滤波器
  cfg.filter.coarse.length_blocks = 11;  // 默认 13
  cfg.filter.coarse.rate = 0.95f;        // 默认 0.7
  // 更保守的抑制器行为
  cfg.suppressor.normal_tuning.max_dec_factor_lf = 0.35f;  // 默认 0.25
  cfg.suppressor.normal_tuning.max_inc_factor = 1.5f;      // 默认 2.0
  return cfg;
}
```

多声道时，参与自适应的滤波器参数总量增加（每个声道独立滤波），因此需要更短、收敛更快的滤波器，以及更保守的抑制策略。

## 学习扩展

### AEC3 双滤波器架构

AEC3 使用**精滤波器（Refined Filter）+ 粗滤波器（Coarse Filter）**的双滤波器架构：
- **精滤波器**：长自适应滤波器，精确建模回声路径，收敛较慢但稳态效果好。
- **粗滤波器**：短自适应滤波器，快速跟踪回声路径变化，收敛快但精度较低。
- 初始阶段使用 `refined_initial`/`coarse_initial` 参数，一定时间后切换到稳态参数。
- `config_change_duration_blocks` 控制切换过渡期的长度。

### 延迟估计

AEC3 的延迟估计使用多滤波器机制：
1. 将渲染信号与采集信号分别做下采样（4x 或 8x）。
2. 多个滤波器在不同延迟假设下独立自适应。
3. 选择能量收敛最好的滤波器对应的延迟作为估计值。
4. 经过平滑和滞回处理后输出最终延迟。

### 抑制器通调（Tuning）

Suppressor 有两组预置参数：
- **normal_tuning**：一般场景，ENR 透明阈值较低（0.3/0.07），更主动地抑制回声。
- **nearend_tuning**：近端说话时，ENR 透明阈值较高（1.09/0.1），保留更多近端语音。

通过 `DominantNearendDetection` 自动识别近端占主导的场景并切换。

### 参数验证的工程意义

Validate() 确保极端或无效的配置不会导致 AEC3 运行时崩溃或产生噪声。这是 WebRTC 音频模块鲁棒性的重要保障。开发者修改配置后应始终调用 Validate() 确认参数有效。
