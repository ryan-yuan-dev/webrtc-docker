# WebRTC 视频编解码器 API 文档

## 概述

`api/video_codecs/` 定义了 WebRTC 视频编解码器的公共接口、配置文件格式和工厂模式。WebRTC 支持 VP8、VP9、H.264、H.265、AV1 等多种视频编解码器。

---

## 一、核心编解码器接口

### video_encoder.cc
**路径**: `api/video_codecs/video_encoder.cc`
**关键接口**: `VideoEncoder`, `VideoEncoderFactory`

视频编码器的抽象接口。所有编码器实现（VP8/VP9/H264/H265/AV1）都实现此接口。

**核心方法**:

| 方法 | 说明 |
|------|------|
| `InitEncode(config, settings)` | 初始化编码器，传入 `VideoCodec` 配置 |
| `Encode(frame, frame_types)` | 编码一帧视频 |
| `RegisterEncodeCompleteCallback(cb)` | 注册编码完成回调 |
| `Release()` | 释放编码器资源 |
| `SetRates(parameters)` | 动态更新码率参数 |
| `GetEncoderInfo()` | 获取编码器能力信息 |
| `SetFecControllerOverride()` | 设置 FEC 控制器覆盖 |

**EncoderInfo 结构**:
- `scaling_settings` — 缩放能力（是否支持降分辨率输入）
- `requested_resolution_alignment` — 请求的分辨率对齐
- `supports_native_handle` — 是否支持原生帧句柄（如 GPU 纹理）
- `implementation_name` — 实现名称
- `has_trusted_rate_controller` — 是否有可信的内部码率控制

**编码流水线中的限定词 (Qualifier)**: 编码前的 NVI 模板方法 `Encode()` 先验证帧格式，再调用虚函数 `EncodeImpl()`。

### video_decoder.cc
**路径**: `api/video_codecs/video_decoder.cc`
**关键接口**: `VideoDecoder`, `VideoDecoderFactory`

视频解码器抽象接口。

**核心方法**:
- `Configure(config)` — 配置解码器
- `Decode(frame, render_time_ms)` — 解码一帧
- `RegisterDecodeCompleteCallback(cb)` — 注册解码完成回调
- `Release()` — 释放解码器

### video_codec.cc
**路径**: `api/video_codecs/video_codec.cc`
**关键类**: `VideoCodec`, `VideoCodecVP8`, `VideoCodecVP9`, `VideoCodecH264`

`VideoCodec` 是编码器配置的数据结构——它是外部 API 和编码器实现之间的配置桥梁。

**与 RtpCodec / SdpVideoFormat 的关系**:
```
SdpVideoFormat (SDP 层) ←→ VideoCodec (编码器配置层)
     name: "VP8"               codecType: kVideoCodecVP8
     parameters: {fmtp}        codec_specific_.VP8: {...}
     scalability_modes         mode: kRealtimeVideo
```

**编解码器特有配置**:
- **VP8**: `numberOfTemporalLayers`, `denoisingOn`, `automaticResizeOn`, `keyFrameInterval`
- **VP9**: 上述 + `numberOfSpatialLayers`, `flexibleMode`, `adaptiveQpMode`
- **H264**: `keyFrameInterval`, `numberOfTemporalLayers`

**`CodecTypeToPayloadString()`** — 编解码器类型 → SDP 负载名称（如 `kVideoCodecVP8 → "VP8"`）
**`PayloadStringToCodecType()`** — 反向映射，大小写不敏感

**模式**: `VideoCodecMode::kRealtimeVideo` (实时视频) 或 `kScreensharing` (屏幕共享)

**复杂度控制**: `GetVideoEncoderComplexity()` / `SetVideoEncoderComplexity()` — 编解码器复杂度 (Low/Medium/High)。低复杂度牺牲质量换取速度（实时场景），高复杂度用于离线。

**`IsMixedCodec()`** — 判断 simulcast 各层是否使用混合编解码器（如 VP8+VP9 混合 simulcast）。

### scalability_mode.cc / scalability_mode_helper.cc
**路径**: `api/video_codecs/scalability_mode.cc`, `scalability_mode_helper.cc`
**关键函数**: `ScalabilityModeToString()`, `ScalabilityModeFromString()`

可伸缩性模式 (Scalability Mode) 定义 SVC/Simulcast 配置字符串：

| 模式 | 含义 |
|------|------|
| `L1T1` | 1 空间层 × 1 时间层 (无 SVC) |
| `L1T2` | 1 空间层 × 2 时间层 (时域分层) |
| `L1T3` | 1 空间层 × 3 时间层 |
| `L2T1` | 2 空间层 × 1 时间层 (空域分层) |
| `L2T2_KEY` | 2 空间层 × 2 时间层 (Key 模式) |
| `L2T3` | 2 空间层 × 3 时间层 (完整 SVC) |
| `L3T3` | 3 空间层 × 3 时间层 |

`ScalabilityModeHelper` 提供辅助函数：判断模式是否支持交错、获取层级数等。

---

## 二、编解码器配置文件

### h264_profile_level_id.cc
**路径**: `api/video_codecs/h264_profile_level_id.cc`
**关键类**: `H264ProfileLevelId`, `H264Level`

H.264 标准定义的 Profile (Baseline/Main/High/Constrained Baseline) 和 Level (1.1 ~ 5.2) 配置。

**Profile-Level-ID** 是 SDP 中 `fmtp:profile-level-id=42e01f` 的解析器:
- `profile_idc` + `profile_iop` + `level_idc` 三部分
- 例如 `42e01f`: profile_idc=0x42 (Baseline), profile_iop=0xe0 (constrained set 0+1+2), level_idc=0x1f (Level 3.1)

### h265_profile_tier_level.cc
**路径**: `api/video_codecs/h265_profile_tier_level.cc`
**关键类**: `H265ProfileTierLevel`

H.265/HEVC 的 Profile-Tier-Level 配置，比 H.264 更复杂。包括 profile_idc、tier_flag、level_idc 和多个 compatibility flags。

### vp8_frame_config.cc / vp8_temporal_layers.cc
**路径**: `api/video_codecs/vp8_frame_config.cc`, `vp8_temporal_layers.cc`

VP8 时域可伸缩性的帧配置。`Vp8FrameConfig` 定义帧的参考关系和缓冲区更新策略。`Vp8TemporalLayers` 控制时域层的帧模式选择。

### vp9_profile.cc
**路径**: `api/video_codecs/vp9_profile.cc`
**关键枚举**: `VP9Profile`

VP9 编码配置文件: Profile 0 (8-bit 4:2:0), Profile 1 (8-bit 4:2:2/4:4:4), Profile 2 (10/12-bit 4:2:0), Profile 3 (10/12-bit 4:2:2/4:4:4)。

### av1_profile.cc
**路径**: `api/video_codecs/av1_profile.cc`
**关键枚举**: `AV1Profile`

AV1 编码配置文件: Main (8/10-bit 4:2:0), High (8/10-bit 4:4:4), Professional (12-bit)。

---

## 三、SDP 视频格式

### sdp_video_format.cc
**路径**: `api/video_codecs/sdp_video_format.cc`
**关键类**: `SdpVideoFormat`

编解码器能力在 SDP 层面的表示。核心是 `name` + `parameters`（key-value map，对应 SDP `a=fmtp:` 属性）。

**关键方法**:
- `IsSameCodec(other)` — 仅按名称判断（不比较参数），用于编解码器匹配
- `IsSameCodecAndParams(other)` — 名称+参数完全比较，用于编解码器协商
- `Matches(that)` — 名称匹配 + 本对象参数是对方参数的子集

**`SdpVideoFormatFactory`** — 根据编解码器类型创建 SDP 格式。内部实现通过 `std::map<string, CodecSupport>` 配置编解码器支持。

### simulcast_stream.cc
**路径**: `api/video_codecs/simulcast_stream.cc`
**关键类**: `SimulcastStream`

Simulcast (同时联播) — 同时发送同一视频的多个分辨率版本：

```
SimulcastStream[0]: 1920×1080 @ 2Mbps
SimulcastStream[1]: 640×360  @ 500kbps
SimulcastStream[2]: 320×180  @ 150kbps
```

每层可单独设置：`width`, `height`, `maxBitrate`, `minBitrate`, `targetBitrate`, `active`, `scalability_mode`, `numberOfTemporalLayers`。

---

## 四、软件回退包装器

### video_encoder_software_fallback_wrapper.cc
**路径**: `api/video_codecs/video_encoder_software_fallback_wrapper.cc`

**硬件编码器回退机制**: 当硬件编码器失败或不支持某些特性时，自动切换到软件编码器。

**回退策略**:
1. 首选硬件编码器 (HW)
2. HW 失败时自动切换到软件 (SW)
3. 可配置是否允许回退到 SW
4. SW 回退时使用相同配置参数

### video_decoder_software_fallback_wrapper.cc
**路径**: `api/video_codecs/video_decoder_software_fallback_wrapper.cc`

解码器软件回退包装器。当硬件解码器对某些编码特性（如特定 Profile 或 resolution）不支持时，fallback 到软件解码器。

---

## 五、Simple Encoder Wrapper

### simple_encoder_wrapper.cc
**路径**: `api/video_codecs/simple_encoder_wrapper.cc`

简化编码器包装器，提供更友好的编码接口。处理帧类型决策、QP 设置等常见操作。

---

## 六、工厂与注册

### builtin_video_encoder_factory.cc / builtin_video_decoder_factory.cc
**路径**: `api/video_codecs/builtin_video_encoder_factory.cc`, `builtin_video_decoder_factory.cc`

创建内置编解码器工厂。自动注册 VP8（始终可用）、VP9、AV1（可通过编译标志启用/禁用）。

### libaom_av1_encoder_factory.cc
**路径**: `api/video_codecs/libaom_av1_encoder_factory.cc`

AV1 编码器工厂。AV1 是最新一代开源视频编解码器，比 VP9 节省约 30% 码率。基于 libaom 库实现。

---

## 学习扩展

### 视频编解码器对比

| 编解码器 | 推出时间 | 压缩效率 | 复杂度 | 主要用途 |
|----------|----------|----------|--------|----------|
| **VP8** | 2008 | 基准 | 低 | WebRTC 默认必须支持 |
| **H.264** | 2003 | 稍优于VP8 | 中 | 硬件编解码广泛支持 |
| **VP9** | 2013 | 优于H.264 ~30% | 中高 | Android/Chrome |
| **H.265** | 2013 | 优于H.264 ~50% | 高 | 4K 流媒体 |
| **AV1** | 2018 | 优于VP9 ~30% | 高 | 未来默认编解码器 |

### Simulcast vs SVC

```
Simulcast (同时联播):
  Layer 0 (高分辨率) ──→ 高质量网络
  Layer 1 (中分辨率) ──→ 中质量网络  
  Layer 2 (低分辨率) ──→ 低质量网络
  (各层独立编码，接收端选择一层)
  
SVC (Scalable Video Coding):
  Base Layer ──→ 所有接收端都收到
  Enhancement Layer 1 ──→ 只有好网络收到
  Enhancement Layer 2 ──→ 只有最佳网络收到
  (增强层依赖基础层，共同提升质量)
```

### 硬件编码器 vs 软件编码器

| 维度 | 硬件编码 | 软件编码 |
|------|----------|----------|
| 速度 | 极快 (专用ASIC) | 较慢 (需优化) |
| 功耗 | 极低 | 较高 |
| 灵活性 | 有限 (固定Profile) | 完全可定制 |
| 质量/码率比 | 通常较差 | 可优化到更好 |
| 启动延迟 | 可能较高 | 较低 |
| 并发能力 | 有限 (1-3 实例) | 可多实例 |

**WebRTC 的策略**: 优先使用硬件编码（省功耗），支持软件回退（兼容性）。

### 编码器码率控制

```
总目标码率
  │
  ▼
VideoBitrateAllocator
  │
  ├─→ Layer 0: base_temporal_bitrate + enhancement_temporal_bitrate
  ├─→ Layer 1: base_temporal_bitrate + enhancement_temporal_bitrate
  └─→ ...
  │
  ▼
VideoEncoder::SetRates()
  │
  ▼
编码器内部码率控制 (QP决策、帧率调整)
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Template Method** | `VideoEncoder::Encode()` | NVI 模式，验证后调用 `EncodeImpl` |
| **Strategy** | `VideoEncoder` 实现 | 不同编解码器可互换 |
| **Abstract Factory** | `VideoEncoderFactory` | 创建编码器/解码器对 |
| **Decorator** | `*SoftwareFallbackWrapper` | 为编码器添加回退行为 |
| **Config Object** | `VideoCodec` | 编解码器配置的 Value Object |
| **Type Safe Enum** | `VideoCodecType`, `ScalabilityMode` | 编译期安全枚举 + 运行时字符串转换 |
| **Adapter** | `SdpVideoFormat` ↔ `VideoCodec` | SDP 格式与编码器配置之间的适配 |
