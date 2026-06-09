# scalability_mode_helper

## 概述

`scalability_mode_helper` 提供字符串形式的 Scalability Mode 到层数信息的辅助转换功能。它将字符串标识符（如 `"L2T3"`）解析为空间层数和时间层数，或者直接转换为 `ScalabilityMode` 枚举值。该模块依赖于 `modules/video_coding/svc/scalability_mode_util.h` 中的实际转换逻辑，是对底层工具的 API 边界封装。

## 头文件接口 (.h)

**核心函数**：
- `ScalabilityModeStringToNumSpatialLayers(string_view)`：返回字符串表示的可伸缩性模式中的空间层数。
- `ScalabilityModeStringToNumTemporalLayers(string_view)`：返回时间层数。
- `ScalabilityModeStringToEnum(string_view)`：将字符串转换为 `ScalabilityMode` 枚举。

所有函数在遇到未知模式时返回 `nullopt`。

## 实现文件 (.cc)

- 三个函数均委托给 `modules/video_coding/svc/scalability_mode_util.h` 中定义的底层工具函数：
  - `ScalabilityModeFromString`：字符串转枚举。
  - `ScalabilityModeToNumSpatialLayers`：枚举转空间层数。
  - `ScalabilityModeToNumTemporalLayers`：枚举转时间层数。
- 该模块作为公共 API 的边界，隐藏了底层 `modules/video_coding/svc/` 的实现细节。

## 学习扩展

- 此模块的存在体现了 WebRTC 的分层设计：`api/` 层只暴露高层接口，具体实现在 `modules/` 层。
- `modules/video_coding/svc/scalability_mode_util.h` 中的 `ScalabilityModeFromString` 通过解析字符串中的 `L`/`S`、数字和 `h`/`_KEY` 后缀来确定模式参数。
- 空间层数和时间层数是 SVC 编码中最重要的两个维度，直接影响编码器的架构和码率分配策略。

## 设计模式

**外观模式（Facade）**：本模块作为底层 `scalability_mode_util` 功能的简化外观，为 API 层提供更易用的接口，屏蔽内部实现细节。函数命名也更直观（`NumSpatialLayers` 而非模糊的辅助函数名）。
