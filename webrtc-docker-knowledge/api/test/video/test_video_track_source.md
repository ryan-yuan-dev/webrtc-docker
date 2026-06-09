# test_video_track_source

## 概述

`TestVideoTrackSource` 是一个用于测试的 `VideoTrackSourceInterface` 实现，提供了视频轨道源的基本框架，允许子类实现自定义的视频帧生成逻辑。包含状态管理、Sink 注册/注销等基础功能。

## 头文件接口 (.h)

### `TestVideoTrackSource` 类

继承 `Notifier<VideoTrackSourceInterface>`：

- **`TestVideoTrackSource(remote, stream_label)`** — 构造，指定是否为远端源和可选的流标签
- **`SetState(new_state)`** — 设置源状态（kInitializing / kLive / kMuted / kEnded）
- **`state()`** — 获取当前状态
- **`remote()`** — 是否为远端源
- **`is_screencast()`** — 固定返回 `false`
- **`needs_denoising()`** — 固定返回 `nullopt`
- **`GetStats()`** — 返回 `false`
- **`AddOrUpdateSink(sink, wants)`** — 注册/更新视频 Sink
- **`RemoveSink(sink)`** — 移除视频 Sink
- **`SupportsEncodedOutput()`** — 固定返回 `false`
- **`GenerateKeyFrame()`** — 空操作
- **`AddEncodedSink()` / `RemoveEncodedSink()`** — 空操作

纯虚方法（子类需实现）：
| 方法 | 说明 |
|------|------|
| `Start()` | 开始产生视频 |
| `Stop()` | 停止产生视频 |
| `SetScreencast(bool)` | 设置屏幕共享模式 |
| `source()` | 返回底层 `VideoSourceInterface` 指针 |

可选覆盖方法：
| 方法 | 说明 |
|------|------|
| `SetEnableAdaptation(bool)` | 启用/禁用自适应 |
| `GetFrameWidth()` | 获取帧宽 |
| `GetFrameHeight()` | 获取帧高 |
| `OnOutputFormatRequest(w, h, max_fps)` | 输出格式请求回调 |
| `GetStreamLabel()` | 获取流标签 |

## 实现文件 (.cc)

- 构造函数初始化 `state_ = kInitializing`，对 `worker_thread_checker_` 和 `signaling_thread_checker_` 执行 `Detach()`。
- `SetState()` 在状态改变时调用 `FireOnChanged()` 通知观察者。
- `AddOrUpdateSink()` 和 `RemoveSink()` 分别委托给 `source()->AddOrUpdateSink()` / `RemoveSink()`。

## 学习扩展

- **Notifier**: WebRTC 的观察者通知机制基类。
- **VideoTrackSourceInterface**: 视频轨道源的标准接口，提供状态管理和 Sink 管理功能。
- **SequenceChecker**: WebRTC 的序列检查器，用于断言方法在正确的线程/任务队列上调用。

## 设计模式

- **模板方法模式** — 基类定义了通用框架，通过纯虚方法让子类实现具体行为。
- **观察者模式** — 通过 `Notifier` 和 `FireOnChanged()` 通知状态变化。
- **适配器模式** — 将底层 `source()` 与 `TestVideoTrackSource` 的 Sink 管理接口适配。
