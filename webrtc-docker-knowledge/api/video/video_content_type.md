# video_content_type

## 概述

`VideoContentType` 是一个枚举类型，用一个字节表示视频内容类型，通过 RTP 头部扩展（`video-content-type`）在网络中传输。当前支持两种类型：`UNSPECIFIED`（普通实时视频）和 `SCREENSHARE`（屏幕共享）。辅助函数提供类型判断、合法性校验和字符串转换。

## 头文件接口 (.h)

- **枚举 `VideoContentType`**：`uint8_t` 类型，`UNSPECIFIED = 0`，`SCREENSHARE = 1`。仅使用最低位。
- **`videocontenttypehelpers` 命名空间**：
  - `IsScreenshare()`：判断是否为屏幕共享。
  - `IsValidContentType()`：校验 uint8 值是否为合法的 ContentType。
  - `ToString()`：返回 "screen" 或 "realtime"。

## 实现文件 (.cc)

- **`IsScreenshare()`**：通过位掩码 `(1u << 1) - 1 = 1` 检查最低位。包含一个检查机制确保其他位未被设置（兼容检测旧版值）。
- **`IsValidContentType()`**：允许低 6 位被设置（兼容旧版实现中使用的额外位）。
- **`ToString()`**：根据 `IsScreenshare` 结果返回 "screen" 或 "realtime"。

## 学习扩展

- **RTP 头部扩展**：`VideoContentType` 作为 RTP 头部扩展传输，接收端解析后可用于差异化处理（如屏幕共享使用不同的码率控制策略）。
- 屏幕共享内容在编码中的处理方式通常与普通视频不同——屏幕共享需要更高的空间分辨率但可以容忍更低帧率，使用不同的码率分配策略。

## 设计模式

**类型安全枚举（Type-safe Enum）**：`enum class` 提供类型安全的枚举值，配合 `videocontenttypehelpers` 中的辅助函数组成完整的内容类型管理体系。
