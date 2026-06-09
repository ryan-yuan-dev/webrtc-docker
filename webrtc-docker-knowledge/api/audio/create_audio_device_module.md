# create_audio_device_module

## 概述

`create_audio_device_module` 定义了 WebRTC 音频设备模块（ADM, AudioDeviceModule）的工厂函数 `CreateAudioDeviceModule()`。该函数根据指定的 `AudioLayer` 类型创建平台相关的音频设备模块实例，是音频采集和渲染管线的底层入口。

该文件非常简洁，仅提供了一个函数声明和一个简单的实现转发。

## 头文件接口 (.h)

### 函数

| 函数签名 | 说明 |
|----------|------|
| `CreateAudioDeviceModule(const Environment& env, AudioDeviceModule::AudioLayer audio_layer)` | 指定 `AudioLayer` 创建音频设备模块，返回 `scoped_refptr<AudioDeviceModule>` |

- `env`：当前 Environment（包含任务队列工厂、时钟等上下文信息）。
- `audio_layer`：指定音频 API 层类型（如 ALSA、PulseAudio、CoreAudio、WinMM 等平台相关选项）。
- 返回值：`absl_nullable scoped_refptr<AudioDeviceModule>`，创建失败可能返回 nullptr。

## 实现文件 (.cc)

### 实现逻辑

```cpp
absl_nullable scoped_refptr<AudioDeviceModule> CreateAudioDeviceModule(
    const Environment& env,
    AudioDeviceModule::AudioLayer audio_layer) {
  return AudioDeviceModuleImpl::Create(env, audio_layer);
}
```

直接委托给 `AudioDeviceModuleImpl::Create(env, audio_layer)` 静态工厂方法，由 `modules/audio_device/audio_device_impl.h` 中的具体实现完成平台相关的 ADM 创建。

## 学习扩展

### AudioDeviceModule 的作用

`AudioDeviceModule` 是 WebRTC 音频硬件抽象层，负责：
- 音频采集：从麦克风获取 PCM 数据。
- 音频渲染：将 PCM 数据发送到扬声器。
- 设备管理：枚举设备、控制音量、处理设备插拔。

### AudioLayer 类型（平台相关）

常见的 AudioLayer 包括：
- **Linux**: `kAlsaLinux`（ALSA 接口）、`kPulseAudio`（PulseAudio 接口）
- **macOS/iOS**: `kCoreAudio`（CoreAudio 接口）
- **Windows**: `kWinMM`（Windows Multimedia）、`kWASAPI`（Windows Audio Session API）
- **Android**: `kJava`（Java API）、`kOpenSLES`（OpenSL ES 接口）、`kAAudio`（AAudio 接口）

### 与 APM 的关系

音频设备模块采集的 PCM 数据通常会先封装为 `AudioFrame`，再送入 `AudioProcessing::ProcessStream()` 进行 AEC、NS、AGC 等处理，最后送入编码器。

在实际使用中，ADM 和 APM 配合构成完整的采集处理管线：
```
ADM (采集) → AudioFrame → APM (处理) → AudioFrame → 编码器
```
