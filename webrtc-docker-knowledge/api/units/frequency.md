# frequency

## 概述

`frequency.h` / `frequency.cc` 定义了 WebRTC 的强类型频率 (Frequency) 单位。`Frequency` 表示周期事件的发生频率，用于描述视频时钟频率 (90kHz)、音频采样率 (48kHz)、视频帧率 (30fps) 等。内部存储单位为 milliHertz (mHz, 千分之一赫兹)。

`Frequency` 是 `RelativeUnit` 的子类，支持与 `TimeDelta` 和 `DataRate`/`DataSize` 之间的量纲运算。

## 头文件接口 (.h)

**文件**: `api/units/frequency.h`

### Frequency 类

```cpp
class Frequency final : public rtc_units_impl::RelativeUnit<Frequency> {
 public:
  template <typename T>
  static constexpr Frequency MilliHertz(T value);     // 从 mHz 构造
  template <typename T>
  static constexpr Frequency Hertz(T value);          // 从 Hz 构造 (value * 1000)
  template <typename T>
  static constexpr Frequency KiloHertz(T value);      // 从 kHz 构造 (value * 1000000)

  constexpr Frequency() = default;

  template <typename T = int64_t>
  constexpr T hertz() const;                          // 获取 Hz 值
  template <typename T = int64_t>
  constexpr T millihertz() const;                     // 获取 mHz 值
};
```

### 重载运算符

```cpp
// 频率与时间互转
constexpr Frequency operator/(int64_t nominator, const TimeDelta& interval);
constexpr TimeDelta operator/(int64_t nominator, const Frequency& frequency);

// 频率与时间的乘积 (返回无量纲 count)
constexpr double operator*(Frequency frequency, TimeDelta time_delta);
constexpr double operator*(TimeDelta time_delta, Frequency frequency);

// 频率与 DataRate/DataSize 的运算 (定义在 data_rate.h)
constexpr DataSize operator/(const DataRate rate, const Frequency frequency);
constexpr Frequency operator/(const DataRate rate, const DataSize size);
constexpr DataRate operator*(const DataSize size, const Frequency frequency);
```

## 实现文件 (.cc)

**文件**: `api/units/frequency.cc`

### ToString

```cpp
std::string ToString(Frequency value) {
  if (value.IsPlusInfinity())
    sb << "+inf Hz";
  else if (value.IsMinusInfinity())
    sb << "-inf Hz";
  else if (value.millihertz<int64_t>() % 1000 != 0)
    sb.AppendFormat("%.3f Hz", value.hertz<double>());
  else
    sb << value.hertz<int64_t>() << " Hz";
}
```

格式化规则：
- 无穷大输出 `+inf Hz` / `-inf Hz`
- 无法被 1000 整除的输出高精度格式（如 `90.000 Hz` 对应 90kHz 时钟）
- 能被 1000 整除的输出整数格式（如 `30 Hz` 对应 30fps）

## 学习扩展

### 典型频率值

| 场景 | 频率值 | 内部 mHz 值 |
|------|--------|-------------|
| RTP 视频时钟 | 90 kHz | 90,000,000 mHz |
| 音频采样率 (Opus) | 48 kHz | 48,000,000 mHz |
| 音频采样率 (PCMU) | 8 kHz | 8,000,000 mHz |
| 视频帧率 (30fps) | 30 Hz | 30,000 mHz |
| 视频帧率 (60fps) | 60 Hz | 60,000 mHz |
| NTP 时钟频率 | 1 kHz | 1,000,000 mHz |

### 量纲关系

```cpp
// 频率倒数 = 周期
TimeDelta period = 1 / Frequency::Hertz(30);  // 约 33.33 ms

// 频率 × 时间 = 计数
double frames = Frequency::Hertz(30) * TimeDelta::Seconds(2);  // 60.0 帧

// 码率 / 频率 = 每周期数据量
DataSize per_frame = DataRate::KilobitsPerSec(2000) / Frequency::Hertz(30);
// = 2000 kbps / 30 Hz ≈ 8333 bytes/frame
```

### 为什么使用 mHz 作为内部单位？

- 高精度: 毫赫兹 (mHz) 允许以千分之一赫兹的精度表示频率，可以精确表示像 90kHz 这样的值
- 整数运算: 所有内部计算使用 `int64_t` 整数运算，避免浮点精度损失
- 通用性: 从 1 mHz 到 1 GHz (超过 `int64_t` 范围但实际不使用的范围) 的动态范围

### 毫赫兹转换

```cpp
// 内部转换公式
Hertz = millihertz / 1000
KiloHertz = millihertz / 1000000

// 构造转换
MilliHertz(value)  → 直接存储 value
Hertz(value)       → 存储 value * 1000
KiloHertz(value)   → 存储 value * 1000000
```

## 设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递 |
| **Strong Typedef** | 编译期区分 Frequency 与其他单位类型 |
| **Dimensional Analysis** | 通过运算符重载实现频率与周期的转换 |

## 测试: frequency_unittest.cc

单元测试覆盖：
- 构造方法正确性 (MilliHertz, Hertz, KiloHertz)
- 单位转换 (mHz ↔ Hz ↔ kHz)
- ToString 格式化（整数和小数模式）
- 运算符验证 (`/` 频率↔周期, `*` 频率×时间)
- 与 DataRate 和 DataSize 的互运算
- 无穷大和零值
