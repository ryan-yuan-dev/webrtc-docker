# peer_connection_interface

## 概述

`peer_connection_interface.h` / `peer_connection_interface.cc` 是 WebRTC 中最重要的头文件之一，定义了 `PeerConnectionInterface`、`PeerConnectionFactoryInterface`、`PeerConnectionObserver`、`PeerConnectionDependencies`、`PeerConnectionFactoryDependencies` 以及各种配置结构和状态枚举。这是应用程序使用 WebRTC 进行端到端通信的主要接口契约。

在 WebRTC 架构中，该文件位于 `api/` 层的核心位置，几乎所有 WebRTC 应用都直接依赖于此文件。

## 头文件接口 (.h)

### 状态枚举

**`SignalingState`**

| 值 | 说明 |
|----|------|
| `kStable` | 稳定状态，无进行中的 Offer/Answer 交换 |
| `kHaveLocalOffer` | 已设置本地 Offer |
| `kHaveLocalPrAnswer` | 已设置本地 Provisional Answer |
| `kHaveRemoteOffer` | 已收到远端 Offer |
| `kHaveRemotePrAnswer` | 已收到远端 Provisional Answer |
| `kClosed` | 已关闭 |

**`IceGatheringState`**

| 值 | 说明 |
|----|------|
| `kIceGatheringNew` | 初始状态 |
| `kIceGatheringGathering` | 正在收集候选 |
| `kIceGatheringComplete` | 收集完成 |

**`PeerConnectionState`**

| 值 | 说明 |
|----|------|
| `kNew` | 新建 |
| `kConnecting` | 连接中 |
| `kConnected` | 已连接 |
| `kDisconnected` | 已断开 |
| `kFailed` | 连接失败 |
| `kClosed` | 已关闭 |

**`IceConnectionState`**

| 值 | 说明 |
|----|------|
| `kIceConnectionNew` | 初始 |
| `kIceConnectionChecking` | 检查中 |
| `kIceConnectionConnected` | 已连接 |
| `kIceConnectionCompleted` | 完成 |
| `kIceConnectionFailed` | 失败 |
| `kIceConnectionDisconnected` | 已断开 |
| `kIceConnectionClosed` | 已关闭 |

**`SdpSemantics`**

| 值 | 说明 |
|----|------|
| `kUnifiedPlan` | 标准 Unified Plan SDP（推荐，默认） |
| `kPlanB_DEPRECATED` | 已废弃的 Plan B SDP |

### 结构体 `PeerConnectionInterface::IceServer`

| 成员 | 说明 |
|------|------|
| `uri` / `urls` | STUN/TURN 服务器地址 |
| `username` / `password` | TURN 凭据 |
| `tls_cert_policy` | TLS 证书策略 |
| `hostname` | 主机名（用于 TLS SNI） |
| `tls_alpn_protocols` | TLS ALPN 协议列表 |
| `tls_elliptic_curves` | TLS 椭圆曲线列表 |

### 结构体 `PeerConnectionInterface::RTCConfiguration`

核心配置结构，包含 50+ 配置项，主要类别：

| 类别 | 关键字段 |
|------|----------|
| ICE 服务器 | `servers` |
| ICE 策略 | `type`(kAll/kRelay/kNoHost/kNone), `bundle_policy`, `rtcp_mux_policy` |
| 连接超时 | `ice_connection_receiving_timeout`, `ice_backup_candidate_pair_ping_interval` |
| 候选策略 | `tcp_candidate_policy`, `candidate_network_policy`, `continual_gathering_policy` |
| 音频设置 | `audio_jitter_buffer_max_packets`, `audio_jitter_buffer_fast_accelerate`, `audio_jitter_buffer_min_delay_ms` |
| 网络限制 | `disable_ipv6_on_wifi`, `max_ipv6_networks`, `disable_link_local_networks` |
| SDP 语义 | `sdp_semantics` (kUnifiedPlan / kPlanB) |
| 安全 | `certificates`, `crypto_options`, `active_reset_srtp_params` |
| ICE 检查 | `ice_check_interval_strong_connectivity`, `ice_unwritable_timeout` |
| VPN | `vpn_preference`, `vpn_list` |
| 端口分配器 | `port_allocator_config` |

### 结构体 `RTCOfferAnswerOptions`

| 字段 | 说明 |
|------|------|
| `offer_to_receive_video/audio` | Plan B 兼容，控制是否包含 recv 方向 |
| `voice_activity_detection` | VAD 开关 |
| `ice_restart` | ICE 重启标记 |
| `use_rtp_mux` | 是否使用 BUNDLE |
| `raw_packetization_for_video` | 视频原始包化模式 |
| `num_simulcast_layers` | Simulcast 层数 |
| `use_obsolete_sctp_sdp` | 旧版 SCTP SDP 格式 |

### 类 `PeerConnectionInterface`

主要方法分类：

| 类别 | 方法 |
|------|------|
| 媒体管理 | `AddTrack()`, `RemoveTrackOrError()`, `AddTransceiver()`, `CreateSender()` |
| Stream 管理 | `AddStream()`, `RemoveStream()` (Plan B) |
| 收发器查询 | `GetSenders()`, `GetReceivers()`, `GetTransceivers()` |
| 信令 | `CreateOffer()`, `CreateAnswer()`, `SetLocalDescription()`, `SetRemoteDescription()` |
| 描述查询 | `local_description()`, `remote_description()`, `current_local_description()`, `pending_local_description()` |
| 状态查询 | `signaling_state()`, `ice_connection_state()`, `peer_connection_state()`, `ice_gathering_state()` |
| 统计 | `GetStats()` (legacy + spec-compliant) |
| DataChannel | `CreateDataChannelOrError()` |
| ICE 候选 | `AddIceCandidate()`, `RemoveIceCandidate()` |
| 配置 | `GetConfiguration()`, `SetConfiguration()` |
| 传输 | `LookupDtlsTransportByMid()`, `GetSctpTransport()` |
| 控制 | `Close()`, `RestartIce()`, `SetBitrate()`, `SetAudioPlayout()`, `SetAudioRecording()` |
| 事件日志 | `StartRtcEventLog()`, `StopRtcEventLog()` |

### 类 `PeerConnectionObserver`
事件回调接口，必须实现的方法：

| 方法 | 说明 |
|------|------|
| `OnSignalingChange(state)` | 信令状态变化 |
| `OnDataChannel(data_channel)` | 远端创建 DataChannel |
| `OnIceGatheringChange(state)` | ICE 收集状态变化 |
| `OnIceCandidate(candidate)` | 新的 ICE 候选已收集 |

可选实现的方法：

| 方法 | 说明 |
|------|------|
| `OnAddStream(stream)` | 收到远端媒体流 |
| `OnRemoveStream(stream)` | 远端关闭流 |
| `OnRenegotiationNeeded()` | 需要重新协商 |
| `OnIceConnectionChange(state)` | ICE 连接状态变化 |
| `OnTrack(transceiver)` | 新 Track 开始接收（Unified Plan） |
| `OnAddTrack(receiver, streams)` | 新接收器创建 |
| `OnRemoveTrack(receiver)` | Track 被移除 |

### 结构体 `PeerConnectionDependencies`

| 字段 | 说明 |
|------|------|
| `observer` (必须) | PeerConnectionObserver 指针 |
| `allocator` | PortAllocator |
| `async_dns_resolver_factory` | DNS 解析器工厂 |
| `ice_transport_factory` | ICE 传输工厂 |
| `cert_generator` | 证书生成器 |
| `tls_cert_verifier` | TLS 证书验证器 |
| `video_bitrate_allocator_factory` | 视频比特率分配器工厂 |
| `lna_permission_factory` | 本地网络访问权限工厂 |
| `trials` | Field trials 配置 |

### 结构体 `PeerConnectionFactoryDependencies`

| 字段类别 | 字段 |
|----------|------|
| 线程 | `network_thread`, `worker_thread`, `signaling_thread` |
| 网络 | `socket_factory`, `packet_socket_factory`, `network_manager`, `network_monitor_factory` |
| 日志 | `event_log_factory` |
| 控制 | `fec_controller_factory`, `network_state_predictor_factory`, `network_controller_factory` |
| 音频 | `adm`, `audio_encoder_factory`, `audio_decoder_factory`, `audio_mixer`, `audio_processing_builder`, `audio_frame_processor` |
| 视频 | `video_encoder_factory`, `video_decoder_factory` |
| 媒体 | `media_factory` (为 nullptr 时不创建媒体引擎) |
| 其他 | `env`, `neteq_factory`, `sctp_factory`, `decode_metronome`, `encode_metronome` |

### 类 `PeerConnectionFactoryInterface`

| 方法 | 说明 |
|------|------|
| `SetOptions(options)` | 设置工厂选项 |
| `CreatePeerConnectionOrError(config, deps)` | 创建 PeerConnection |
| `GetRtpSenderCapabilities(kind)` | 获取 RTP 发送能力 |
| `GetRtpReceiverCapabilities(kind)` | 获取 RTP 接收能力 |
| `CreateLocalMediaStream(stream_id)` | 创建本地 MediaStream |
| `CreateAudioSource(options)` | 创建音频源 |
| `CreateVideoTrack(source, label)` | 创建视频 Track |
| `CreateAudioTrack(label, source)` | 创建音频 Track |
| `StartAecDump(file, max_size)` / `StopAecDump()` | AEC dump 控制 |

### 枚举 `TlsCertPolicy`

| 值 | 说明 |
|----|------|
| `kTlsCertPolicySecure` | 强制证书验证（安全） |
| `kTlsCertPolicyInsecureNoCheck` | 跳过证书验证（不安全） |

### 枚举 `IceTransportsType`

| 值 | 说明 |
|----|------|
| `kNone` | 不收集候选 |
| `kRelay` | 仅中继候选 |
| `kNoHost` | 排除本地主机候选 |
| `kAll` | 所有类型的候选 |

### 枚举 `BundlePolicy`

| 值 | 说明 |
|----|------|
| `kBundlePolicyBalanced` | 平衡策略 |
| `kBundlePolicyMaxBundle` | 尽可能合并所有媒体流到同一传输 |
| `kBundlePolicyMaxCompat` | 最高兼容性，尽量不合并 |

## 实现文件 (.cc)

### RTCConfiguration
```cpp
RTCConfiguration::RTCConfiguration(RTCConfigurationType type) {
  if (type == kAggressive) {
    bundle_policy = kBundlePolicyMaxBundle;
    rtcp_mux_policy = kRtcpMuxPolicyRequire;
    ice_connection_receiving_timeout = kAggressiveIceConnectionReceivingTimeout;
    enable_ice_renomination = true;
    redetermine_role_on_ice_restart = false;
  }
}
```
Aggressive 配置提供更激进的连接建立策略，适用于对连接速度敏感的应用程序。

### AsString 实现
所有状态枚举值都提供了 `constexpr absl::string_view AsString()` 实现，支持编译期字符串转换和 `AbslStringify`。

## 学习扩展

- `PeerConnectionInterface` 是 WebRTC 最大的接口，覆盖了连接建立、媒体管理、统计、事件日志等所有方面。
- Unified Plan (`kUnifiedPlan`) 是当前和未来的标准 SDP 语义，每个收发器（Transceiver）对应一个 m= section。
- Plan B (`kPlanB_DEPRECATED`) 已标记废弃，不应用在新应用中。
- `PeerConnectionFactoryDependencies::media_factory` 的设计支持最小化构建：默认为 nullptr，只有在调用 `EnableMedia` 后才链接媒体模块。
- `RTCConfiguration` 中有 `port_allocator_config` 和 `PortAllocator` 两套端口分配机制：前者是配置参数，后者是从 `PeerConnectionDependencies` 注入的对象。

## 设计模式

**工厂模式 (Factory)**：`PeerConnectionFactoryInterface` 是抽象工厂，创建 `PeerConnection`、`MediaStream`、`Track` 等对象。

**观察者模式 (Observer)**：`PeerConnectionObserver` 接收所有 PC 事件回调。

**Builder 模式 (Builder)**：`RTCConfiguration` 和 `PeerConnectionFactoryDependencies` 作为参数对象，简化了构造函数的复杂度。

**Proxy 模式 (Proxy)**：创建的 PeerConnection 可能由 `PeerConnectionProxy` 包装以提供线程安全。

**策略模式 (Strategy)**：`PeerConnectionDependencies` 允许注入各种策略实现（PortAllocator、DNS 解析器、证书验证器等）。
