# stun

## 概述

`stun.h` / `stun.cc` 实现了 STUN (Session Traversal Utilities for NAT, RFC 5389 / RFC 8489) 协议的完整编解码。STUN 是 WebRTC ICE 框架的基础协议，用于 NAT 穿透过程中的地址发现和连通性检查。

该模块定义了完整的 STUN 消息结构、各种属性类型的解析和序列化，以及消息完整性校验 (HMAC-SHA1) 和指纹 (CRC32) 验证。还包括对 TURN (RFC 5766) 和 ICE (RFC 5245) 的扩展支持。

`stun.cc` 文件约 49KB，是 api/transport 目录下最大的实现文件。

## 头文件接口 (.h)

**文件**: `api/transport/stun.h` (约 767 行)

### STUN 消息类型

```cpp
enum StunMessageType : uint16_t {
  STUN_INVALID_MESSAGE_TYPE    = 0x0000,
  STUN_BINDING_REQUEST         = 0x0001,  // 绑定请求
  STUN_BINDING_INDICATION      = 0x0011,  // 绑定指示（无响应）
  STUN_BINDING_RESPONSE        = 0x0101,  // 绑定成功响应
  STUN_BINDING_ERROR_RESPONSE  = 0x0111,  // 绑定错误响应

  GOOG_PING_REQUEST            = 0x200,   // Google PING 变体
  GOOG_PING_RESPONSE           = 0x300,
  GOOG_PING_ERROR_RESPONSE     = 0x310,
};
```

### STUN 属性类型

```cpp
enum StunAttributeType {
  STUN_ATTR_MAPPED_ADDRESS        = 0x0001,  // 映射地址
  STUN_ATTR_USERNAME              = 0x0006,  // 用户名
  STUN_ATTR_MESSAGE_INTEGRITY     = 0x0008,  // HMAC-SHA1 (20 bytes)
  STUN_ATTR_ERROR_CODE            = 0x0009,  // 错误码
  STUN_ATTR_UNKNOWN_ATTRIBUTES    = 0x000a,  // 未知属性列表
  STUN_ATTR_REALM                 = 0x0014,  // 认证域
  STUN_ATTR_NONCE                 = 0x0015,  // 随机数
  STUN_ATTR_XOR_MAPPED_ADDRESS    = 0x0020,  // XOR 混淆映射地址
  STUN_ATTR_SOFTWARE              = 0x8022,  // 软件信息
  STUN_ATTR_ALTERNATE_SERVER      = 0x8023,  // 备选服务器
  STUN_ATTR_FINGERPRINT           = 0x8028,  // CRC32 指纹
  STUN_ATTR_RETRANSMIT_COUNT      = 0xFF00,  // 重传计数
};
```

### StunMessage (核心类)

```cpp
class StunMessage {
 public:
  StunMessage();
  explicit StunMessage(uint16_t type);
  StunMessage(uint16_t type, absl::string_view transaction_id);

  enum class IntegrityStatus {
    kNotSet, kNoIntegrity, kIntegrityOk, kIntegrityBad
  };

  // 属性访问
  int type() const;
  const std::string& transaction_id() const;
  uint32_t reduced_transaction_id() const;
  bool IsLegacy() const;

  // 获取特定属性
  const StunAddressAttribute* GetAddress(int type) const;
  const StunUInt32Attribute* GetUInt32(int type) const;
  const StunUInt64Attribute* GetUInt64(int type) const;
  const StunByteStringAttribute* GetByteString(int type) const;
  const StunUInt16ListAttribute* GetUInt16List(int type) const;
  const StunErrorCodeAttribute* GetErrorCode() const;

  // 属性管理
  void AddAttribute(std::unique_ptr<StunAttribute> attr);
  std::unique_ptr<StunAttribute> RemoveAttribute(int type);
  void ClearAttributes();
  std::vector<uint16_t> GetNonComprehendedAttributes() const;

  // 消息完整性
  IntegrityStatus ValidateMessageIntegrity(const std::string& password);
  bool AddMessageIntegrity(absl::string_view password);
  bool AddMessageIntegrity32(absl::string_view password);
  bool IntegrityOk() const;

  // 指纹
  bool AddFingerprint();
  static bool ValidateFingerprint(const char* data, size_t size);

  // 编解码
  bool Read(ByteBufferReader* buf);
  bool Write(ByteBufferWriter* buf) const;

  // 工具
  static bool IsStunMethod(ArrayView<int> methods, const char* data, size_t size);
  static std::string GenerateTransactionId();
  std::unique_ptr<StunMessage> Clone() const;
  bool EqualAttributes(const StunMessage* other,
                       std::function<bool(int type)> attribute_type_mask) const;
};
```

### 属性类层次

```
StunAttribute (基类)
  ├── StunAddressAttribute          // 记录 IP 地址 (MAPPED-ADDRESS 等)
  ├── StunXorAddressAttribute       // XOR 混淆地址 (XOR-MAPPED-ADDRESS)
  ├── StunUInt32Attribute           // 32-bit 整数 (FINGERPRINT 等)
  ├── StunUInt64Attribute           // 64-bit 整数 (ICE-CONTROLLED 等)
  ├── StunByteStringAttribute       // 字节串 (USERNAME, MESSAGE-INTEGRITY 等)
  ├── StunErrorCodeAttribute        // 错误码
  └── StunUInt16ListAttribute       // 16-bit 整数列表 (UNKNOWN-ATTRIBUTES)
```

### 协议扩展

```cpp
class TurnMessage : public StunMessage;  // TURN RFC 5766
class IceMessage : public StunMessage;   // ICE RFC 5245
```

### TURN 消息类型

```cpp
enum TurnMessageType : uint16_t {
  STUN_ALLOCATE_REQUEST           = 0x0003,
  STUN_ALLOCATE_RESPONSE          = 0x0103,
  TURN_SEND_INDICATION            = 0x0016,
  TURN_DATA_INDICATION            = 0x0017,
  TURN_CREATE_PERMISSION_REQUEST  = 0x0008,
  TURN_CHANNEL_BIND_REQUEST       = 0x0009,
  // ...
};
```

### TURN 和 ICE 属性

```cpp
// TURN 属性
enum TurnAttributeType {
  STUN_ATTR_CHANNEL_NUMBER    = 0x000C,   // 通道号
  STUN_ATTR_LIFETIME          = 0x000d,   // 生命周期
  STUN_ATTR_XOR_PEER_ADDRESS  = 0x0012,   // XOR 对端地址
  STUN_ATTR_DATA              = 0x0013,   // 数据
  // ...
};

// ICE 属性
enum IceAttributeType {
  STUN_ATTR_PRIORITY          = 0x0024,   // ICE 优先级
  STUN_ATTR_USE_CANDIDATE     = 0x0025,   // 提名候选者
  STUN_ATTR_ICE_CONTROLLED    = 0x8029,   // 受控角色
  STUN_ATTR_ICE_CONTROLLING   = 0x802A,   // 控制角色
  STUN_ATTR_GOOG_NETWORK_INFO = 0xC057,   // Google 网络信息
  // ...
};
```

### 辅助函数

```cpp
std::string StunMethodToString(int msg_type);
int GetStunSuccessResponseType(int request_type);
int GetStunErrorResponseType(int request_type);
bool IsStunRequestType(int msg_type);
bool IsStunIndicationType(int msg_type);
bool IsStunSuccessResponseType(int msg_type);
bool IsStunErrorResponseType(int msg_type);
bool ComputeStunCredentialHash(const std::string& username,
                               const std::string& realm,
                               const std::string& password,
                               std::string* hash);
std::unique_ptr<StunAttribute> CopyStunAttribute(
    const StunAttribute& attribute,
    ByteBufferWriter* tmp_buffer_ptr = 0);
```

## 实现文件 (.cc)

**文件**: `api/transport/stun.cc` (约 1500 行)

### 核心常量

```cpp
const int k127Utf8CharactersLengthInBytes = 508;
const int kMessageIntegrityAttributeLength = 20;
const int kTheoreticalMaximumAttributeLength = 65535;
const uint32_t kStunMagicCookie = 0x2112A442;
const uint32_t STUN_FINGERPRINT_XOR_VALUE = 0x5354554E;
const size_t kStunHeaderSize = 20;
const size_t kStunTransactionIdLength = 12;
```

### ReduceTransactionId

将 96-bit (12 字节) 的 Transaction ID 通过 XOR 折叠为 32-bit hash，用于统计和日志精简：

```cpp
uint32_t ReduceTransactionId(absl::string_view transaction_id) {
  uint32_t result = 0;
  uint32_t next;
  while (reader.ReadUInt32(&next)) {
    result ^= next;
  }
  return result;
}
```

### LengthValid

对各类属性进行长度合规性验证：

- USERNAME/REALM/NONCE/SOFTWARE: 最多 508 字节 (127 UTF-8 字符 x 4 字节)
- MESSAGE-INTEGRITY: 固定 20 字节 (SHA-1 HMAC)
- DATA: 无 RFC 限制，但理论上不超过 65535 字节

### StunMessage::Read

完整的 STUN 消息反序列化：

1. 读取 2 字节 message type
2. 检查 MSB -- RTP/RTCP 包 MSB 为 1，可用于区分 STUN 和非 STUN
3. 读取 2 字节 message length
4. 读取 4 字节 magic cookie (0x2112A442)
5. 读取 12 字节 transaction ID
6. 如果 magic cookie 不匹配，说明是 RFC 3489 旧版（混合使用 legacy 格式）
7. 逐个读取属性：type + length + value，创建对应类型的 StunAttribute

### StunMessage::Write

完整的 STUN 消息序列化：

1. 写入 message type
2. 写入 message length
3. 写入 magic cookie (非 legacy 模式)
4. 写入 transaction ID
5. 遍历属性，逐个写入 type + length + value

### ValidateMessageIntegrity (关键方法)

验证 HMAC-SHA1 消息完整性校验的完整流程：

1. 定位 MESSAGE-INTEGRITY 属性在原始 buffer 中的位置
2. 将 MESSAGE-INTEGRITY 属性之后的数据从 message length 中排除
3. 对调整后的消息计算 HMAC-SHA1 (使用 `ComputeHmac(DIGEST_SHA_1, ...)`)
4. 将计算结果与消息中的 HMAC 进行 memcmp 比较

支持两种完整性类型：
- `STUN_ATTR_MESSAGE_INTEGRITY` (0x0008): 标准的 20 字节 HMAC-SHA1
- `STUN_ATTR_GOOG_MESSAGE_INTEGRITY_32` (0xC060): Google 截断的 4 字节 HMAC

### AddMessageIntegrity

为消息添加 MESSAGE-INTEGRITY 属性的流程：

1. 先添加一个占位属性（填充零值）
2. 序列化完整消息
3. 计算 HMAC-SHA1（排除 MESSAGE-INTEGRITY 属性本身）
4. 将正确的 HMAC 写回占位属性

### ValidateFingerprint

验证 STUN 消息尾部的 CRC32 指纹：

```
CRC32(message_without_fingerprint_attr) XOR 0x5354554E == fingerprint_value
```

### AddFingerprint

添加 CRC32 指纹属性：

1. 添加一个值为 0 的占位 FINGERPRINT 属性
2. 序列化消息
3. 计算 CRC32（排除 FINGERPRINT 属性本身）
4. 将 `CRC32 XOR 0x5354554E` 写入属性值

### IsStunMethod

快速判断 buffer 是否为 STUN 消息的辅助方法：
- 检查 size 对齐和最小长度
- 检查 magic cookie
- 匹配给定的 method 列表

### StunAddressAttribute::Read/Write

地址属性编解码：

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0 0 0 0 0 0 0 0|    Family     |           Port                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                 Address (32 bits or 128 bits)                 |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- Family: 0x01 = IPv4, 0x02 = IPv6
- Port 和 Address 按网络字节序 (Big Endian)

### StunXorAddressAttribute

XOR-MAPPED-ADDRESS 编解码，地址与 Magic Cookie + Transaction ID 进行 XOR：

```cpp
// IPv4 XOR
v4addr.s_addr = v4addr.s_addr ^ HostToNetwork32(kStunMagicCookie);

// IPv6 XOR
ip_as_ints[0] ^= HostToNetwork32(kStunMagicCookie);  // 与 magic cookie XOR
ip_as_ints[1] ^= transactionid_as_ints[0];            // 与 Transaction ID XOR
ip_as_ints[2] ^= transactionid_as_ints[1];
ip_as_ints[3] ^= transactionid_as_ints[2];
// Port XOR
xoredport = port() ^ (kStunMagicCookie >> 16);
```

### 错误码编解码

STUN 错误码被编码为一个 32-bit 值，高 8-bit 为零，接着 8-bit 为 Class (百位)，低 8-bit 为 Number (个位)：

```
code = class_ * 100 + number_
```

例如：`STUN_ERROR_UNAUTHORIZED` (401) => class = 4, number = 1

### 辅助函数

- `StunMethodToString(int msg_type)` - 将消息类型枚举值转为可读字符串
- `GetStunSuccessResponseType(int req_type)` - 请求类型 | 0x100
- `GetStunErrorResponseType(int req_type)` - 请求类型 | 0x110
- `ComputeStunCredentialHash(...)` - MD5(username:realm:password) 用于长期凭证认证

### TurnMessage / IceMessage

两者均重写 `GetAttributeValueType()` 以识别各自扩展的属性类型，以及 `CreateNew()` 用于多态拷贝 (Clone):

```cpp
StunMessage* TurnMessage::CreateNew() const { return new TurnMessage(); }
StunMessage* IceMessage::CreateNew() const { return new IceMessage(); }
```

## 测试: stun_unittest.cc

**文件**: `api/transport/stun_unittest.cc` (约 69KB)

全面的 STUN 单元测试套件，覆盖范围包括：

### 测试内容

- **属性编解码**: 所有属性类型 (Address, XorAddress, UInt32, UInt64, ByteString, ErrorCode, UInt16List) 的 Read/Write 测试
- **消息序列化**: StunMessage 的 Read/Write 完整测试，包括 RFC 3489 legacy 格式
- **消息完整性**: MESSAGE-INTEGRITY 添加和验证，使用正确和错误密码
- **Fingerprint**: CRC32 指纹的添加和验证
- **错误处理**: 非法属性长度、格式错误的 buffer、不支持的属性类型
- **Transaction ID**: 生成、有效性验证、reduced_transaction_id
- **Google 自定义属性**: GOOG-PING, GOOG-MESSAGE-INTEGRITY-32 等
- **ICE/TURN 扩展**: IceMessage, TurnMessage 的属性和编解码
- **EqualAttributes**: 属性比较器测试
- **Clone**: 消息深拷贝测试

## 学习扩展

### STUN 在 WebRTC ICE 中的作用

```
ICE 连通性检查流程：

对端 A                     STUN 服务器                  对端 B
  │                           │                          │
  │── STUN Binding Request ──→│                          │
  │←─ STUN Binding Response ──│                          │
  │     (XOR-MAPPED-ADDRESS)  │                          │
  │                           │                          │
  │────────────────────────────────── STUN Binding Req ─→│
  │←───────────────────────────────── STUN Binding Resp ─│
  │                                                      │
```

### STUN 消息头结构

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0 0|  STUN Message Type        |         Message Length        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Magic Cookie                          |
|                       (0x2112A442)                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                     Transaction ID (96 bits)                  |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- Message Type 的高两位必须为 0，用于与 RTP (版本 2, 开头为 10) 区分
- Magic Cookie 用于区分 RFC 3489 (旧) 和 RFC 5389 (新)
- Transaction ID 用于匹配请求与响应

### 消息类型编码规则

```cpp
// 类型编码: 低 4 位是 Method, 随后两位是 Class
// Class 编码:
kStunTypeMask = 0x0110;
0x000 = Request     // STUN_BINDING_REQUEST     = 0x0001
0x010 = Indication  // STUN_BINDING_INDICATION  = 0x0011
0x100 = Success     // STUN_BINDING_RESPONSE    = 0x0101
0x110 = Error       // STUN_BINDING_ERROR_RESP  = 0x0111
```

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Serializable** | `StunMessage`, 所有 `StunAttribute` | 对象与字节流之间的双向转换 (Read/Write) |
| **Composite** | `StunMessage` + `StunAttribute` | 消息包含任意数量的属性，通过 AddAttribute/GetAttribute 管理 |
| **Factory Method** | `StunAttribute::Create(...)` | 根据 value_type 创建正确子类 |
| **Template Method** | `TurnMessage::GetAttributeValueType`, `IceMessage::GetAttributeValueType` | 子类重写属性类型解析方法，复用基类编解码逻辑 |
| **Prototype** | `StunMessage::CreateNew()` / `Clone()` | 通过多态创建和拷贝消息 |
