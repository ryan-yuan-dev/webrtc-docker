# media_stream_interface

## 概述

`media_stream_interface.h` / `media_stream_interface.cc` 定义了 WebRTC 媒体流（MediaStream）的核心接口体系，包括 `MediaStreamInterface`、`MediaStreamTrackInterface`、`AudioTrackInterface`、`VideoTrackInterface` 以及对应的源（Source）和观察者接口。这些接口对应于 W3C 的 Media Capture and Streams 规范。

在 WebRTC 架构中，该文件位于 `api/` 层，是应用程序与媒体引擎之间关于 Track/Stream 操作的主要契约。

## 头文件接口 (.h)

### 接口 `ObserverInterface` / `NotifierInterface`
通用的观察者模式基类：

| 方法 | 说明 |
|------|------|
| `OnChanged()` | 由 Notifier 通知状态变化 |
| `RegisterObserver(observer)` / `UnregisterObserver(observer)` | 注册/注销观察者 |

### 类 `MediaSourceInterface`
媒体源的基类：

| 方法 | 说明 |
|------|------|
| `state()` | 源状态：`kInitializing` / `kLive` / `kEnded` / `kMuted` |
| `remote()` | 是否为远端源 |

### 类 `MediaStreamTrackInterface`
C++ 版本的 `MediaStreamTrack`：

| 方法 | 说明 |
|------|------|
| `kind()` | 返回 `kAudioKind` ("audio") 或 `kVideoKind` ("video") |
| `id()` | Track 标识符 |
| `enabled()` / `set_enabled()` | 启用/禁用（禁用时产生静音或黑帧） |
| `state()` | `kLive` 或 `kEnded`（一旦变为 ended，不再恢复） |

常量：`kAudioKind = "audio"`，`kVideoKind = "video"`。

### 类 `VideoTrackSourceInterface`
视频源的接口：

| 方法 | 说明 |
|------|------|
| `is_screencast()` | 是否为屏幕共享源 |
| `needs_denoising()` | 是否需要去噪处理 |
| `GetStats(Stats*)` | 获取源统计（输入宽高） |
| `SupportsEncodedOutput()` | 是否支持编码输出 |
| `GenerateKeyFrame()` | 强制生成关键帧 |
| `AddEncodedSink(sink)` / `RemoveEncodedSink(sink)` | 管理编码帧接收器 |
| `ProcessConstraints(constraints)` | 通知源约束变化 |

### 类 `VideoTrackInterface`
视频 Track 接口：

| 方法 | 说明 |
|------|------|
| `AddOrUpdateSink(sink, wants)` / `RemoveSink(sink)` | 注册/注销视频帧接收器 |
| `GetSource()` | 获取底层视频源 |
| `content_hint()` / `set_content_hint()` | 内容提示（kNone/kFluid/kDetailed/kText） |

### 类 `AudioTrackSinkInterface`
音频数据接收器：

| 方法 | 说明 |
|------|------|
| `OnData(audio_data, bits_per_sample, sample_rate, channels, frames)` | 接收音频数据 |
| `OnData(... + absolute_capture_timestamp_ms)` | 带捕获时间戳的版本 |
| `NumPreferredChannels()` | 接收器偏好的声道数 |

### 类 `AudioSourceInterface`
音频源接口：

| 方法 | 说明 |
|------|------|
| `SetVolume(volume)` | 设置音量 (0~10) |
| `RegisterAudioObserver` / `UnregisterAudioObserver` | 管理音频观察者 |
| `AddSink(sink)` / `RemoveSink(sink)` | 管理音频数据接收器 |
| `options()` | 返回当前音频选项 |

### 类 `AudioProcessorInterface`
音频处理器接口：

| 方法 | 说明 |
|------|------|
| `GetStats(has_remote_tracks)` | 获取音频处理统计（噪声检测、APM 统计） |

### 类 `AudioTrackInterface`
音频 Track 接口：

| 方法 | 说明 |
|------|------|
| `GetSource()` | 获取底层音频源 |
| `AddSink(sink)` / `RemoveSink(sink)` | 管理音频数据接收器 |
| `GetSignalLevel(int*)` | 获取信号电平 |
| `GetAudioProcessor()` | 获取音频处理器 |

### 类型别名

```cpp
typedef std::vector<scoped_refptr<AudioTrackInterface>> AudioTrackVector;
typedef std::vector<scoped_refptr<VideoTrackInterface>> VideoTrackVector;
```

### 类 `MediaStreamInterface`
W3C MediaStream 的 C++ 版本：

| 方法 | 说明 |
|------|------|
| `id()` | Stream ID |
| `GetAudioTracks()` / `GetVideoTracks()` | 获取所有音频/视频 Track |
| `FindAudioTrack(track_id)` / `FindVideoTrack(track_id)` | 按 ID 查找 Track |
| `AddTrack(track)` / `RemoveTrack(track)` | 添加/移除 Track（默认实现 `RTC_CHECK_NOTREACHED`） |

## 实现文件 (.cc)

```cpp
const char* const MediaStreamTrackInterface::kVideoKind = kMediaTypeVideo;  // "video"
const char* const MediaStreamTrackInterface::kAudioKind = kMediaTypeAudio;  // "audio"
```

- `VideoTrackInterface::content_hint()` 默认返回 `ContentHint::kNone`。
- `AudioTrackInterface::GetSignalLevel()` 默认返回 `false`。
- `AudioTrackInterface::GetAudioProcessor()` 默认返回 `nullptr`。
- `AudioSourceInterface::options()` 默认返回空 `AudioOptions{}`。

## 学习扩展

- `MediaStreamInterface` 的 `AddTrack` 默认实现为 `RTC_CHECK_NOTREACHED()`，期望子类（如 `LocalMediaStream`）覆盖。
- 远程 Track 不会因为被添加到同一个 Stream 而自动同步音视频；同步需要 SDP 中的 `a=msid` 属性正确配置。
- `VideoTrackSourceInterface` 有两个线程约束：signaling thread 用于状态管理，worker thread 用于 `VideoSourceInterface<VideoFrame>` 方法。
- `AudioTrackSinkInterface` 提供两个 `OnData` 重载，较旧的版本没有 `absolute_capture_timestamp_ms` 参数，新版通过默认实现保持向后兼容。

## 设计模式

**观察者模式 (Observer Pattern)**：`ObserverInterface` / `NotifierInterface` 构成核心观察者机制；`AudioTrackSinkInterface` 作为数据推送的观察者。

**抽象工厂 (Abstract Factory)**：`PeerConnectionFactory` 创建具体的 `AudioTrack`、`VideoTrack` 和 `MediaStream`。

**接口分离原则 (Interface Segregation)**：Media Source、Track、Sink 分别定义为独立的接口，避免职责混合。
