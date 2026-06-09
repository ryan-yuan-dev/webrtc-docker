# time_delta

## 概述

`time_delta.h` / `time_delta.cc` 定义了 WebRTC 的强类型时间间隔 (Time Delta) 单位。`TimeDelta` 表示两个时间点之间的差值，既可以表示持续时间（如编码延迟、RTT），也可以表示任意时间间隔。内部存储单位为微秒 (microseconds, us)。

`TimeDelta` 是 `RelativeUnit` 的子类，支持丰富的算术运算。与 `Timestamp` 配合使用时，`Timestamp + TimeDelta = Timestamp`；`Timestamp - Timestamp = TimeDelta`。

## 头文件接口 (.h)

**文件**: `api/units/time_delta.h`

### TimeDelta 类

```cpp
class TimeDelta final : public rtc_units_impl::RelativeUnit<TimeDelta> {
 public:
  template <typename T>
  static constexpr TimeDelta Minutes(T value);       // 从分钟构造
  template <typename T>
  static constexpr TimeDelta Seconds(T value);       // 从秒构造
  template <typename T>
  static constexpr TimeDelta Millis(T value);        // 从毫秒构造
  template <typename T>
  static constexpr TimeDelta Micros(T value);        // 从微秒构造

  constexpr TimeDelta() = default;                    // 构造零值

  // 模板访问方法 (支持 int64_t, double 等)
  template <typename T = int64_t>
  constexpr T seconds() const;                       // 获取秒值
  template <typename T = int64_t>
  constexpr T ms() const;                            // 获取毫秒值
  template <typename T = int64_t>
  constexpr T us() const;                            // 获取微秒值
  template <typename T = int64_t>
  constexpr T ns() const;                            // 获取纳秒值

  // 带 fallback 的访问
  constexpr int64_t seconds_or(int64_t fallback_value) const;
  constexpr int64_t ms_or(int64_t fallback_value) const;
  constexpr int64_t us_or(int64_t fallback_value) const;

  // 绝对值
  constexpr TimeDelta Abs() const;
};
```

### 关键属性

- `one_sided = false`: TimeDelta 可以为负（负的时间间隔有意义）
- `UnitBase<TimeDelta>`: 基础单元类型

## 实现文件 (.cc)

**文件**: `api/units/time_delta.cc`

### ToString

```cpp
std::string ToString(TimeDelta value) {
  if (value.IsPlusInfinity())
    sb << "+inf ms";
  else if (value.IsMinusInfinity())
    sb << "-inf ms";
  else {
    if (value.us() == 0 || (value.us() % 1000) != 0)
      sb << value.us() << " us";
    else if (value.ms() % 1000 != 0)
      sb << value.ms() << " ms";
    else
      sb << value.seconds() << " s";
  }
}
```

格式化规则（智能输出最合适的单位）：
| 条件 | 输出示例 |
|------|----------|
| 0 us 或 us % 1000 != 0 | `500 us` |
| ms % 1000 != 0 | `10 ms` |
| 其他 | `5 s` |
| 正无穷 | `+inf ms` |
| 负无穷 | `-inf ms` |

## 学习扩展

### 典型应用场景

| 场景 | TimeDelta 值 | 说明 |
|------|-------------|------|
| RTT (局域网) | 1-5 ms | 局域网延迟 |
| RTT (互联网) | 20-200 ms | 广域网延迟 |
| 视频帧间隔 (30fps) | ~33 ms | 帧间隔 |
| 视频帧间隔 (60fps) | ~16.67 ms | 帧间隔 |
| 音频 20ms 帧 | 20 ms | Opus 帧 |
| GoogCC 处理间隔 | 25 ms | 拥塞控制更新周期 |
| NTP 同步间隔 | 若干秒 | 时钟同步 |
| 超时 (ICE) | 若干秒 | 连接超时 |

### 时间单位与精度

```cpp
// 内部存储: int64_t 微秒
// 最大可表示范围: 约 ±292,471 年
// 精度: 1 微秒

// 构造和访问
TimeDelta::Minutes(5)        // 300,000,000 us
TimeDelta::Seconds(30)       // 30,000,000 us
TimeDelta::Millis(100)       // 100,000 us
TimeDelta::Micros(500)       // 500 us

// 异或运算
td.seconds<double>()         // 双精度秒（适用于除法）
td.ms()                      // int64_t 毫秒
td.us()                      // int64_t 微秒
td.ns()                      // int64_t 纳秒 (= us * 1000)
```

### 为什么微秒是最佳单位？

- 1 us 精度足以覆盖 WebRTC 的所有时间场景（音频采样周期 ~20us @ 48kHz）
- int64_t 提供足够的动态范围（数十万年）
- 避免浮点运算（使用整数运算保证确定性）
- 微秒是常见硬件计时器的标准精度

### Abs() 方法

```cpp
TimeDelta td = TimeDelta::Millis(-10);
td.Abs();  // TimeDelta::Millis(10)
```

用于需要时间绝对值的安全计算，例如 RTT 偏差计算。

## 设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递 |
| **Strong Typedef** | 编译期区分 TimeDelta 与 Timestamp、DataRate 等 |
| **Dimensional Analysis** | 时间间隔与时间戳的组合运算（Timestamp ± TimeDelta） |

## 测试: time_delta_unittest.cc

单元测试覆盖：
- 构造方法正确性 (Minutes, Seconds, Millis, Micros)
- 单位转换 (s ↔ ms ↔ us ↔ ns)
- ToString 格式化（智能单位选择）
- 算术运算 (+=, -=, 按标量乘除)
- Abs() 绝对值
- 无穷大和零值
- 与 Timestamp 的加减运算
