# rtc_error

## 概述

`rtc_error.h` / `rtc_error.cc` 定义了 WebRTC 的错误类型系统，包括 `RTCErrorType`、`RTCErrorDetailType` 枚举，`RTCError` 类以及 `RTCErrorOr<T>` 模板。该错误系统类似于 `absl::StatusOr`，用于在 WebRTC API 中统一传递错误信息，对应 W3C 规范中的 RTCError 和 DOMException。

在 WebRTC 架构中，该文件位于 `api/` 层，几乎所有需要错误返回的 API 都使用此类型。

## 头文件接口 (.h)

### 枚举 `RTCErrorType`

| 值 | 说明 | 对应的 DOM 异常 |
|----|------|----------------|
| `NONE` | 无错误 | - |
| `UNSUPPORTED_OPERATION` | 操作合法但暂不支持 | OperationError |
| `UNSUPPORTED_PARAMETER` | 参数合法但暂不支持 | OperationError |
| `INVALID_PARAMETER` | 无效参数 | InvalidAccessError / TypeError |
| `INVALID_RANGE` | 参数值超出范围 | RangeError |
| `SYNTAX_ERROR` | 字符串解析错误 | SyntaxError |
| `INVALID_STATE` | 对象当前状态不支持该操作 | InvalidStateError |
| `INVALID_MODIFICATION` | 非法修改 | InvalidModificationError |
| `NETWORK_ERROR` | 网络协议错误 | NetworkError |
| `RESOURCE_EXHAUSTED` | 资源耗尽 | OperationError |
| `INTERNAL_ERROR` | 内部错误 | OperationError |
| `OPERATION_ERROR_WITH_DATA` | 错误附带额外数据 | RTCError |

### 枚举 `RTCErrorDetailType`

| 值 | 说明 |
|----|------|
| `NONE` | 无具体信息 |
| `DATA_CHANNEL_FAILURE` | DataChannel 错误 |
| `DTLS_FAILURE` | DTLS 握手失败 |
| `FINGERPRINT_FAILURE` | 指纹验证失败 |
| `SCTP_FAILURE` | SCTP 关联错误 |
| `SDP_SYNTAX_ERROR` | SDP 语法错误 |
| `HARDWARE_ENCODER_NOT_AVAILABLE` | 硬件编码器不可用 |
| `HARDWARE_ENCODER_ERROR` | 硬件编码器错误 |

### 类 `RTCError`

| 方法 | 说明 |
|------|------|
| `OK()` | 静态方法，返回无错误对象 |
| `type()` / `set_type()` | 错误类型 |
| `message()` / `set_message()` | 人类可读的错误信息（仅用于日志） |
| `error_detail()` / `set_error_detail()` | 详细错误信息 |
| `sctp_cause_code()` / `set_sctp_cause_code()` | SCTP 原因码 |
| `ok()` | 是否无错误 (`type_ == NONE`) |

### 宏 `LOG_AND_RETURN_ERROR`

```cpp
LOG_AND_RETURN_ERROR(type, message)  // 记录日志并返回 RTCError
LOG_AND_RETURN_ERROR_EX(type, message, severity)  // 可指定日志级别
```

### 模板类 `RTCErrorOr<T>`
类似 `absl::StatusOr<T>` 的联合类型，要么包含有效值，要么包含错误。

| 方法 | 说明 |
|------|------|
| `ok()` | 是否包含有效值 |
| `error()` / `MoveError()` | 获取错误 |
| `value()` | 获取值的引用 |
| `MoveValue()` | 移动获取值 |

```cpp
// 使用示例
RTCErrorOr<std::unique_ptr<Foo>> result = FooFactory::MakeNewFoo(arg);
if (result.ok()) {
  auto foo = result.ConsumeValue();
  foo->DoSomethingCool();
} else {
  RTC_LOG(LS_ERROR) << result.error();
}
```

## 实现文件 (.cc)

### 名称字符串表
- `kRTCErrorTypeNames[]`：按 `RTCErrorType` 枚举索引映射的字符串数组，使用 `static_assert` 确保数组大小与枚举值数量一致。
- `kRTCErrorDetailTypeNames[]`：`RTCErrorDetailType` 的字符串映射。

### RTCError::OK()
返回默认构造的 `RTCError()`（`type_ = NONE`）。

### ToString(RTCErrorType) / ToString(RTCErrorDetailType)
通过枚举值直接索引预定义字符串数组。

## 学习扩展

- `RTCError` 的 `message()` 返回 `const char*`，不应被用于程序逻辑判断，仅用于日志/诊断。
- `RTCErrorOr<T>` 的默认构造生成 `INTERNAL_ERROR`（而非 `NONE`），防止意外将未初始化的错误视为"成功"。
- `RTCErrorOr<T>` 禁止拷贝，只允许移动，鼓励显式的错误处理。
- `RTCErrorDetailType` 的 `OPERATION_ERROR_WITH_DATA` 类型可能附带额外的 `sctp_cause_code`，用于报告 SCTP 协议层面的具体原因。

## 设计模式

**Result 模式 (Result Type)**：`RTCErrorOr<T>` 实现了函数式编程中的 Result 类型，强制调用者处理错误路径。

**Null Object 模式 (Null Object)**：`RTCError::OK()` 返回代表"无错误"的哨兵实例。

**宏封装 (Macro Encapsulation)**：`LOG_AND_RETURN_ERROR` 宏封装了日志记录和错误返回的常见模式。
