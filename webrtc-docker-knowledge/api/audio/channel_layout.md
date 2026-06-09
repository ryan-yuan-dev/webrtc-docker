# channel_layout

## 概述

`channel_layout` 定义了 WebRTC 的声道布局（Channel Layout）枚举体系和辅助函数。该文件衍生自 Chromium 的 `base/channel_layout.h`，用于描述音频声道在空间中的排列顺序和布局方式。

核心功能包括：定义声道布局枚举（从单声道到 7.1 环绕声等多种布局）、声道位置枚举（LEFT, RIGHT, CENTER 等）、声道间映射查询、声道数到布局的推导。

## 头文件接口 (.h)

### 枚举 ChannelLayout

声道布局枚举，定义了 30+ 种标准声道布局。值不可重用（UMA 日志记录需要）。关键布局：

| 枚举值 | 声道数 | 说明 |
|--------|--------|------|
| `CHANNEL_LAYOUT_NONE` | 0 | 无布局 |
| `CHANNEL_LAYOUT_UNSUPPORTED` | 0 | 不支持 |
| `CHANNEL_LAYOUT_MONO` | 1 | 前中置（Front C） |
| `CHANNEL_LAYOUT_STEREO` | 2 | 左 + 右（Front L, Front R） |
| `CHANNEL_LAYOUT_2_1` | 3 | 左 + 右 + 后中置 |
| `CHANNEL_LAYOUT_SURROUND` | 3 | 左 + 右 + 前中置 |
| `CHANNEL_LAYOUT_4_0` | 4 | 左 + 右 + 前中置 + 后中置 |
| `CHANNEL_LAYOUT_QUAD` | 4 | 左 + 右 + 后左 + 后右 |
| `CHANNEL_LAYOUT_5_0` | 5 | 5.0 环绕（含侧环绕） |
| `CHANNEL_LAYOUT_5_1` | 6 | 5.1 环绕（含 LFE） |
| `CHANNEL_LAYOUT_5_1_BACK` | 6 | 5.1 环绕（后环绕替代侧环绕） |
| `CHANNEL_LAYOUT_7_1` | 8 | 7.1 环绕 |
| `CHANNEL_LAYOUT_DISCRETE` | 0 | 声道不映射到扬声器 |
| `CHANNEL_LAYOUT_STEREO_AND_KEYBOARD_MIC` | 3 | 立体声 + 键盘麦克风（WebRTC 专用） |
| `CHANNEL_LAYOUT_BITSTREAM` | 0 | 码流透传模式 |
| `CHANNEL_LAYOUT_MAX` | - | 最大枚举值，等于 CHANNEL_LAYOUT_BITSTREAM |

### 枚举 Channels

多声道中每个声道的位置标识：

| 枚举值 | 说明 |
|--------|------|
| `LEFT` / `RIGHT` | 左 / 右（前置） |
| `CENTER` | 中置 |
| `LFE` | 低频效果声道（Subwoofer） |
| `BACK_LEFT` / `BACK_RIGHT` | 后置左 / 右 |
| `LEFT_OF_CENTER` / `RIGHT_OF_CENTER` | 中置偏左 / 偏右 |
| `BACK_CENTER` | 后中置 |
| `SIDE_LEFT` / `SIDE_RIGHT` | 侧环绕左 / 右 |
| `CHANNELS_MAX` | 最大枚举值 = SIDE_RIGHT |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `kMaxConcurrentChannels` | 8 | 所有布局中最大并发声道数 |

### 函数

| 函数 | 说明 |
|------|------|
| `ChannelOrder(layout, channel)` | 返回指定声道在交错流中的位置索引，-1 表示不使用 |
| `ChannelLayoutToChannelCount(layout)` | 返回给定布局的声道数 |
| `GuessChannelLayout(channels)` | 根据声道数猜测最佳布局 |
| `ChannelLayoutToString(layout)` | 返回布局名称的字符串表示 |

## 实现文件 (.cc)

### 静态查找表

**kLayoutToChannels**：将 `ChannelLayout` 枚举值映射到声道数。按布局枚举值的顺序直接索引访问。例如：
- `CHANNEL_LAYOUT_MONO` -> 1
- `CHANNEL_LAYOUT_STEREO` -> 2
- `CHANNEL_LAYOUT_5_1` -> 6
- `CHANNEL_LAYOUT_DISCRETE` -> 0

**kChannelOrderings**：二维数组，定义每种布局中各个声道在交错流中的位置。行索引为 `ChannelLayout`，列索引为 `Channels`（FL, FR, FC, LFE, BL, BR, FLofC, FRofC, BC, SL, SR）。值表示该声道在交错数据中的索引位置，-1 表示该布局不使用此声道。

例如，5.1 环绕声（CHANNEL_LAYOUT_5_1）的声道顺序：
```
交错排列: [FL0, FR0, FC0, LFE0, SL0, SR0, FL1, FR1, ...]
索引:        0     1     2     3     4     5
```
- ChannelOrder(5_1, LEFT) = 0
- ChannelOrder(5_1, CENTER) = 2
- ChannelOrder(5_1, SIDE_LEFT) = 4

### 函数实现

**ChannelLayoutToChannelCount()**
```cpp
int ChannelLayoutToChannelCount(ChannelLayout layout) {
  RTC_DCHECK_LT(static_cast<size_t>(layout), std::size(kLayoutToChannels));
  RTC_DCHECK_LE(kLayoutToChannels[layout], kMaxConcurrentChannels);
  return kLayoutToChannels[layout];
}
```
使用静态表直接索引，包含边界检查。

**GuessChannelLayout()**
```cpp
ChannelLayout GuessChannelLayout(int channels) {
  switch (channels) {
    case 1: return CHANNEL_LAYOUT_MONO;
    case 2: return CHANNEL_LAYOUT_STEREO;
    case 3: return CHANNEL_LAYOUT_SURROUND;
    case 4: return CHANNEL_LAYOUT_QUAD;
    case 5: return CHANNEL_LAYOUT_5_0;
    case 6: return CHANNEL_LAYOUT_5_1;
    case 7: return CHANNEL_LAYOUT_6_1;
    case 8: return CHANNEL_LAYOUT_7_1;
    default: return CHANNEL_LAYOUT_UNSUPPORTED;
  }
}
```
当声道数不匹配标准布局时，记录警告日志。

**ChannelOrder()**
```cpp
int ChannelOrder(ChannelLayout layout, Channels channel) {
  // 通过静态二维表直接索引
  return kChannelOrderings[layout][channel];
}
```

## 学习扩展

### 与 AudioFrame 的关系

`AudioFrame` 使用 `GuessChannelLayout(num_channels)` 在构造和调用 `UpdateFrame()` 时自动推导声道布局。多声道帧的声道布局信息通过 `channel_layout()` 获取。

### WebRTC 特殊布局

- `CHANNEL_LAYOUT_STEREO_AND_KEYBOARD_MIC`：包含键盘麦克风声道，在 WebRTC 采集管线中会被剥离（键盘麦数据仅在内部使用，不对外输出）。
- `CHANNEL_LAYOUT_DISCRETE`：声道不映射到特定扬声器位置，声道数需单独指定。

### 与 Chromium 的一致性

本文件直接派生自 Chromium 的 `base/channel_layout.h`，枚举值和声道顺序与 FFmpeg 保持一致，确保与浏览器媒体管线的兼容性。
