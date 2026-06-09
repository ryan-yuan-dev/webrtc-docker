# timestamp

## 概述

`timestamp.h` / `timestamp.cc` 定义了 WebRTC 的强类型时间点 (Timestamp) 单位。`Timestamp` 表示一个绝对时间点，用于描述视频帧的捕获时刻、数据包的到达时间、RTT 测量时间等。内部存储单位为微秒 (microseconds, us)，相对于某个未指定的起始时刻 (epoch)。

与其他单位不同，`Timestamp` 是 `UnitBase` 的子类（而非 `RelativeUnit`），因此其值必须是单向的（`one_sided = true`），意味着负值无效。两个 `Timestamp` 相减得到 `TimeDelta`。

## 头文件接口 (.h)

**文件**: `api/units/timestamp.h`

### Timestamp 类

```cpp
class Timestamp final : public rtc_units_impl::UnitBase<Timestamp> {
 public:
  // 构造方法（均为 static 工厂）
  template <typename T>
  static constexpr Timestamp Seconds(T value);       // 从秒构造
  template <typename T>
  static constexpr Timestamp Millis(T value);        // 从毫秒构造
  template <typename T>
  static constexpr Timestamp Micros(T value);        // 从微秒构造

  Timestamp() = delete;  // 不允许默认构造（必须显式设置）

  // 访问方法
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

  // 算术运算
  constexpr Timestamp operator+(const TimeDelta delta) const;
  constexpr Timestamp operator-(const TimeDelta delta) const;
  constexpr TimeDelta operator-(const Timestamp other) const;
  constexpr Timestamp& operator+=(const TimeDelta delta);
  constexpr Timestamp& operator-=(const TimeDelta delta);
};
```

### 关键特性

- `Timestamp() = delete`: 防止无意义的空时间戳，必须使用 `Micros()`、`Millis()` 等静态方法构造
- `one_sided = true`: 时间戳必须为正（从 epoch 开始计时）
- `UnitBase<Timestamp>`: 基础类型是 `UnitBase`，不是 `RelativeUnit`

## 实现文件 (.cc)

**文件**: `api/units/timestamp.cc`

### ToString

```cpp
std::string ToString(Timestamp value) {
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

与 `TimeDelta::ToString` 的格式化逻辑相同，采用智能单位选择。

### 运算符实现

所有运算符都正确处理无穷大语义：

```cpp
// Timestamp + TimeDelta = Timestamp
constexpr Timestamp Timestamp::operator+(const TimeDelta delta) const {
  if (IsPlusInfinity() || delta.IsPlusInfinity()) {
    // 正无穷 + 正无穷 = 正无穷
    return PlusInfinity();
  } else if (IsMinusInfinity() || delta.IsMinusInfinity()) {
    // 负无穷 + 负无穷 = 负无穷
    return MinusInfinity();
  }
  return Timestamp::Micros(us() + delta.us());
}

// Timestamp - Timestamp = TimeDelta
constexpr TimeDelta Timestamp::operator-(const Timestamp other) const {
  // 无穷大语义处理
  return TimeDelta::Micros(us() - other.us());
}
```

`us - other.us` 是 int64_t 减法，结果可能为负，这赋值给 `TimeDelta` 是允许的（`TimeDelta` 可以为负）。

## 学习扩展

### Timestamp vs TimeDelta 的区分

| 概念 | Timestamp | TimeDelta |
|------|-----------|-----------|
| 含义 | 时间点 ("现在是几点") | 时间间隔 ("持续多久") |
| 纪元 | 相对未指定 epoch | 无纪元概念 |
| 负值 | 不允许 (one_sided=true) | 允许 (one_sided=false) |
| 默认构造 | 不允许 (= delete) | 允许 (构造 0 值) |
| 典型值 | 帧捕获时刻, 包到达时间 | RTT, 编码延迟, 超时 |
| 运算符 | Timestamp + TimeDelta → Timestamp | TimeDelta + TimeDelta → TimeDelta |
| | Timestamp - Timestamp → TimeDelta | TimeDelta × scalar → TimeDelta |

### 无穷大语义

`Timestamp` 支持 `PlusInfinity()` 和 `MinusInfinity()`，用于表示"无限未来"和"无限过去"：

```cpp
Timestamp::PlusInfinity()  // 表示尚未发生的事件
Timestamp::MinusInfinity() // 表示从不发生的事件

// 常见用途:
Timestamp send_time = Timestamp::PlusInfinity();  // 尚未发送
Timestamp receive_time;  // = 0 (默认不会编译通过, 因为没有默认构造)

// 典型使用模式:
PacketResult result;
result.receive_time = Timestamp::PlusInfinity();  // 标记为"未收到"
```

### 为什么禁止默认构造？

`Timestamp()` 被 delete 的设计决策防止了无意识地创建零值时间戳，强制开发者明确指定时间点，避免了常见的初始化遗漏问题。

```cpp
// 错误方式 (不会编译通过):
Timestamp t;  // Error! 被 delete

// 正确方式:
Timestamp t = Timestamp::Millis(0);       // 显式零值
Timestamp t2 = Timestamp::Micros(1000);   // 显式时间点
Timestamp t3 = Timestamp::Seconds(10);    // 显式时间点
```

### 在 WebRTC 中的使用场景

```cpp
// 1. 编码帧时间戳
Timestamp capture_time = Timestamp::Millis(env.clock()->TimeInMilliseconds());

// 2. 包到达时间
Timestamp arrival_time = Timestamp::Micros(rtp_packet.arrival_time_us());

// 3. 计算延迟
TimeDelta delay = arrival_time - capture_time;

// 4. 超时检测
if (now > deadline) { /* 超时 */ }

// 5. RTT 计算
TimeDelta rtt = receive_time - send_time;
```

## 设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递，静态工厂方法构造 |
| **Strong Typedef** | 编译期区分 Timestamp 与 TimeDelta，防止单位混淆 |
| **Null Object (via PlusInfinity)** | 使用无穷大表示"未设置"或"无效"状态 |
| **Delete Default Constructor** | 通过禁止默认构造强制开发者明确初始化 |

## 测试: timestamp_unittest.cc

单元测试覆盖：
- 构造方法正确性 (Millis, Micros, Seconds)
- 单位转换 (s ↔ ms ↔ us ↔ ns)
- ToString 格式化
- 算术运算 (+, -, +=, -=)
- Timestamp - Timestamp = TimeDelta
- Timestamp + TimeDelta = Timestamp
- 无穷大语义
- 比较运算符 (<, >, ==, !=)
