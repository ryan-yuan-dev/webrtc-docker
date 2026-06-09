# audio_decoder

## 概述

`AudioDecoder` 是 WebRTC AudioCoding 模块中所有音频解码器的抽象基类。定义了将编码后的音频数据包解码为 PCM 样本的标准接口。所有具体解码器（Opus、G711、G722、L16/PCM16B 等）都继承自该类。它支持传统的一次性解码方式（`Decode`/`DecodeRedundant`）以及更灵活的基于帧解析（`ParsePayload`/`EncodedAudioFrame`）的新接口。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/audio_decoder.h`

```cpp
class AudioDecoder {
 public:
  enum SpeechType { kSpeech = 1, kComfortNoise = 2 };
  enum { kNotImplemented = -2 };

  // --- 嵌套类: EncodedAudioFrame (帧级解码接口) ---
  class EncodedAudioFrame {
   public:
    struct DecodeResult { size_t num_decoded_samples; SpeechType speech_type; };
    virtual size_t Duration() const = 0;            // 返回帧的样本数
    virtual bool IsDtxPacket() const;               // DTX 检测
    virtual std::optional<DecodeResult> Decode(ArrayView<int16_t> decoded) const = 0;
  };

  // --- 嵌套类: ParseResult (解析结果) ---
  struct ParseResult {
    uint32_t timestamp;
    int priority;                                    // 优先级，0 最高
    std::unique_ptr<EncodedAudioFrame> frame;
  };

  // --- 核心接口 ---
  virtual std::vector<ParseResult> ParsePayload(Buffer&& payload, uint32_t timestamp);
  int Decode(const uint8_t* encoded, size_t encoded_len, int sample_rate_hz,
             size_t max_decoded_bytes, int16_t* decoded, SpeechType* speech_type);
  int DecodeRedundant(...);

  // --- PLC (Packet Loss Concealment) ---
  virtual bool HasDecodePlc() const;
  virtual size_t DecodePlc(size_t num_frames, int16_t* decoded);
  virtual void GeneratePlc(size_t requested_samples_per_channel,
                           BufferT<int16_t>* concealment_audio);

  virtual void Reset() = 0;                          // 重置解码器状态

  // --- Packet 分析 ---
  virtual int PacketDuration(...) const;
  virtual int PacketDurationRedundant(...) const;
  virtual bool PacketHasFec(...) const;

  virtual int SampleRateHz() const = 0;              // 输出采样率
  virtual size_t Channels() const = 0;               // 输出声道数

  static constexpr int kMaxNumberOfChannels = ...;   // 最大声道数

 protected:
  static SpeechType ConvertSpeechType(int16_t type);
  virtual int DecodeInternal(...) = 0;               // 子类实现的实际解码逻辑
  virtual int DecodeRedundantInternal(...);
};
```

接口演进：
- **新接口**: `ParsePayload()` + `EncodedAudioFrame`，支持帧解析、优先级排序、DTX 检测等。
- **旧接口**: `Decode()` + `DecodeRedundant()`，直接解码整个 payload。标注为过时但子类仍需实现 `DecodeInternal`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/audio_decoder.cc`

1. **`OldStyleEncodedFrame`**: 一个内部辅助类，将使用旧 `Decode()` 接口的解码器适配到新的 `EncodedAudioFrame` 接口。通过 `PacketDuration()` 获取帧长，通过 `Decode()` 执行实际解码。

2. **默认实现**:
   - `ParsePayload()`: 默认将整个 payload 包装为单个 `OldStyleEncodedFrame`，返回单元素 vector。
   - `Decode()`: 先检查缓冲区是否足够（`PacketDuration * Channels * sizeof(int16_t) > max_decoded_bytes`），然后调用 `DecodeInternal()`。
   - `DecodeRedundant()`: 类似 `Decode()`，但调用 `DecodeRedundantInternal()`（默认指向 `DecodeInternal`）。
   - `HasDecodePlc()`: 返回 false；`DecodePlc()`: 返回 0；`GeneratePlc()`: 空实现。
   - `PacketDuration()`: 返回 `kNotImplemented`。
   - `PacketHasFec()`: 返回 false。
   - `ErrorCode()`: 返回 0。

3. **`ConvertSpeechType()`**: 将从底层编解码器返回的整型 speech type（0/1/2）转换为 `SpeechType` 枚举，其中 0 和 1 对应 `kSpeech`，2 对应 `kComfortNoise`。

4. **TRACE_EVENT**: `Decode()` 和 `DecodeRedundant()` 都带有 `TRACE_EVENT0` 调用，用于性能追踪。

## 学习扩展

- **DecodePlc vs GeneratePlc**: `DecodePlc` 是基于帧数的 PLC，返回生成的样本数；`GeneratePlc` 是基于请求样本数的 PLC，输出到 `BufferT<int16_t>`。后者是新接口，旧实现将被删除（`TODO(bugs.webrtc.org/9676)`）。
- **kMaxNumberOfChannels**: 由 `kMaxNumberOfAudioChannels` 定义，当前值为 8。
- **MsanCheckInitialized**: 在 Decode 时使用 MemorySanitizer 检查输入是否已初始化，用于内存错误检测。

## 设计模式

- **模板方法模式 (Template Method)**: `Decode()` 是模板方法，定义了前置检查（缓冲区大小验证）和后置流程，将实际解码委托给子类实现的 `DecodeInternal()`。
- **适配器模式 (Adapter)**: `OldStyleEncodedFrame` 将旧的 `Decode` 接口适配到新的 `EncodedAudioFrame` 接口。
- **抽象基类 (Abstract Base Class)**: 定义了完整的解码器协议，子类只需实现少数纯虚函数。
