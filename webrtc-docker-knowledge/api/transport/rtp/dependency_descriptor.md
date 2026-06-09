# dependency_descriptor

## 概述

`dependency_descriptor.h` / `dependency_descriptor.cc` 定义了视频帧依赖描述符 (Dependency Descriptor) 的数据结构。该结构遵循 AV1 RTP 规格 (https://aomediacodec.github.io/av1-rtp-spec/#dependency-descriptor-rtp-header-extension)，作为 RTP 头扩展用于描述视频帧之间的解码依赖关系。

依赖描述符替代了传统的 Frame Marking RTP 头扩展，提供更灵活和精细的帧依赖描述能力，使 SFU (Selective Forwarding Unit) 可以在不解析码流的情况下做出准确的帧丢弃决策。

## 头文件接口 (.h)

**文件**: `api/transport/rtp/dependency_descriptor.h`

### DecodeTargetIndication (枚举)

```cpp
enum class DecodeTargetIndication {
  kNotPresent = 0,   // '-' 该帧不是解码目标的组成部分
  kDiscardable = 1,  // 'D' 该帧可以被丢弃而不影响该目标
  kSwitch = 2,       // 'S' 该帧是该目标的切换点
  kRequired = 3      // 'R' 该帧是该目标解码所必需的
};
```

这四种指示值对应 AV1 RTP 规格中的符号表示：`-`, `D`, `S`, `R`。

### FrameDependencyTemplate (帧依赖模板)

```cpp
struct FrameDependencyTemplate {
  FrameDependencyTemplate& S(int spatial_layer);    // 设置 spatial_id
  FrameDependencyTemplate& T(int temporal_layer);   // 设置 temporal_id
  FrameDependencyTemplate& Dtis(absl::string_view dtis);  // 解析字符串设置 DTIs
  FrameDependencyTemplate& FrameDiffs(std::initializer_list<int> diffs);  // 帧差异
  FrameDependencyTemplate& ChainDiffs(std::initializer_list<int> diffs);  // 链差异

  int spatial_id = 0;
  int temporal_id = 0;
  InlinedVector<DecodeTargetIndication, 10> decode_target_indications;
  InlinedVector<int, 4> frame_diffs;   // 依赖的帧（相对于当前帧的差异值）
  InlinedVector<int, 4> chain_diffs;   // 可丢弃链差异值
};
```

- **Spatial Layer (空间层)**: 不同分辨率的视频层，如 S0(低清) + S1(高清)
- **Temporal Layer (时间层)**: 不同帧率的子流，如 T0(基础帧率) + T1(增强帧率)
- **DTIs**: 每个解码目标的指示，如 "-R--" 表示只有第二个解码目标需要该帧
- **Frame Diffs**: 当前帧依赖的帧（如依赖前 1 帧即为 [1]）
- **Chain Diffs**: 每条可丢弃链的帧差异

### FrameDependencyStructure (帧依赖结构)

```cpp
struct FrameDependencyStructure {
  int structure_id = 0;
  int num_decode_targets = 0;  // 解码目标数量
  int num_chains = 0;          // 可丢弃链数量
  InlinedVector<int, 10> decode_target_protected_by_chain;  // 目标→链映射
  InlinedVector<RenderResolution, 4> resolutions;           // 各空间层分辨率
  std::vector<FrameDependencyTemplate> templates;           // 模板列表（最大 64 个）
};
```

- `structure_id`: 结构标识，用于引用更新
- `decode_target_protected_by_chain`: 每条链保护对应的解码目标
- `resolutions`: 每个空间层的渲染分辨率
- `templates`: 最多 64 个依赖模板

### DependencyDescriptorMandatory

```cpp
class DependencyDescriptorMandatory {
 public:
  void set_frame_number(int frame_number);
  int frame_number() const;
  void set_template_id(int template_id);
  int template_id() const;
  void set_first_packet_in_frame(bool first);
  bool first_packet_in_frame() const;
  void set_last_packet_in_frame(bool last);
  bool last_packet_in_frame() const;
};
```

包含必须的帧级别信息：帧号、模板 ID、首/末包标志。

### DependencyDescriptor

```cpp
struct DependencyDescriptor {
  static constexpr int kMaxSpatialIds = 4;
  static constexpr int kMaxTemporalIds = 8;
  static constexpr int kMaxDecodeTargets = 32;
  static constexpr int kMaxTemplates = 64;

  bool first_packet_in_frame = true;
  bool last_packet_in_frame = true;
  int frame_number = 0;
  FrameDependencyTemplate frame_dependencies;
  std::optional<RenderResolution> resolution;
  std::optional<uint32_t> active_decode_targets_bitmask;
  std::unique_ptr<FrameDependencyStructure> attached_structure;
};
```

- `frame_dependencies`: 当前帧的依赖信息
- `resolution`: 当前帧分辨率（可选，仅在分辨率变化时携带）
- `active_decode_targets_bitmask`: 活跃解码目标位掩码
- `attached_structure`: 附带的依赖结构定义（仅在模板更新时携带）

### 辅助函数

```cpp
namespace webrtc_impl {
InlinedVector<DecodeTargetIndication, 10> StringToDecodeTargetIndications(
    absl::string_view indication_symbols);
}
```

## 实现文件 (.cc)

**文件**: `api/transport/rtp/dependency_descriptor.cc`

### StringToDecodeTargetIndications

将字符串形式的 DTI 指示转换为枚举数组：

```cpp
InlinedVector<DecodeTargetIndication, 10> StringToDecodeTargetIndications(
    absl::string_view symbols) {
  for (char symbol : symbols) {
    switch (symbol) {
      case '-': indication = DecodeTargetIndication::kNotPresent; break;
      case 'D': indication = DecodeTargetIndication::kDiscardable; break;
      case 'R': indication = DecodeTargetIndication::kRequired; break;
      case 'S': indication = DecodeTargetIndication::kSwitch; break;
    }
  }
}
```

### FrameDependencyTemplate 链式 setter

```cpp
inline FrameDependencyTemplate& FrameDependencyTemplate::S(int spatial_layer);
inline FrameDependencyTemplate& FrameDependencyTemplate::T(int temporal_layer);
inline FrameDependencyTemplate& FrameDependencyTemplate::Dtis(absl::string_view dtis);
inline FrameDependencyTemplate& FrameDependencyTemplate::FrameDiffs(std::initializer_list<int> diffs);
inline FrameDependencyTemplate& FrameDependencyTemplate::ChainDiffs(std::initializer_list<int> diffs);
```

这些 setter 被定义为内联函数以支持链式构建模板：
```cpp
templates.push_back(
    FrameDependencyTemplate()
        .S(0).T(0).Dtis("SS").FrameDiffs({2, 4}).ChainDiffs({2}));
```

## 学习扩展

### SVC (Scalable Video Coding) 和层次结构

依赖描述符的核心是描述 SVC 编码的帧依赖关系：

```
Temporal Layer 结构示例 (3 层):

T2: I--I--I--I--I--I--I--I--  (帧率: 完整)
T1: -P----P----P----P----P---  (帧率: 二分之一)
T0: --K----K----K----K----K--  (帧率: 四分之一)

箭头表示依赖关系 (K 依赖 I, P 依赖 K 或 I)
```

### SFU 的帧丢弃决策

SFU 依赖 Dependency Descriptor 做智能转发决策：

```
场景: 带宽不足，需要丢弃 T2 帧

SFU 检查:
  T2 帧的 DecodeTargetIndication 是 "D" (Discardable)
  → 丢弃 T2 帧不会影响 T0/T1 层的解码

不支持的场景:
  如果 T1 帧标记为 "R" 但依赖的 T0 帧被丢弃
  → 解码失败，接收端会报错
```

### Dependency Descriptor 与 Frame Marking 的对比

| 特性 | Dependency Descriptor | Frame Marking |
|------|----------------------|---------------|
| 空间/时间层支持 | 任意层次结构 | 固定层次 |
| 可丢弃链 | 支持多条链 | 不支持 |
| 解码目标 | 最多 32 个 | 有限 |
| 模板机制 | 通过模板减少重复 | 无模板 |
| SFU 友好度 | 高 - 精确描述依赖 | 中等 |

### 使用场景

依赖描述符在以下场景中特别重要：
- **Simulcast + SVC**: 多流多层的复杂依赖关系
- **自适应码率转发**: SFU 需要根据带宽动态调整转发策略
- **视频会议**: 参会者可能需要不同质量等级的视频流

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Fluent Interface (Builder)** | `FrameDependencyTemplate::S().T().Dtis().FrameDiffs().ChainDiffs()` | 链式调用构建依赖模板 |
| **Composite** | `DependencyDescriptor` 包含 `FrameDependencyTemplate` | 帧描述符聚合依赖模板信息 |
| **Template Pattern** | `FrameDependencyStructure` + `FrameDependencyTemplate` | 模板定义帧结构，帧描述符引用模板 |
