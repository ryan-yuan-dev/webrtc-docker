# media_types

## 概述

`media_types.h` / `media_types.cc` 定义了 WebRTC 中媒体类型枚举 `MediaType` 及其字符串表示。这是一个贯穿整个 WebRTC 代码库的基础类型定义，用于标识音频、视频、数据等媒体类型。

在 WebRTC 架构中，该文件位于 `api/` 层，是最基础的类型定义之一，被几乎所有媒体相关的模块引用。

## 头文件接口 (.h)

### 枚举 `MediaType`

| 值 | 说明 |
|----|------|
| `AUDIO` | 音频媒体 |
| `VIDEO` | 视频媒体 |
| `DATA` | 数据通道 |
| `UNSUPPORTED` | 不支持的媒体类型 |
| `ANY` | 任意类型（用于通配匹配） |

### 函数 `MediaTypeToString`

| 输入 | 输出 |
|------|------|
| `MediaType::AUDIO` | `"audio"` |
| `MediaType::VIDEO` | `"video"` |
| `MediaType::DATA` | `"data"` |
| 其他 | 触发 `RTC_DCHECK_NOTREACHED()` |

### 全局字符串常量

| 常量 | 值 |
|------|-----|
| `kMediaTypeAudio` | `"audio"` |
| `kMediaTypeVideo` | `"video"` |
| `kMediaTypeData` | `"data"` |

## 实现文件 (.cc)

`MediaTypeToString` 实现：switch 语句将枚举值映射为 C 字符串，`UNSUPPORTED` 和 `ANY` 类型触发 DCHECK。

## 学习扩展

- `MediaType::UNSUPPORTED` 用于解析 SDP 时遇到不认识的媒体类型（如 `application`），不会崩溃。
- `kMediaTypeAudio` / `kMediaTypeVideo` 字符串常量在 `media_stream_interface.cc` 中被用来初始化 `MediaStreamTrackInterface::kAudioKind` / `kVideoKind`。
- `MediaType` 枚举通过 `RTP_TRANSCEIVER_DIRECTION` 等接口广泛用于判断收发器的媒体类型。

## 设计模式

**基础值类型 (Value Type)**：简单枚举 + 字符串转换函数，提供类型安全的同时兼容字符串表示。
