# audio_codec_pair_id

## 概述

`AudioCodecPairId` 是 WebRTC 中用于关联一对编码器（Encoder）和解码器（Decoder）的轻量级标识符类。它的核心作用是让同一个编解码对（codec pair）中的编码器和解码器能够共享同一个 ID，从而在编码器端发生配置变更时，同步通知到对应的解码器。该 ID 是全局唯一的、可拷贝的、可比较的，适用于作为 `std::map` 或 `std::unordered_map` 的键。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/audio_codec_pair_id.h`

```cpp
class AudioCodecPairId final {
 public:
  AudioCodecPairId() = delete;                           // 禁止默认构造
  AudioCodecPairId(const AudioCodecPairId&) = default;   // 可拷贝
  AudioCodecPairId(AudioCodecPairId&&) = default;        // 可移动

  friend void swap(AudioCodecPairId& a, AudioCodecPairId& b);

  static AudioCodecPairId Create();                      // 工厂方法，创建新 ID

  // 比较运算符（==, !=, <, <=, >=, >）
  friend bool operator==(AudioCodecPairId a, AudioCodecPairId b);
  friend bool operator!=(AudioCodecPairId a, AudioCodecPairId b);
  // ... 全部六种比较运算符

  uint64_t NumericRepresentation() const;                // 获取数值表示

 private:
  explicit AudioCodecPairId(uint64_t id);
  uint64_t id_;
};
```

关键设计点：
- 禁止默认构造（`= delete`），确保每个 ID 对象都拥有有效值。
- `Create()` 是唯一的构造入口，返回的每个 ID 值全局唯一。
- `NumericRepresentation()` 返回适合用作 hash 值的数值。
- 全部比较运算符通过 `friend` 实现，支持在有序容器中使用。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/audio_codec_pair_id.cc`

实现围绕一个 static atomic 计数器和一个混淆函数展开：

1. **`GetNextId()`**: 使用 `std::atomic<uint64_t>` 静态变量作为全局递增计数器。`fetch_add(1, std::memory_order_relaxed)` 原子操作确保多线程安全。最多支持 `2^63` 次调用。

2. **`ObfuscateId()`**: 对递增序列做线性变换（乘以奇系数 + 奇常数），实现 1:1 映射，使 ID 对外看起来不可预测。这里利用 `uint64_t` 溢出实现模 `2^64` 运算。使用 `static_assert` 验证了前 10 个值。

3. **`AudioCodecPairId::Create()`**: 调用 `GetNextId()` 获取下一个 ID 值，经过 `ObfuscateId()` 混淆后构造 `AudioCodecPairId` 对象。

## 学习扩展

- **动机**: 当编码器根据网络条件动态调整配置（如 bitrate、frame length）时，需要通知解码器。`AudioCodecPairId` 提供了一种机制，使编码器/解码器可以共享一个 ID，factory 层据此可以实现自动同步。
- **RTC_DCHECK_LT** 宏用于边界检查：最多允许产生 `2^63` 个 ID，在长期运行的进程中不会用完。
- `std::memory_order_relaxed` 的用法：对于仅需原子性、不要求顺序一致性的计数操作，relaxed ordering 性能最佳。
- 混淆函数中使用的系数是质数（奇数），保证模 `2^64` 下存在乘法逆元，实现双射。

## 设计模式

- **工厂方法模式**: `Create()` 是静态工厂方法，封装了 ID 的创建逻辑。
- **值对象 (Value Object)**: 该类是不可变的值类型，不可默认构造、可拷贝、可比较，适合作为容器键。
- **不可预测 ID (Opaque Identifier)**: 内部使用混淆技术使 ID 序列不可预测，防止调用者产生对 ID 顺序的依赖。
