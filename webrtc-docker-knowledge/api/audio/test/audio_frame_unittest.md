# audio_frame_unittest

## 概述

`audio_frame_unittest` 是 `AudioFrame` 类的单元测试文件，使用 Google Test 框架，验证 AudioFrame 的核心功能：静音状态管理、buffer 清零、帧更新（UpdateFrame）、拷贝（CopyFrom）、多声道支持。

## 测试用例

| 测试名 | 验证内容 |
|--------|----------|
| `FrameStartsZeroedAndMuted` | 默认构造的 AudioFrame 为静音态，data_view() 为空，所有采样值为 0 |
| `UnmutedFrameIsInitiallyZeroedLegacy` | 使用 `mutable_data()`（无参版本）取消静音后，buffer 初始为零 |
| `UnmutedFrameIsInitiallyZeroed` | 使用带参数的 `mutable_data()` 取消静音后，确认声道为 MONO，samples_per_channel 正确 |
| `MutedFrameBufferIsZeroed` | 写入非零值后调用 `Mute()`，读取时全零，验证静音机制 |
| `UpdateFrameMono` | 更新单声道帧，验证所有元数据（timestamp、采样率、speech_type、vad_activity、声道数、声道布局）以及数据内容 |
| `UpdateFrameMultiChannel` | 更新多声道帧（立体声和 5.1），验证声道布局自动推导、数据长度正确 |
| `CopyFrom` | 从源 AudioFrame 拷贝到目标帧，验证所有字段和数据一致；验证静音帧拷贝 |

## 关键验证点

- **静音态行为**：静音帧的 `data()` 和 `data_view()` 始终返回零值，但 `mutable_data()` 调用后自动取消静音。
- **UpdateFrame 的空指针处理**：`data` 参数为 `nullptr` 时帧进入静音态。
- **声道布局自动推导**：`GuessChannelLayout()` 根据声道数自动选择声道布局。
