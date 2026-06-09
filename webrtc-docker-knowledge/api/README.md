# WebRTC Core API 层文档

## 概述

`api/` 目录是 WebRTC 的**公共 API 层**，定义了外部应用与 WebRTC 内部实现之间的接口契约。它是 WebRTC 架构中最稳定的部分——API 变更需要经过严格的兼容性审查。

**设计原则**:
- **接口与实现分离**: `.h` 定义纯虚接口 (interface)，`.cc` 只包含默认实现、工厂函数和跨平台无关的数据结构
- **依赖注入 (Dependency Injection)**: 通过 `*Dependencies` 结构体注入所有外部依赖，而非在构造函数中自行创建
- **分层架构**: api/ → pc/ (PeerConnection 实现) → call/ (媒体会话) → modules/ (具体算法)

---

## 一、PeerConnection 相关

### peer_connection_interface.cc
**路径**: `api/peer_connection_interface.cc`
**关键类**: `PeerConnectionInterface`, `RTCConfiguration`, `PeerConnectionDependencies`, `PeerConnectionFactoryDependencies`

这是 WebRTC 最核心的接口文件。`PeerConnectionInterface` 是对等连接的抽象，对应 WebRTC 标准中的 `RTCPeerConnection`。

**`RTCConfiguration`** — 连接配置结构体:
```cpp
struct RTCConfiguration {
  RTCConfigurationType type;  // kAggressive 可启用激进连接策略
  // ICE 相关:
  IceTransportsType type;     // kNone/kRelay/kNoHost/kAll
  BundlePolicy bundle_policy;
  RtcpMuxPolicy rtcp_mux_policy;
  TcpCandidatePolicy tcp_candidate_policy;
  // 媒体相关:
  bool disable_ipv6;
  bool enable_ice_renomination;    // ICE 重新提名
  bool redetermine_role_on_ice_restart;
  // ...
};
```

**`kAggressive` 预设配置**: 当 type 为 `kAggressive` 时，自动设置:
- `bundle_policy = kBundlePolicyMaxBundle` — 所有媒体流复用一个传输通道
- `rtcp_mux_policy = kRtcpMuxPolicyRequire` — 强制 RTCP 复用
- `enable_ice_renomination = true` — 允许 ICE 重新提名（切换更优路径）
- `ice_connection_receiving_timeout` 设为更短的激进超时 (aggressive timeout)

**依赖注入结构**:
- `PeerConnectionDependencies`: 包含 `PeerConnectionObserver*` — 连接事件回调
- `PeerConnectionFactoryDependencies`: 包含所有线程、编解码器工厂、ADM、APM 等

### create_peerconnection_factory.cc
**路径**: `api/create_peerconnection_factory.cc`
**关键函数**: `CreatePeerConnectionFactory()`

创建 `PeerConnectionFactoryInterface` 的顶层工厂函数。它是**推荐的外部入口**——封装了所有依赖的组装过程。

**组装流程**:
```
1. 创建 PeerConnectionFactoryDependencies
2. 创建 Environment (包含 FieldTrials)
3. 设置 Socket Factory (从 network_thread 获取)
4. 设置音频处理 Builder (Custom 或 Builtin)
5. 调用 EnableMedia(dependencies) — 初始化媒体引擎
6. 调用 CreateModularPeerConnectionFactory(dependencies)
```

**线程模型**: 三个线程由外部传入:
- `network_thread` — 网络 I/O (DTLS, ICE)
- `worker_thread` — 媒体处理 (编码/解码)
- `signaling_thread` — 信令处理 (SDP 协商)

### create_modular_peer_connection_factory.cc
**路径**: `api/create_modular_peer_connection_factory.cc`

模块化工厂的入口。与 `CreatePeerConnectionFactory` 的区别：允许更精细的控制，例如替换媒体引擎。常用于 Chromium 等嵌入场景——Chromium 注入自己的音频/视频捕获管线。

### enable_media.cc / enable_media_with_defaults.cc
**路径**: `api/enable_media.cc`, `api/enable_media_with_defaults.cc`
**关键函数**: `EnableMedia()`, `EnableMediaWithDefaults()`

初始化媒体引擎的核心函数。`EnableMediaWithDefaults` 可自动检测平台支持的音频/视频编解码器作为默认值。

---

## 二、RTP 相关

### rtp_parameters.cc
**路径**: `api/rtp_parameters.cc`
**关键类**: `RtpParameters`, `RtpCodecParameters`, `RtpEncodingParameters`, `RtpExtension`, `RtpHeaderExtensionCapability`, `RtpCodecCapability`, `RtcpParameters`, `RtcpFeedback`

RTP 参数体系是 WebRTC 中描述媒体编解码和传输配置的核心数据结构。

**类体系**:
```
RtpParameters
├── transaction_id           # 事务 ID (用于 setParameters/getParameters)
├── mid                      # Media Stream Identification
├── codecs[]                 # 编解码器列表 (RtpCodecParameters)
│   ├── payload_type         # 负载类型 (0-127)
│   ├── name                 # 编解码器名称 (如 "VP8", "H264", "opus")
│   ├── kind                 # 媒体类型 (kAudio/kVideo)
│   ├── clock_rate           # 时钟频率 (如 90000 for video)
│   └── parameters           # codec-specific 参数 (SDP fmtp 映射)
├── encodings[]              # 编码参数 (RtpEncodingParameters)
│   ├── ssrc                 # 同步源标识符
│   ├── rid                  # RTP Stream ID (用于 simulcast)
│   ├── active               # 是否激活
│   ├── max_bitrate_bps      # 最大比特率
│   ├── scalability_mode     # 可伸缩性模式 (如 "L1T3")
│   └── scale_resolution_down_by  # simulcast 降分辨率因子
├── header_extensions[]      # RTP 头扩展 (RtpExtension)
│   ├── uri                  # 扩展 URI
│   ├── id                   # 扩展 ID (1-14, one-byte header)
│   └── encrypt              # 是否加密
└── rtcp                     # RTCP 参数
    ├── cname                # 规范名
    └── reduced_size         # 是否使用精简 RTCP
```

**RtpExtension — RTP 头扩展管理**:
- `IsSupportedForAudio(uri)` — 判断扩展是否适用于音频。音频支持的扩展：`kAudioLevelUri`, `kAbsSendTimeUri`, `kAbsoluteCaptureTimeUri`, `kTransportSequenceNumber*`, `kMidUri`, `kRidUri`
- `IsSupportedForVideo(uri)` — 视频支持的扩展比音频多：`kVideoRotationUri`, `kPlayoutDelayUri`, `kVideoContentTypeUri`, `kVideoTimingUri`, `kGenericFrameDescriptorUri00`, `kDependencyDescriptorUri`, `kColorSpaceUri`, `kVideoLayersAllocationUri`, `kVideoFrameTrackingIdUri`, `kCorruptionDetectionUri`
- `IsEncryptionSupported(uri)` — 除 `kAbsSendTimeUri` (当 ENABLE_EXTERNAL_AUTH 时) 和 `kEncryptHeaderExtensionsUri` 外均可加密
- `FindHeaderExtensionByUri(extensions, uri, filter)` — 按 URI 和过滤策略查找扩展。三种过滤策略：
  - `kDiscardEncryptedExtension` — 只要未加密的
  - `kPreferEncryptedExtension` — 优先加密的，可回退到未加密
  - `kRequireEncryptedExtension` — 只要加密的
- `FindHeaderExtensionByUriAndEncryption(extensions, uri, encrypt)` — 精确匹配 URI + 加密状态
- `DeduplicateHeaderExtensions(extensions, filter)` — 头扩展去重并按 (URI, encrypt, id) 排序，确保比较的确定性

**RtpCodec**:
- `IsResiliencyCodec()` — 是否为弹性编解码器 (RTX, RED, ULPFEC, FlexFEC)
- `IsMediaCodec()` — 是否为媒体编解码器 (排除弹性编解码器和 CN)

**RtpEncodingParameters** — simulcast 和 SVC 的核心:
- `scale_resolution_down_by` — simulcast 降分辨率因子
- `scalability_mode` — 可伸缩性模式字符串 (如 "L1T3" = 1 空间层 + 3 时间层)
- `max_framerate` — 最大帧率
- `adaptive_ptime` — 自适应打包时长

### rtp_headers.cc
**路径**: `api/rtp_headers.cc`
**关键类**: `RTPHeaderExtension`, `RTPHeader`

处理 RTP 包头结构和扩展头解析。

### rtp_packet_info.cc
**路径**: `api/rtp_packet_info.cc`
**关键类**: `RtpPacketInfo`, `RtpPacketInfos`

封装单个/多个 RTP 包的元信息（SSRC、CSRC、RTP 时间戳、接收时间等），用于在接收管线中传递。

### rtp_receiver_interface.cc / rtp_sender_interface.cc / rtp_transceiver_interface.cc
**路径**: 三个接口文件
**关键接口**: `RtpReceiverInterface`, `RtpSenderInterface`, `RtpTransceiverInterface`

RTP 收发器的抽象接口，对应 WebRTC 1.0 标准中的 `RTCRtpReceiver`, `RTCRtpSender`, `RTCRtpTransceiver`。

- **Sender** — 控制编码参数 (setParameters)、track 替换 (setTrack)
- **Receiver** — 观察接收到的 track、获取接收统计
- **Transceiver** — 同时管理 sender 和 receiver，表示一个双向媒体流

---

## 三、JSEP (JavaScript Session Establishment Protocol)

### jsep.cc
**路径**: `api/jsep.cc`
**关键类**: `SessionDescriptionInterface`
**关键函数**: `SdpTypeToString()`, `SdpTypeFromString()`

JSEP 定义了 WebRTC 中 SDP 协商的状态机。

**SDP 类型**:
| SdpType | 字符串 | 含义 |
|---------|--------|------|
| `kOffer` | "offer" | 发起方创建 |
| `kPrAnswer` | "pranswer" | 临时应答 (early media) |
| `kAnswer` | "answer" | 最终应答 |
| `kRollback` | "rollback" | 回滚到稳定状态 |

**状态转换**:
```
stable ──createOffer──→ have-local-offer
stable ──createAnswer─→ have-remote-offer (收到 remote offer 后)
have-local-offer ──setLocal──→ have-local-offer
have-local-offer ──setRemote(answer)──→ stable
have-remote-offer ──setLocal(answer)──→ stable
任一状态 ──setLocal(rollback)──→ stable
```

### jsep_ice_candidate.cc
**路径**: `api/jsep_ice_candidate.cc`
**关键类**: `JsepIceCandidate`

ICE 候选者与 SDP 的绑定。封装 `Candidate` 和 `sdp_mid`、`sdp_mline_index`。

---

## 四、媒体流与轨道

### media_stream_interface.cc / media_types.cc
**路径**: `api/media_stream_interface.cc`, `api/media_types.cc`
**关键接口**: `MediaStreamInterface`, `AudioTrackInterface`, `VideoTrackInterface`

`MediaStreamInterface` 对应 WebRTC 标准中的 `MediaStream`，是一个音频轨道和视频轨道的容器。

```
MediaStream
├── AudioTrack[]    # 来自麦克风的音频
└── VideoTrack[]    # 来自摄像头的视频
```

`MediaTypes` — 简单的枚举：`MEDIA_TYPE_AUDIO`, `MEDIA_TYPE_VIDEO`, `MEDIA_TYPE_DATA`, `MEDIA_TYPE_UNSUPPORTED`。

### audio_options.cc
**路径**: `api/audio_options.cc`
**关键类**: `AudioOptions`

音频轨道的配置选项：回声消除、降噪、自动增益控制、高通滤波、立体声开关等。

---

## 五、传输层

### candidate.cc
**路径**: `api/candidate.cc`
**关键类**: `Candidate`

ICE (Interactive Connectivity Establishment) 候选者。包含：
- `component` — RTP(1) 或 RTCP(2)
- `protocol` — UDP/TCP/TLS
- `address` — IP 地址和端口
- `priority` — 优先级 (RFC 5245 公式: `(2^24 × type-pref) + (2^8 × local-pref) + (2^0 × 256 - comp)`)
- `type` — LOCAL/STUN/SRFLX/PRFLX/RELAY
- `network_name` — 所属网络接口

### dtls_transport_interface.cc
**路径**: `api/dtls_transport_interface.cc`
**关键接口**: `DtlsTransportInterface`

DTLS (Datagram TLS) 传输层抽象。封装 DTLS 握手状态和新/已连接/已关闭/失败的状态转换。

### sctp_transport_interface.cc
**路径**: `api/sctp_transport_interface.cc`
**关键接口**: `SctpTransportInterface`

SCTP (Stream Control Transmission Protocol) 传输，用于 DataChannel。提供 SCTP 状态信息和本地/远端端口。

### ice_transport_factory.cc
**路径**: `api/ice_transport_factory.cc`

创建 ICE 传输的工厂函数。支持创建 P2P (Peer-to-Peer) ICE 传输，可配置端口分配器 (PortAllocator)。

### data_channel_interface.cc
**路径**: `api/data_channel_interface.cc`
**关键接口**: `DataChannelInterface`

数据通道接口。提供 `Send()`, `Close()`, `RegisterObserver()` 等方法。支持可靠/不可靠传输、有序/无序发送。

**DataChannel 状态**: `kConnecting → kOpen → kClosing → kClosed`

### datagram_connection_factory.cc
**路径**: `api/datagram_connection_factory.cc`

数据报传输工厂的抽象。为 DTLS/SCTP 提供底层的包发送/接收能力。

---

## 六、帧转换器

### frame_transformer_interface.cc / frame_transformer_factory.cc
**路径**: `api/frame_transformer_interface.cc`, `api/frame_transformer_factory.cc`
**关键接口**: `TransformableFrameInterface`, `TransformableVideoFrameInterface`, `TransformableAudioFrameInterface`, `FrameTransformerInterface`

帧转换器允许在编码前/解码后进行自定义帧处理。典型用途：
- **端到端加密 (E2EE)**: 在发送前加密帧，接收后解密
- **帧标注**: 添加水印或元数据
- **帧过滤**: 根据策略丢弃帧

**接口继承**:
```
TransformableFrameInterface
├── TransformableVideoFrameInterface  # + GetMetadata(), SetMetadata()
└── TransformableAudioFrameInterface
```

**frame_transformer_factory.cc**:
- `CreateFrameTransformer(TransformableVideoFrameInterface::CloneFunc)` — 创建帧转换器。`CloneFunc` 指定如何克隆视频帧。

---

## 七、错误处理与统计

### rtc_error.cc
**路径**: `api/rtc_error.cc`
**关键类**: `RTCError`

WebRTC 操作结果的错误类型。使用 `RTCErrorType` 枚举。

**常见错误类型**:
| 错误类型 | 含义 |
|----------|------|
| `NONE` | 无错误 |
| `INVALID_PARAMETER` | 无效参数 |
| `INVALID_RANGE` | 参数超出范围 |
| `SYNTAX_ERROR` | SDP 语法错误 |
| `INVALID_STATE` | 非法状态操作 |
| `INVALID_MODIFICATION` | 非法修改 |
| `NETWORK_ERROR` | 网络错误 |
| `RESOURCE_EXHAUSTED` | 资源耗尽 |
| `INTERNAL_ERROR` | 内部错误 |
| `OPERATION_ERROR_WITH_DATA` | 操作失败但有一致性数据 |

### legacy_stats_types.cc
**路径**: `api/legacy_stats_types.cc`
**关键类**: `StatsReport`, `StatsReport::Value`

传统 Stats API 的序列化/反序列化。Stats 是 `id→StatsReport` 的映射，每个 StatsReport 包含多个 `StatsReport::Value`（name + value 的组合）。

新的 Stats API（标准 `RTCStatsReport`）替代了此 Legacy API，后者保留用于向后兼容。

---

## 八、其他工具

### field_trials.cc / field_trials_registry.cc
**路径**: `api/field_trials.cc`, `api/field_trials_registry.cc`
**关键类**: `FieldTrials`

WebRTC 的 Field Trial（特性开关）系统。允许通过字符串键值对动态控制实验性功能，而无需重新编译。例如：
```
WebRTC-FlexFEC-03-Advertised/Enabled/
WebRTC-Video-H26xPacketBuffer/Enabled/
```

`FieldTrialsRegistry` 是全局注册表，但推荐使用 `Environment` 注入方式以避免全局状态。

### priority.cc
**路径**: `api/priority.cc`
**关键类**: `Priority`

任务优先级枚举：`Priority::kVeryLow`, `kLow`, `kNormal`, `kHigh`, `kVeryHigh`。用于任务队列调度。

### rtc_event_log_output_file.cc
**路径**: `api/rtc_event_log_output_file.cc`
**关键类**: `RtcEventLogOutputFile`

将 WebRTC 事件日志写入文件。支持限制最大文件大小、自动轮转。

---

## 学习扩展

### WebRTC 核心数据流

```
┌──────────────────────────────────────────────────────────────┐
│                    Application                                │
│  getUserMedia() ──→ createOffer()/createAnswer() ──→ 连接     │
│        │                    │                                 │
│        ▼                    ▼                                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │              PeerConnectionInterface                  │     │
│  │                                                      │     │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────┐              │
│  │  │  Audio  │  │  Video  │  │  Data    │              │
│  │  │  Track  │  │  Track  │  │  Channel │              │
│  │  └────┬────┘  └────┬────┘  └────┬─────┘              │
│  │       │            │            │                     │
│  │  ┌────▼────────────▼────────────▼─────┐              │
│  │  │         RtpTransceiver             │              │
│  │  │  ┌──────────┐  ┌──────────────┐    │              │
│  │  │  │  Sender  │  │   Receiver   │    │              │
│  │  │  └────┬─────┘  └──────┬───────┘    │              │
│  │  └───────┼───────────────┼────────────┘              │
│  │          │               │                            │
│  │  ┌───────▼───────────────▼────────────┐              │
│  │  │          MediaEngine               │              │
│  │  │  ┌──────┐  ┌──────┐  ┌──────┐      │              │
│  │  │  │Encoder│  │RTP/  │  │Network│     │              │
│  │  │  │Decoder│  │RTCP  │  │(ICE/  │     │              │
│  │  │  │       │  │      │  │DTLS)  │     │              │
│  │  │  └──────┘  └──────┘  └──────┘      │              │
│  │  └────────────────────────────────────┘              │
│  └──────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

### RTP 包结构

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|V=2|P|X|  CC   |M|     PT      |        sequence number        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           timestamp                           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           synchronization source (SSRC) identifier            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|            contributing source (CSRC) identifiers             |
|                             ....                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|   defined by profile   |           length                    |  (如果 X=1)
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          header extension (RTP Extension)                     |
|                             ....                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          payload                              |
|                             ....                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**RTP 头扩展 URI 常见列表**:
- `urn:ietf:params:rtp-hdrext:sdes:mid` — a=mid 标识
- `urn:ietf:params:rtp-hdrext:ssrc-audio-level` — 音频电平
- `http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time` — 绝对发送时间
- `http://www.webrtc.org/experiments/rtp-hdrext/transport-wide-cc-02` — 传输级拥塞控制 (TWCC)
- `urn:ietf:params:rtp-hdrext:toffset` — 时间戳偏移
- `urn:3gpp:video-orientation` — 视频旋转

### SDP ↔ Transceiver 映射

```
SDP m= section  ←→  RtpTransceiver
  m=audio ...   ←→  audio transceiver (sendrecv/sendonly/recvonly/inactive)
  m=video ...   ←→  video transceiver

RtpTransceiver {
  mid: 对应用 m= section 的 mid 属性
  direction: sendrecv/sendonly/recvonly/inactive/stopped
  sender:   RtpSender   → 发送编码参数
  receiver: RtpReceiver → 接收解码统计
}
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Factory** | `CreatePeerConnectionFactory`, `IceTransportFactory` | 封装复杂的对象创建 |
| **Builder** | `PeerConnectionFactoryDependencies` | 分步装配复杂对象 |
| **Strategy** | `EnableMedia`, `FrameTransformerInterface` | 运行时切换策略/算法 |
| **Observer** | `PeerConnectionObserver` | 连接事件回调 |
| **Bridge** | `PeerConnectionInterface` → `PeerConnection` | 接口与实现分离 |
| **Dependency Injection** | 所有 `*Dependencies` 结构体 | 外部注入依赖、可测试 |
| **Value Object** | `RtpParameters`, `Candidate`, `RTCError` | 数据传输对象 |
| **Null Object** | `data_channel_interface.cc` 中的默认实现 | 不分配 DataChannel 时的安全空对象 |
| **Adapter** | `JsepIceCandidate` | 将 ICE Candidate 适配为 JSEP 格式 |
| **Command** | `SetSessionDescriptionObserver` | 异步操作的回调抽象 |
| **State Machine** | JSEP SDP 协商 | SDP offer/answer/pranswer/rollback 状态机 |
| **Type Safe Enum** | `SdpType`, `Priority`, `MediaType` | 不用 enum class 的变体，提供字符串转换 |
