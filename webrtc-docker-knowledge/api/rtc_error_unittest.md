# rtc_error_unittest

## 概述

`rtc_error_unittest.cc` 是对 `api/rtc_error.h` 中 `RTCError` 和 `RTCErrorOr<T>` 类的单元测试文件。

## 测试范围

- `RTCError` 默认构造（`ok()` 返回 true）
- `RTCError::OK()` 静态方法
- `RTCError` 带类型构造
- `RTCError` 带类型和信息构造
- `error_detail()` / `sctp_cause_code()` 设置和获取
- `ToString()` 字符串表示
- `RTCErrorOr<T>` 默认构造（`INTERNAL_ERROR`）
- `RTCErrorOr<T>` 从错误构造（`!ok()`）
- `RTCErrorOr<T>` 从值构造（`ok()`）
- `RTCErrorOr<T>::value()` / `MoveValue()` 取值
- `RTCErrorOr<T>::error()` / `MoveError()` 获取错误
- 移动语义
- `LOG_AND_RETURN_ERROR` 宏
- RTCErrorType / RTCErrorDetailType 枚举的 `ToString()`
