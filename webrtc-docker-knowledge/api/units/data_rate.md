# data_rate

## 概述

`data_rate.h` / `data_rate.cc` 定义了 WebRTC 的强类型数据速率 (Data Rate) 单位。`DataRate` 表示数据传输速率，用于描述带宽、编码码率、pacing 速率等。内部存储单位为 bps (bits per second)。

`DataRate` 是 `RelativeUnit` 的子类，支持与 `DataSize` 和 `TimeDelta` 之间的量纲运算，在编译期防止单位混淆。

## 头文件接口 (.h)

**文件**: `api/units/data_rate.h`

### DataRate 类

```cpp
class DataRate final : public rtc_units_impl::RelativeUnit<DataRate> {
 public:
  // 构造方法
  static constexpr DataRate BitsPerSec(T value);      // 从 bps 构造
  static constexpr DataRate BytesPerSec(T value);     // 从 Bps 构造 (value / 8)
  static constexpr DataRate KilobitsPerSec(T value);  // 从 kbps 构造 (value * 1000)
  static constexpr DataRate Infinity();               // 正无穷

  constexpr DataRate() = default;

  // 访问方法
  constexpr T bps() const;            // 获取 bps 值
  constexpr T bytes_per_sec() const;  // 获取 Bps 值 (bps / 8)
  constexpr T kbps() const;           // 获取 kbps 值 (bps / 1000)
  constexpr int64_t bps_or(int64_t fallback_value) const;
  constexpr int64_t kbps_or(int64_t fallback_value) const;
};
```

### 重载运算符

```cpp
// 关键量纲运算
constexpr DataRate operator/(const DataSize size, const TimeDelta duration);
constexpr TimeDelta operator/(const DataSize size, const DataRate rate);
constexpr DataSize operator*(const DataRate rate, const TimeDelta duration);

// 频率相关运算
constexpr DataSize operator/(const DataRate rate, const Frequency frequency);
constexpr Frequency operator/(const DataRate rate, const DataSize size);
constexpr DataRate operator*(const DataSize size, const Frequency frequency);
```

### 辅助函数

```cpp
std::string ToString(DataRate value);
```

### 内部实现辅助

```cpp
namespace data_rate_impl {
constexpr int64_t Microbits(const DataSize& size);  // bytes → microbits (bytes * 8000000)
constexpr int64_t MillibytePerSec(const DataRate& size);  // bps → millibytes/s
}
```

## 实现文件 (.cc)

**文件**: `api/units/data_rate.cc`

### ToString

```cpp
std::string ToString(DataRate value) {
  if (value.IsPlusInfinity())       return "+inf bps";
  else if (value.IsMinusInfinity()) return "-inf bps";
  else if (value.bps() == 0 || value.bps() % 1000 != 0)
    sb << value.bps() << " bps";
  else
    sb << value.kbps() << " kbps";
}
```

格式化规则：
- 正负无穷分别输出 `+inf bps` / `-inf bps`
- 无法被 1000 整除的输出 bps（如 `1500 bps`）
- 能被 1000 整除的输出 kbps（如 `2 kbps`）

### 关键运算符实现

`DataSize / TimeDelta = DataRate`:
```cpp
DataRate::BitsPerSec(Microbits(size) / duration.us())
// Microbits = bytes * 8000000
// 结果 = (bytes * 8000000 / us) bits per second
```

`DataSize / DataRate = TimeDelta`:
```cpp
TimeDelta::Micros(Microbits(size) / rate.bps())
```

`DataRate * TimeDelta = DataSize`:
```cpp
DataSize::Bytes((microbits + 4000000) / 8000000)  // 带四舍五入
```

`DataRate / Frequency = DataSize`:
```cpp
DataSize::Bytes(MillibytePerSec(rate) / millihertz)
// MillibytePerSec = bps * (1000/8)
// 结果 = (bps * 125) / mHz 字节 -> 截断而非四舍五入
```

## 学习扩展

### 典型应用场景

| 场景 | DataRate 值 | 代码示例 |
|------|-------------|----------|
| 音频编码码率 | 32 kbps | `DataRate::KilobitsPerSec(32)` |
| 视频最低码率 | 100 kbps | `DataRate::KilobitsPerSec(100)` |
| 视频目标码率 | 2 Mbps | `DataRate::KilobitsPerSec(2000)` |
| 以太网带宽 | 100 Mbps | `DataRate::KilobitsPerSec(100000)` |
| 探测速率 | 10 Mbps | `DataRate::KilobitsPerSec(10000)` |

### 量纲分析

```
DataSize     = DataRate × TimeDelta
TimeDelta    = DataSize / DataRate
DataRate     = DataSize / TimeDelta
DataSize     = DataRate / Frequency   (每周期数据量)
Frequency    = DataRate / DataSize    (每秒传输的块数)
DataRate     = DataSize × Frequency   (块大小 × 块频率)
```

## 设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递，通过工厂方法构造 |
| **Strong Typedef** | 编译期区分 DataRate、DataSize、TimeDelta 等不同类型 |
| **Dimensional Analysis** | 在类型系统中编码量纲关系，编译期禁止不兼容运算 |

## 测试: data_rate_unittest.cc

单元测试覆盖：
- 构造方法正确性 (BitsPerSec, BytesPerSec, KilobitsPerSec)
- 单位转换 (bps ↔ kbps ↔ bytes_per_sec)
- ToString 格式化
- 运算符验证 (`/` 和 `*` 的量纲运算)
- 无穷大和零值处理
