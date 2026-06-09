# audio_format

## 概述

`audio_format.h` 定义了三个核心数据结构，用于描述音频编码格式及其编解码能力：

1. **`SdpAudioFormat`**: SDP 协议中音频 codec 的描述，包含 codec 名称、时钟频率、声道数和参数键值对。
2. **`AudioCodecInfo`**: codec 实现的详细信息，包括采样率、声道数、默认/最小/最大码率，以及舒适噪声和网络自适应支持标志。
3. **`AudioCodecSpec`**: 将 `SdpAudioFormat` 和 `AudioCodecInfo` 组合在一起，完整描述一个 codec 的格式和实现信息。

这三个结构体是 WebRTC 音频 codec 管理的基础数据类型，贯穿 codec factory、SDP 协商、编码器/解码器创建的全流程。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/audio_format.h`

```cpp
// SDP 规范中的单个音频 codec 描述
struct RTC_EXPORT SdpAudioFormat {
  using Parameters = std::map<std::string, std::string>;  // 已废弃，使用 CodecParameterMap

  SdpAudioFormat(absl::string_view name, int clockrate_hz, size_t num_channels);
  SdpAudioFormat(absl::string_view name, int clockrate_hz, size_t num_channels,
                 const CodecParameterMap& param);

  bool Matches(const SdpAudioFormat& o) const;   // 兼容性检查（忽略参数）

  std::string name;                               // codec 名称（如 "opus", "PCMU"）
  int clockrate_hz;                               // 时钟频率
  size_t num_channels;                            // 声道数
  CodecParameterMap parameters;                   // SDP 参数（如 minptime, useinbandfec）
};

// Codec 实现信息
struct AudioCodecInfo {
  AudioCodecInfo(int sample_rate_hz, size_t num_channels, int bitrate_bps);
  AudioCodecInfo(int sample_rate_hz, size_t num_channels, int default_bitrate_bps,
                 int min_bitrate_bps, int max_bitrate_bps);

  bool HasFixedBitrate() const;                   // 是否固定码率

  int sample_rate_hz;
  size_t num_channels;
  int default_bitrate_bps;
  int min_bitrate_bps;
  int max_bitrate_bps;
  bool allow_comfort_noise = true;                // 是否支持外部舒适噪声
  bool supports_network_adaption = false;          // 是否支持网络自适应
};

// 组合格式和实现信息
struct AudioCodecSpec {
  SdpAudioFormat format;
  AudioCodecInfo info;
};
```

`SdpAudioFormat::Matches()` 与 `operator==` 的区别：
- `Matches()`: 只比较 `name`（忽略大小写）、`clockrate_hz` 和 `num_channels`，忽略 `parameters`。用于 SDP offer/answer 兼容性检查。
- `operator==`: 比较所有字段，包括 `parameters`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/audio_format.cc`

1. **`SdpAudioFormat`** 的四个构造函数：
   - 拷贝/移动构造函数为 `= default`。
   - 两个参数构造函数：一种不带 parameters（默认构造空 map），一种带 const reference parameters，一种带 move parameters。

2. **`Matches()` 实现**: 使用 `absl::EqualsIgnoreCase` 进行不区分大小写的 name 比较，然后比较 `clockrate_hz` 和 `num_channels`。

3. **`operator==`**: 除了 Matches 的内容外，额外比较 `parameters`。

4. **`AudioCodecInfo` 构造函数**:
   - 三参数版本（固定码率）：将所有三个码率值设为相同值，调用五参数版本。
   - 五参数版本：初始化所有字段并做 DCHECK 校验（采样率 > 0、声道数 > 0、min <= default <= max）。

## 学习扩展

- **CodecParameterMap**: `api/rtp_parameters.h` 中定义的 `std::map<std::string, std::string>` 别名。`SdpAudioFormat` 之前有自己的 `Parameters` 别名，已废弃。
- **SDP 参数示例**: Opus codec 的 SDP 参数常包含 `minptime=10`（最小包长 10ms）、`useinbandfec=1`（使用带内 FEC）、`stereo=1`（立体声）等。
- **舒适噪声 (Comfort Noise)**: `allow_comfort_noise` 标志表示该 codec 可以与外部舒适噪声生成器配合使用。DTX（不连续传输）场景中接收端需要生成舒适噪声。
- **`HasFixedBitrate()`**: 当 `min_bitrate_bps == max_bitrate_bps` 时返回 true，表示该 codec 使用固定码率（如 G711 始终为 64kbps）。

## 设计模式

- **值对象 (Value Object)**: 这三个结构体都是纯数据容器，提供值语义（可拷贝、可比较），不包含业务逻辑。
- **Builder 风格**: `AudioCodecInfo` 故意不提供带所有标志位的构造函数，而是通过公有成员变量设置，避免新增标志位时破坏现有代码。
- **适配器描述**: `SdpAudioFormat` 将 SDP 协议中的字符串描述映射为 WebRTC 内部数据类型；`AudioCodecInfo` 补充了实现细节；`AudioCodecSpec` 将两者组合为完整的 codec 描述。
