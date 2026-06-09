# dtls_transport_interface

## 概述

`dtls_transport_interface.h` / `dtls_transport_interface.cc` 定义了 DTLS (Datagram Transport Layer Security) 传输层的接口和状态信息结构。DTLS 传输建立在 ICE 传输之上，为 RTP/RTCP 和 SCTP 数据提供加密安全保障，对应 W3C 规范的 RTCDtlsTransport 接口。

在 WebRTC 架构中，该接口位于 `api/` 层，是 PeerConnection 安全传输的抽象边界。

## 头文件接口 (.h)

### 枚举 `DtlsTransportState`

| 值 | 说明 |
|----|------|
| `kNew` | 尚未开始协商 |
| `kConnecting` | 正在进行 DTLS 握手协商 |
| `kConnected` | DTLS 握手完成，已验证指纹 |
| `kClosed` | 主动关闭 |
| `kFailed` | 握手失败或指纹验证失败 |

### 枚举 `DtlsTransportTlsRole`

| 值 | 说明 |
|----|------|
| `kServer` | 对端发送 CLIENT_HELLO |
| `kClient` | 本端发送 CLIENT_HELLO |

### 类 `DtlsTransportInformation`

提供 DTLS 传输的快照信息：

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `state()` | `DtlsTransportState` | 传输状态 |
| `role()` | `optional<DtlsTransportTlsRole>` | TLS 角色 |
| `tls_version()` | `optional<int>` | TLS 协议版本 |
| `ssl_cipher_suite()` | `optional<int>` | SSL 加密套件 |
| `srtp_cipher_suite()` | `optional<int>` | SRTP 加密套件 |
| `ssl_group_id()` | `optional<int>` | SSL 密钥交换组 ID |
| `remote_ssl_certificates()` | `const SSLCertChain*` | 远端 SSL 证书链（只读） |

### 类 `DtlsTransportObserverInterface`

| 方法 | 说明 |
|------|------|
| `OnStateChange(DtlsTransportInformation)` | 传输状态变化通知 |
| `OnError(RTCError)` | 发生错误导致状态跳转到 kFailed |

### 类 `DtlsTransportInterface`

| 方法 | 说明 |
|------|------|
| `ice_transport()` | 返回底层 ICE 传输 |
| `Information()` | 返回当前状态的快照（可跨线程调用） |
| `RegisterObserver` / `UnobserverObserver` | 注册/注销观察者 |

## 实现文件 (.cc)

### 构造函数
`DtlsTransportInformation` 提供多个构造函数覆盖，包括：
- 默认构造：状态为 `kNew`
- 仅状态构造
- 完整构造（状态、角色、TLS 版本、加密套件、证书等）
- 已废弃的旧版构造（不包含角色参数）

### 拷贝语义
支持深拷贝（deep copy），包括 `SSLCertChain` 的 `Clone()`，确保拷贝后的对象拥有独立的证书链所有权。

## 学习扩展

- DTLS 是 WebRTC 安全的核心：DTLS 握手后生成的密钥用于 SRTP 加密（视频/音频）和 SCTP over DTLS（数据通道）。
- DtlsTransportInformation 中的 `remote_ssl_certificates()` 可用于指纹验证（Fingerprint Verification），这是 WebRTC 身份认证的关键环节。
- DtlsTransportInterface 的所有非标记方法必须在 network thread 上调用，但 `Information()` 允许跨线程读取。
- DtlsTransportTlsRole 决定了 DTLS 握手中谁先发送 ClientHello，这由 ICE 角色（controlling/controlled）派生而来。

## 设计模式

**不可变快照 (Immutable Snapshot)**：`DtlsTransportInformation` 设计为值传递的快照对象，一旦创建就不再改变，适合在多线程间安全传递状态信息。

**观察者模式 (Observer Pattern)**：`DtlsTransportObserverInterface` 用于通知传输状态变化。

**接口隔离 (Interface Segregation)**：`DtlsTransportInterface` 为外部使用者提供最小接口，`DtlsTransportObserverInterface` 专注于事件通知。
