# videocodec_test_stats

## 概述

`videocodec_test_stats` 定义了视频编解码器测试的统计数据结构。包含每帧的统计（`FrameStatistics`）和视频流的聚合统计（`VideoStatistics`），用于衡量编码器/解码器的性能和质量。

## 头文件接口 (.h)

### `VideoCodecTestStats` 抽象类

**`FrameStatistics` 结构体** — 单帧统计信息：

| 类别 | 字段 | 说明 |
|------|------|------|
| 基础 | `frame_number`, `rtp_timestamp`, `spatial_idx` | 帧号、时间戳、空间层索引 |
| 编码 | `encode_start_ns`, `encode_return_code`, `encoding_successful`, `encode_time_us`, `target_bitrate_kbps`, `target_framerate_fps`, `length_bytes`, `frame_type` | 编码过程指标 |
| 分层 | `spatial_idx`, `temporal_idx`, `inter_layer_predicted`, `non_ref_for_inter_layer_pred` | SVC/Simulcast 分层信息 |
| H264 | `max_nalu_size_bytes` | H264 最大 NALU 大小 |
| 解码 | `decode_start_ns`, `decode_return_code`, `decoding_successful`, `decode_time_us`, `decoded_width`, `decoded_height` | 解码过程指标 |
| 量化 | `qp` | 量化参数 |
| 质量 | `psnr_y/u/v`, `psnr`, `ssim` | PSNR 和 SSIM 客观质量指标 |

**`VideoStatistics` 结构体** — 视频流聚合统计：
- 目标/实际码率、帧率、分辨率
- 编码/解码速度
- 平均/最大编码/解码延迟
- 首帧延迟
- 关键帧/Delta 帧大小
- PSNR/SSIM 质量统计
- 帧计数、空间分辨率变化次数

核心方法：

| 方法 | 说明 |
|------|------|
| `GetFrameStatistics()` | 获取所有帧统计 |
| `SliceAndCalcLayerVideoStatistic(first, last)` | 按帧序号范围切片并计算分层统计 |
| `CalcVideoStatistic(first, last, target_bitrate, target_framerate)` | 计算指定范围的视频统计 |

## 实现文件 (.cc)

- `FrameStatistics::ToMap()` / `ToString()` — 将帧统计转换为键值对映射或字符串。
- `VideoStatistics::ToMap()` / `ToString()` — 将视频统计转换为映射或字符串，支持前缀格式化。

## 学习扩展

- **PSNR (Peak Signal-to-Noise Ratio)**: 峰值信噪比，衡量视频质量的客观指标。
- **SSIM (Structural Similarity)**: 结构相似性指数，更符合人类视觉感知的质量指标。
- **SVC (Scalable Video Coding)**: 可伸缩视频编码，支持空间/时间/质量层级。
- **Q14 中的比率**: 部分指标可能使用定点 Q 格式表示。

## 设计模式

- **数据传输对象（DTO）** — `FrameStatistics` 和 `VideoStatistics` 是纯数据容器。
- **访问器模式** — `GetFrameStatistics()` 和 `CalcVideoStatistic()` 提供不同粒度的数据访问。
