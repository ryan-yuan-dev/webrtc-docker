# video_bitrate_allocator

## 概述

`VideoBitrateAllocator` 是 WebRTC 视频码率分配器的抽象基类，定义了输入总码率和帧率、输出各层码率分配的接口。`VideoBitrateAllocationParameters` 是参数结构体，封装了 `DataRate` 和帧率信息。`VideoBitrateAllocationObserver` 是观察者接口，用于接收码率分配更新的通知。

## 头文件接口 (.h)

- **`VideoBitrateAllocationParameters`**：
  - 两个构造函数：分别接受 `(uint32_t bps, uint32_t framerate)` 和 `(DataRate, double framerate)`。
  - 成员：`total_bitrate`（DataRate 类型）、`framerate`（double 类型）。
- **`VideoBitrateAllocator`**（抽象基类）：
  - `GetAllocation(uint32_t total_bitrate_bps, uint32_t framerate)`：遗留接口，虚方法。
  - `Allocate(VideoBitrateAllocationParameters)`：新接口，虚方法。
  - `SetLegacyConferenceMode(bool)`：弃用方法，用于旧版屏幕共享模式兼容。
  - 默认实现中 `GetAllocation` 调用 `Allocate`，反之亦然，形成转发环路。
- **`VideoBitrateAllocationObserver`**（观察者接口）：
  - `OnBitrateAllocationUpdated(const VideoBitrateAllocation&)`：纯虚函数，子类必须实现。

## 实现文件 (.cc)

- **参数构造**：uint32_t 版本将 bps 包装为 `DataRate::BitsPerSec()`，int 帧率转为 double。
- **默认行为**：`GetAllocation` 调用 `Allocate`，`Allocate` 又调用 `GetAllocation`。实际子类应重写其中一个以避免死循环。
- **`SetLegacyConferenceMode`**：默认空实现。

## 学习扩展

- 具体的码率分配策略由子类实现：`SimulcastRateAllocator`（用于 VP8/H264 等 Simulcast 场景）和 `SvcRateAllocator`（用于 VP9/AV1 SVC 场景）。
- `VideoBitrateAllocatorFactory`（在 `video_bitrate_allocator_factory.h` 中）定义了创建分配器的工厂接口，实现了**抽象工厂**的补充。

## 设计模式

**策略模式（Strategy）**：`VideoBitrateAllocator` 定义了码率分配的策略接口，不同编码方式（Simulcast/SVC）由不同子类实现具体策略。**观察者模式（Observer）**：`VideoBitrateAllocationObserver` 让外部组件订阅码率分配变更。**模板方法（Template Method）**：`GetAllocation` 和 `Allocate` 互调的设计由子类决定覆盖的粒度。
