# WebRTC 单位类型 API 文档

## 概述

`api/units/` 定义了 WebRTC 中使用的强类型单位系统。这些类型通过在编译期防止单位混淆（如将毫秒当作微秒使用），消除了大量潜在的数值错误。

---

## 一、类型总览

| 类型 | 物理量 | 底层类型 | 示例 |
|------|--------|----------|------|
| `Timestamp` | 时间点 | `int64_t` 微秒 | `Timestamp::Micros(5000)` |
| `TimeDelta` | 时间间隔 | `int64_t` 微秒 | `TimeDelta::Millis(10)` |
| `DataRate` | 数据速率 | `int64_t` bps | `DataRate::KilobitsPerSec(500)` |
| `DataSize` | 数据量 | `int64_t` 字节 | `DataSize::Bytes(1500)` |
| `Frequency` | 频率 | `int64_t` mHz | `Frequency::Hertz(90000)` |

所有类型都定义在 `webrtc` 命名空间下，使用 `int64_t` 作为底层存储并提供丰富的运算符重载。

---

## 二、Timestamp (时间点)

### timestamp.cc
**路径**: `api/units/timestamp.cc`

表示一个绝对时间点 (如 "捕获时刻 12345 微秒")。

**构造方法**:
```cpp
Timestamp::Micros(us)     // 微秒
Timestamp::Millis(ms)     // 毫秒
Timestamp::Seconds(s)     // 秒
Timestamp::PlusInfinity() // +∞
Timestamp::MinusInfinity()// -∞
```

**运算**:
```cpp
Timestamp t1, t2;
TimeDelta d = t2 - t1;           // 时间差
Timestamp t3 = t1 + TimeDelta;   // 偏移
Timestamp t4 = t1 - TimeDelta;   // 回退
bool is_after = t2 > t1;         // 比较
```

**`ToString(value)`** — 智能格式化: `0 us` / `1000 us` / `1 ms` / `1 s`

**应用场景**: 视频帧的捕获时间戳、渲染时间点、包的到达时刻

---

## 三、TimeDelta (时间间隔)

### time_delta.cc
**路径**: `api/units/time_delta.cc`

表示一段持续时间 (如 "编码延迟 10ms")。

**构造方法**:
```cpp
TimeDelta::Micros(us)     // 微秒
TimeDelta::Millis(ms)     // 毫秒
TimeDelta::Seconds(s)     // 秒
TimeDelta::Minutes(m)     // 分
TimeDelta::PlusInfinity() // 无穷大
TimeDelta::Zero()         // 零
```

**运算**: 支持 `+`, `-`, `*`, `/` (按标量), `/` (两个 TimeDelta 得 double), 取模等。

**应用场景**: RTT、抖动缓冲区延迟、编码/解码耗时、超时配置

---

## 四、DataRate (数据速率)

### data_rate.cc
**路径**: `api/units/data_rate.cc`

表示数据传输速率 (如 "编码器目标码率 2Mbps")。

**构造方法**:
```cpp
DataRate::BitsPerSec(bps)
DataRate::KilobitsPerSec(kbps)
DataRate::MegabitsPerSec(mbps)
DataRate::BytesPerSec(Bps)
```

**关键运算**:
```cpp
DataSize size = rate * TimeDelta;  // 速率 × 时间 = 数据量
TimeDelta time = size / rate;      // 数据量 / 速率 = 时间
```

**应用场景**: 编码器目标码率、网络带宽估计、码率分配

---

## 五、DataSize (数据量)

### data_size.cc
**路径**: `api/units/data_size.cc`

表示数据大小 (如 "RTP MTU 1200 bytes")。

**构造方法**:
```cpp
DataSize::Bytes(B)
DataSize::Kilobytes(KB)
```

**应用场景**: RTP 包大小、帧编码后大小、缓冲区容量

---

## 六、Frequency (频率)

### frequency.cc
**路径**: `api/units/frequency.cc`

表示频率值 (如 "视频时钟 90kHz")。

**构造方法**:
```cpp
Frequency::Hertz(Hz)       // Hz
Frequency::KiloHertz(kHz)  // kHz
Frequency::MilliHertz(mHz) // mHz
```

**关键运算**:
```cpp
TimeDelta period = 1 / frequency;  // 频率 → 周期
```

**应用场景**: 时钟频率（RTP 时钟 90kHz、音频时钟 48kHz）、帧率 (30fps)

---

## 学习扩展

### 为什么要强类型单位？

**问题**: WebRTC 代码中存在大量时间/速率计算，单位混淆是常见 Bug 来源：
```cpp
// 容易出错:
int64_t rtt_ms = 50;
int64_t timeout_us = rtt_ms;  // BUG: 50us 而不是 50000us!

// 强类型版:
TimeDelta rtt = TimeDelta::Millis(50);
Timestamp timeout = now + rtt;  // 类型安全
```

### 编译期安全保障

```cpp
// 以下操作在编译期就会报错:
Timestamp t = TimeDelta::Seconds(1);         // Error: 不能隐式转换
DataRate r = DataSize::Bytes(1000);          // Error: 不同类型
Timestamp t2 = t + DataSize::Bytes(100);     // Error: 不兼容操作
```

### 关键设计模式

| 模式 | 说明 |
|------|------|
| **Value Object** | 不可变对象，按值传递 |
| **Strong Typedef** | 编译期区分语义相同但含义不同的类型 |
| **Dimension Analysis** | 类型系统中编码了量纲关系 |
