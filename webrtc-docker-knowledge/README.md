# WebRTC API 文档索引

这是 WebRTC `src/api/` 目录下所有 C++ 实现文件 (.cc) 的中文技术文档。文档按照源码目录结构组织，便于对照阅读。

## 目录结构

```
webrtc-docker-knowledge/
├── README.md                    # 本文件 — 总索引与学习路径
└── api/
    ├── README.md                # WebRTC Core API 层 — PeerConnection/RTP/ICE/媒体流/传输/错误处理
    ├── other-modules.md         # 其他小型模块 — crypto/environment/neteq/numerics/test 等
    ├── audio/
    │   └── README.md            # 音频模块 — AudioFrame/APM/回声消除/声道布局/音频设备
    ├── audio_codecs/
    │   └── README.md            # 音频编解码器 — Opus/G.711/G.722/L16/工厂模式
    ├── video/
    │   └── README.md            # 视频模块 — VideoFrame/颜色空间/YUV格式/码率控制
    ├── video_codecs/
    │   └── README.md            # 视频编解码器 — VP8/VP9/H264/H265/AV1/SVC/Simulcast
    ├── transport/
    │   └── README.md            # 传输层 — STUN/TURN/ICE/GoogCC/RTP依赖描述
    ├── task_queue/
    │   └── README.md            # 任务队列 — 异步调度/任务安全/线程模型
    └── units/
        └── README.md            # 单位类型 — Timestamp/TimeDelta/DataRate/DataSize/Frequency
```

## 各模块概述

| 模块 | 文档 | .cc文件数 | 核心内容 |
|------|------|-----------|----------|
| **Core API** | [api/README.md](api/README.md) | 31 | PeerConnection, RTP参数, JSEP, ICE, 传输接口, 帧转换器 |
| **Audio** | [api/audio/README.md](api/audio/README.md) | 10 | AudioFrame, AudioProcessing, AEC3, ChannelLayout, ADM |
| **Audio Codecs** | [api/audio_codecs/README.md](api/audio_codecs/README.md) | 19 | Opus, G.711, G.722, L16, 编解码器工厂 |
| **Video** | [api/video/README.md](api/video/README.md) | 27 | VideoFrame, YUV缓冲区, ColorSpace, 码率分配, 帧组装 |
| **Video Codecs** | [api/video_codecs/README.md](api/video_codecs/README.md) | 25 | VP8/VP9/H264/H265/AV1, SVC, Simulcast, 硬件回退 |
| **Transport** | [api/transport/README.md](api/transport/README.md) | 8 | STUN, GoogCC, 网络类型, RTP依赖描述 |
| **Task Queue** | [api/task_queue/README.md](api/task_queue/README.md) | 4 | 异步调度, 任务安全, 线程模型 |
| **Units** | [api/units/README.md](api/units/README.md) | 5 | Timestamp, TimeDelta, DataRate, DataSize, Frequency |
| **Other Modules** | [api/other-modules.md](api/other-modules.md) | ~50 | Crypto, Environment, NetEQ, Numerics, EventLog, Test |

---

## 学习路径推荐

### 1. 快速概览 (入门者)

如果你刚接触 WebRTC，建议按以下顺序阅读：

1. **[Core API 概述](api/README.md)** — 理解 WebRTC 的整体架构和核心概念
   - 重点：PeerConnection 创建流程、RTP参数体系、JSEP 状态机
2. **[Units 单位类型](api/units/README.md)** — 理解 WebRTC 的强类型安全设计
3. **[Task Queue 任务队列](api/task_queue/README.md)** — 理解线程模型和异步安全
4. **[Transport 传输层](api/transport/README.md)** — 理解 ICE/STUN 和拥塞控制

### 2. 音频方向

1. **[Audio 音频模块](api/audio/README.md)** — AudioFrame → APM → AEC3 流水线
2. **[Audio Codecs 音频编解码器](api/audio_codecs/README.md)** — Opus 编解码接口
3. 扩展阅读：NetEQ (in [other-modules.md](api/other-modules.md)) — 抖动缓冲

### 3. 视频方向

1. **[Video 视频模块](api/video/README.md)** — VideoFrame → 颜色空间 → YUV格式
2. **[Video Codecs 视频编解码器](api/video_codecs/README.md)** — VP8/VP9/H264/AV1 → SVC/Simulcast
3. 关注：硬件编码器回退、Simulcast 码率分配

### 4. 全面深入

按模块顺序全读，建立完整的 WebRTC API 知识体系。建议配合源码对照学习。

---

## 关键概念速查

| 概念 | 所在模块 | 核心文件 |
|------|----------|----------|
| PeerConnection 创建 | Core API | `create_peerconnection_factory.cc` |
| SDP 协商 | Core API | `jsep.cc` |
| RTP 包结构 | Core API | `rtp_parameters.cc`, `rtp_headers.cc` |
| ICE 候选 | Core API | `candidate.cc`, `jsep_ice_candidate.cc` |
| 音频处理流水线 | Audio | `audio_processing.cc` |
| 回声消除 | Audio | `echo_canceller3_config.cc` |
| 视频帧表示 | Video | `video_frame.cc`, `i420_buffer.cc` |
| 颜色空间 | Video | `color_space.cc` |
| 编码器接口 | Video Codecs | `video_encoder.cc`, `video_codec.cc` |
| STUN 协议 | Transport | `stun.cc` |
| 拥塞控制 | Transport | `goog_cc_factory.cc` |
| Opus 编码器 | Audio Codecs | `opus/audio_encoder_opus.cc` |
| NetEQ | Other | `neteq/neteq.cc` |
| H.264 Profile | Video Codecs | `h264_profile_level_id.cc` |
| 任务安全 | Task Queue | `pending_task_safety_flag.cc` |
| 强类型单位 | Units | `timestamp.cc`, `time_delta.cc` |

---

## 设计模式速览

WebRTC API 层广泛使用以下设计模式：

| 模式 | 典型使用 |
|------|----------|
| **Factory / Abstract Factory** | `CreatePeerConnectionFactory`, `VideoEncoderFactory` |
| **Builder** | `VideoFrame::Builder`, `PeerConnectionFactoryDependencies` |
| **Dependency Injection** | `Environment`, `*Dependencies` 结构体 |
| **NVI (Non-Virtual Interface)** | `AudioEncoder::Encode()`, `VideoEncoder::Encode()` |
| **Strategy** | `VideoEncoder`/`VideoDecoder`/`AudioEncoder` 实现 |
| **Observer** | `PeerConnectionObserver`, 编码完成回调 |
| **RAII** | `ScopedTaskSafety`, `CurrentTaskQueueSetter` |
| **Decorator** | `*SoftwareFallbackWrapper` |
| **Value Object** | `ColorSpace`, `RtpParameters`, `Candidate` |
| **Strong Typedef** | `Timestamp`, `TimeDelta`, `DataRate` |
| **Token** | `PendingTaskSafetyFlag` |
| **Template Method** | 编解码器工厂模板 |

---

## 补充说明

- 文档中代码路径均为 `src/api/` 的相对路径，完整路径前缀为 `webrtc-source/src/api/`
- 所有文档使用简体中文编写，技术术语保留英文原名
- 每个模块文档包含「学习扩展」部分，提供概念解释和数据流图
- 文档基于 WebRTC 源码生成，反映当前工作目录下的代码状态
