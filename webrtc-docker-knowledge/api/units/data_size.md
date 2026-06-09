# data_size

## 概述

`data_size.h` / `data_size.cc` 定义了 WebRTC 的强类型数据量 (Data Size) 单位。`DataSize` 表示字节计数，用于描述 RTP 包大小、帧编码后大小、缓冲区容量、在途数据量等。内部存储单位为字节 (bytes)。

`DataSize` 是 `RelativeUnit` 的子类，支持与 `DataRate` 和 `TimeDelta` 之间的量纲运算。

## 头文件接口 (.h)

**文件**: `api/units/data_size.h`

### DataSize 类

```cpp
class DataSize final : public rtc_units_impl::RelativeUnit<DataSize> {
 public:
  template <typename T>
  static constexpr DataSize Bytes(T value);       // 从字节构造
  static constexpr DataSize Infinity();            // 正无穷

  constexpr DataSize() = default;

  template <typename T = int64_t>
  constexpr T bytes() const;                      // 获取字节值

  constexpr int64_t bytes_or(int64_t fallback_value) const;  // 带 fallback 的访问
};
```

- 构造方法：`Bytes(T)` 支持整型和浮点型参数
- 访问方法：`bytes<T>()` 返回指定类型的字节值
- 无穷大：`Infinity()` 返回正无穷
- `one_sided = true`，表示只能非负

## 实现文件 (.cc)

**文件**: `api/units/data_size.cc`

### ToString

```cpp
std::string ToString(DataSize value) {
  if (value.IsPlusInfinity())
    sb << "+inf bytes";
  else if (value.IsMinusInfinity())
    sb << "-inf bytes";
  else
    sb << value.bytes() << " bytes";
}
```

格式化规则简单：始终以 `bytes` 为单位输出（不自动换算为 KB/MB）。

## 学习扩展

### 典型应用场景

| 场景 | DataSize 值 | 说明 |
|------|-------------|------|
| 典型以太网 MTU | ~1500 bytes | 网络层包大小上限 |
| 典型 RTP 包负载 | ~1200 bytes | 应用层数据 |
| 视频关键帧 (I-frame) | 50-200 KB | 取决于分辨率和编码器 |
| P 帧 | 5-20 KB | 预测帧 |
| 音频包 (Opus 20ms) | ~200 bytes | 取决于码率 |
| 视频缓冲区 | 可配置 | 码率自适应缓冲区 |

### 量纲关系

`DataSize` 与 `DataRate` 和 `TimeDelta` 的互运算：

```cpp
// 速率 × 时间 = 数据量
DataSize size = DataRate::KilobitsPerSec(2000) * TimeDelta::Millis(100);
// = 2000 kbps × 100 ms = 200 kb = 25000 bytes

// 数据量 / 速率 = 时间
TimeDelta duration = DataSize::Bytes(1500) / DataRate::KilobitsPerSec(5000);
// = 1500 bytes / 5000 kbps = 1500 / 625000 Bps = 2.4 ms

// 数据量 / 时间 = 速率
DataRate rate = DataSize::Bytes(1500) / TimeDelta::Millis(10);
// = 1500 bytes / 10 ms = 150000 bytes/s = 1200000 bps
```

### 为什么 DataSize 始终以 bytes 为单位？

相比于使用 bit 作为内部单位，bytes 在 WebRTC 的上下文中更加直观，因为：
- RTP 包载荷大小通常以字节计算
- 缓冲区分配操作基于字节
- 大多数编解码器和协议均以字节为单位报告数据量

## 设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递 |
| **Strong Typedef** | 编译期区分 DataSize 与其他单位类型 |
| **Dimensional Analysis** | 通过运算符重载实现类型安全的量纲计算 |

## 测试: data_size_unittest.cc

单元测试覆盖：
- 构造方法正确性 (`Bytes`)
- 单位访问 (`bytes()`)
- `ToString` 格式化
- 无穷大和零值
- 与 DataRate 和 TimeDelta 的量纲运算
