# audio_view

## 概述

`audio_view` 是 WebRTC 音频数据访问的视图层抽象，定义了三类音频 buffer 视图：`MonoView`、`InterleavedView` 和 `DeinterleavedView`。它位于 `api/audio/` 目录，基于 `ArrayView` 构建，为音频处理提供维度感知（声道数、每声道采样数）的类型安全视图。

该模块同时提供通用的辅助函数（`NumChannels`、`SamplesPerChannel`、`IsMono`、`CopySamples`、`ClearSamples`），帮助编写支持多种视图类型的泛型音频处理代码。

## 头文件接口 (.h)

### 类型别名

| 类型 | 定义 | 说明 |
|------|------|------|
| `MonoView<T>` | `ArrayView<T>` | 单声道连续音频 buffer 视图 |
| `kMaxNumberOfAudioChannels` | `constexpr size_t = 24` | WebRTC 支持的最大声道数 |

### 类模板 InterleavedView\<T\>

| 成员 | 说明 |
|------|------|
| `InterleavedView(data, samples_per_channel, num_channels)` | 从指针构造，支持泛型类型转换 |
| `InterleavedView(C-array, num_channels)` | 从 C 风格数组构造，自动计算 samples_per_channel |
| `num_channels()` / `samples_per_channel()` | 返回声道数 / 每声道采样数 |
| `data()` | 返回底层 `ArrayView<T>` |
| `AsMono()` | 当声道数为 1 时返回 `MonoView<T>` |
| `CopyFrom(source)` | 从另一个 InterleavedView 拷贝数据 |
| `empty()` / `size()` | 判断空 / 返回总采样数 |
| `operator[]` / `begin()` / `end()` | 迭代器支持 |

### 类模板 DeinterleavedView\<T\>

| 成员 | 说明 |
|------|------|
| `DeinterleavedView(data, samples_per_channel, num_channels)` | 从连续 buffer 构造（各声道连续排列） |
| `DeinterleavedView(channels[], samples_per_channel, num_channels)` | 从声道指针数组构造（各声道可能非连续分配） |
| `DeinterleavedView(vector<U*>, samples_per_channel)` | 从 `std::vector` 指针数组构造 |
| `operator[](idx)` | 返回第 idx 个声道的 `MonoView<T>` |
| `AsMono()` | 返回第一个声道的 MonoView |
| `Clear()` | 清零所有声道数据 |

### 辅助函数

| 函数 | 说明 |
|------|------|
| `NumChannels(view)` | 返回声道数（MonoView 始终返回 1） |
| `IsMono(view)` | 判断是否为单声道 |
| `SamplesPerChannel(view)` | 返回每声道采样数 |
| `IsInterleavedView(view)` | 编译期判断是否为 InterleavedView |
| `CopySamples(destination, source)` | 在视图间拷贝音频样本（memcpy 封装） |
| `ClearSamples(view)` | 将视图中所有样本清零 |
| `ClearSamples(view, sample_count)` | 将视图中前 sample_count 个样本清零 |

## 实现文件 (.cc)

`audio_view` 是纯模板头文件，**没有独立的 .cc 实现文件**。所有函数均为 inline 模板或 constexpr，在头文件中直接定义。

### 内部存储设计

- **InterleavedView**：存储 `num_channels_`、`samples_per_channel_` 和 `ArrayView<T> data_`。数据按声道交错（interleaved）排列。
- **DeinterleavedView**：使用 `std::variant<T* const*, T*>` 存储数据源，支持两种构造模式：
  - **连续 buffer 模式**（`T*`）：各声道数据在同一连续内存区域中顺序排列。
  - **指针数组模式**（`T* const*`）：各声道数据在不同内存区域，通过指针数组访问。通过 `is_ptr_array()` 判断当前使用哪种模式。

### 迭代器支持

InterleavedView 提供完整的迭代器接口（`begin/end/cbegin/cend/rbegin/rend/crbegin/crend`），支持 range-based for 循环。

### CopySamples 实现细节

- 使用 `memcpy` 完成数据拷贝，包含编译期和运行期检查：
  - `value_type` 大小必须一致。
  - 声道数必须匹配。
  - 每声道采样数必须匹配。
  - 目标 buffer 大小必须不小于源。

## 学习扩展

### 三种视图的内存布局

```
MonoView:         [s0, s1, s2, ..., sN]
InterleavedView:  [L0, R0, L1, R1, L2, R2, ...]  (2声道)
DeinterleavedView:[L0, L1, L2, ... | R0, R1, R2, ...] (2声道)
```

### 使用场景

- **MonoView**：单声道音频帧、DeinterleavedView 中访问单个声道。
- **InterleavedView**：`AudioFrame` 的数据访问接口（`data_view()` 返回 InterleavedView）。
- **DeinterleavedView**：`AudioBuffer` 内部使用，各声道独立处理。

### 与 ArrayView 的关系

三种 Views 均基于 `ArrayView<T>`（非拥有型视图），不负责内存管理，只提供访问接口。`InterleavedView` 和 `DeinterleavedView` 额外增加了声道维度的语义信息，使代码更具表达力。
