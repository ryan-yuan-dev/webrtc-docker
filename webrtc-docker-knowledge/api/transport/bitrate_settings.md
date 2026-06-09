# bitrate_settings

## 概述

`bitrate_settings.h` / `bitrate_settings.cc` 定义了码率相关的数据结构。WebRTC 中发送端的码率由三个关键参数控制：起始码率 (start)、最小码率 (min) 和最大码率 (max)。该模块定义了两个结构体 `BitrateSettings` 和 `BitrateConstraints`，它们表示相同的数据但使用不同的默认值和未赋值表示方法。

这两个结构体的分离反映了 API 层和内部实现层的不同需求：`BitrateSettings` 使用 `std::optional` 表示未设置字段，适合 API 调用方选择性配置；`BitrateConstraints` 使用默认值填充，适合内部流控引擎直接使用。

## 头文件接口 (.h)

**文件**: `api/transport/bitrate_settings.h`

### BitrateSettings

```cpp
struct RTC_EXPORT BitrateSettings {
  BitrateSettings();
  ~BitrateSettings();
  BitrateSettings(const BitrateSettings&);
  std::optional<int> min_bitrate_bps;   // 最小码率 (bps)
  std::optional<int> start_bitrate_bps; // 起始码率 (bps)
  std::optional<int> max_bitrate_bps;   // 最大码率 (bps)
};
```

- 三个字段均为 `std::optional<int>`，未设置时表示"不限制"或"使用默认值"
- 约束条件：0 <= min <= start <= max
- 标记为 `RTC_EXPORT`，属于 API 层的公开结构体

### BitrateConstraints

```cpp
struct BitrateConstraints {
  int min_bitrate_bps = 0;
  int start_bitrate_bps = kDefaultStartBitrateBps;  // = 300000
  int max_bitrate_bps = -1;  // -1 表示无限制
};
```

- 内部使用的版本，所有字段有具体默认值
- `start_bitrate_bps` 默认 300000 bps (300 Kbps)
- `max_bitrate_bps` 为 -1 表示无上限
- 注释指出 TODO: 应合并 `BitrateSettings` 和 `BitrateConstraints`

## 实现文件 (.cc)

**文件**: `api/transport/bitrate_settings.cc`

非常精简，仅提供默认构造/析构/拷贝构造的 `= default` 实现：

```cpp
BitrateSettings::BitrateSettings() = default;
BitrateSettings::~BitrateSettings() = default;
BitrateSettings::BitrateSettings(const BitrateSettings&) = default;
```

## 学习扩展

### 码率参数在 WebRTC 管道中的流转

```
应用层设置 BitrateSettings
       │
       ▼
PeerConnection 内部转换为 BitrateConstraints
       │
       ▼
带宽估计器 (GoogCC) 以此作为约束
       │
       ▼
编码器按目标码率编码
```

- **start_bitrate_bps**: 带宽估计器的先验值 (prior)，也是编码器初始配置的参考
- **min_bitrate_bps**: 防止带宽估计过低导致编码质量严重下降
- **max_bitrate_bps**: 限制单流最大码率，用于流控场景

### 为什么有两个结构体？

WebRTC 的 API 层希望提供更灵活的配置方式，因此使用 `std::optional` 允许调用方只设置关心的参数。内部实现则需要确定的数值以便进行运算。TODO 注释表明这两个结构体未来应合并。

### 默认起始码率的意义

300 Kbps 是一个保守的初始值，WebRTC 会在通话开始后通过探测 (probe) 快速收敛到实际可用带宽，这比直接使用过高的起始值导致网络拥塞更安全。

## 设计模式

| 模式 | 说明 |
|------|------|
| **Option Bag / Parameter Object** | 通过可选字段聚合多个配置参数，避免构造器参数过长 |
| **Separate Interface from Internal Representation** | API 层 (`BitrateSettings`) 与内部实现 (`BitrateConstraints`) 分离，各取所需 |
