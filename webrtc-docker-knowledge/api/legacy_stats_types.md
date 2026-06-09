# legacy_stats_types

## 概述

`legacy_stats_types.h` / `legacy_stats_types.cc` 定义了 WebRTC 的旧版统计报告系统，包括 `StatsReport`、`StatsCollection` 及其子类型。这套 API 对应 JavaScript 中基于回调的 `getStats()` API，提供了大量实现相关的统计指标，但正在被标准化的 `RTCStatsCollector` API 替代。

在 WebRTC 架构中，该文件位于 `api/` 层，标记为"维护模式"，不建议添加新指标。

## 头文件接口 (.h)

### 枚举 `StatsReport::StatsType`
统计报告类型：

| 值 | 说明 |
|----|------|
| `kStatsReportTypeSession` | 会话级信息 (googSession) |
| `kStatsReportTypeTransport` | 传输层信息 (googTransport) |
| `kStatsReportTypeComponent` | 通道组件（RTP 或 RTCP） |
| `kStatsReportTypeCandidatePair` | ICE 候选对 |
| `kStatsReportTypeBwe` | 视频带宽估计 (VideoBWE) |
| `kStatsReportTypeSsrc` | SSRC 流统计 |
| `kStatsReportTypeRemoteSsrc` | 远端 SSRC 统计 |
| `kStatsReportTypeTrack` | MediaStreamTrack 统计 |
| `kStatsReportTypeIceLocalCandidate` | 本地 ICE 候选 |
| `kStatsReportTypeIceRemoteCandidate` | 远端 ICE 候选 |
| `kStatsReportTypeCertificate` | SSL 证书信息 |
| `kStatsReportTypeDataChannel` | DataChannel 统计 |

### 枚举 `StatsReport::StatsValueName`
包含大量统计指标名称（共 100+），主要分为两大类：
- **标准指标**：`kStatsValueNameBytesSent/Received`、`kStatsValueNamePacketsLost`、`kStatsValueNameJitterBufferDelay`、`kStatsValueNameTotalAudioEnergy` 等
- **内部指标**（`goog` 前缀）：`kStatsValueNameAccelerateRate`、`kStatsValueNameDecodeMs`、`kStatsValueNameRtt`、`kStatsValueNameEchoReturnLoss` 等

### 类 `StatsReport::IdBase`（引用计数基类）
各类统计 ID 的基类，包含 `type()`、`Equals()`、`ToString()`。子类包括：
- `BandwidthEstimationId`：带宽估计统计 ID
- `TypedId` / `TypedIntId`：通用类型 ID
- `IdWithDirection`：带方向（发送/接收）的 ID
- `CandidateId`：候选 ID
- `ComponentId` / `CandidatePairId`：组件和候选对 ID

### 类 `StatsReport::Value`
表示单个统计值，支持多种类型：

| 成员 | 说明 |
|------|------|
| `name` | 统计指标名称 (`StatsValueName`) |
| `type` | 值类型（kInt/kInt64/kFloat/kString/kStaticString/kBool/kId） |
| `int_val()` / `int64_val()` / `float_val()` / `string_val()` / `bool_val()` / `id_val()` | 类型安全的取值方法 |
| `display_name()` | 指标名称的字符串表示 |
| `ToString()` | 值的字符串表示 |

### 类 `StatsReport`
单个统计报告：

| 方法 | 说明 |
|------|------|
| `id()` / `type()` / `timestamp()` | 报告标识和元数据 |
| `AddString()` / `AddInt64()` / `AddInt()` / `AddFloat()` / `AddBoolean()` / `AddId()` | 添加统计值 |
| `FindValue(name)` | 按名称查找统计值 |
| `values()` | 获取所有值的只读 map |

### 类 `StatsCollection`
统计报告集合：

| 方法 | 说明 |
|------|------|
| `InsertNew(id)` | 插入新报告（不可重复） |
| `FindOrAddNew(id)` | 查找或创建 |
| `ReplaceOrAddNew(id)` | 替换或添加 |
| `Find(id)` | 按 ID 查找 |
| `DetachCollection()` / `MergeCollection()` | 集合的分离与合并 |

## 实现文件 (.cc)

### InternalTypeToString
将 `StatsType` 映射为字符串，如 `kStatsReportTypeBwe` -> `"VideoBwe"`。

### Value 构造函数
根据类型构造 union 中的值，支持七种类型。

### Value 析构函数
根据 `type_` 决定是否需要释放内存（kString 删除 `string*`，kId 删除 `Id*`）。

### display_name 实现
巨大的 switch 语句将每个 `StatsValueName` 映射为标准字符串名称，兼容 W3C Stats 规范命名。

### 统计报告工厂方法
- `NewBandwidthEstimationId()` -> `BandwidthEstimationId`
- `NewTypedId(type, id)` -> `TypedId`
- `NewTypedIntId(type, id)` -> `TypedIntId`
- `NewIdWithDirection(type, id, direction)` -> `IdWithDirection`
- `NewCandidateId(local, id)` -> `CandidateId`
- `NewComponentId(content_name, component)` -> `ComponentId`
- `NewCandidatePairId(content_name, component, index)` -> `CandidatePairId`

### StatsReport::Add 方法
每个 Add 方法在添加前先检查是否存在相同值的旧条目，仅在不同时才替换，避免不必要的内存操作。

### StatsCollection::MergeCollection
合并集合时，对于 ID 相同的报告执行替换操作，确保线程检查器的正确附加/分离。

## 学习扩展

- 此旧版统计系统已标记为"维护模式"，建议新代码使用 `api/stats/` 下的标准化 RTCStats API。
- `kStatsValueName` 使用 `goog` 前缀标记内部统计指标，这些不在 W3C 标准中定义。
- `Value` 类使用手动引用计数而非 `RefCountInterface`，且要求修改必须在 signaling thread 上进行。
- 很多 `goog` 前缀的值是从 libjingle (Google Talk) 时代遗留下来的命名。

## 设计模式

**类型安全的联合体 (Tagged Union)**：`Value` 使用 `union` 存储不同类型的值，通过 `type_` 枚举标记当前活跃类型。

**工厂方法 (Factory Method)**：多个 `New*Id()` 静态工厂方法创建不同类型的 `Id` 对象。

**组合模式 (Composite)**：`StatsCollection` 组合多个 `StatsReport`，提供集合级别的操作能力。

**不可变对象 (Immutable Object)**：`Value` 使用引用计数管理，但创建后不提供修改方法。
