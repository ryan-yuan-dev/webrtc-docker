# create_peerconnection_quality_test_fixture

## 概述

创建 PeerConnection 端到端质量测试夹具（Fixture）的工厂函数。该夹具在 Alice 和 Bob 之间建立测试通话，支持音频和视频质量分析器。

## 头文件接口 (.h)

### 工厂函数

`CreatePeerConnectionE2EQualityTestFixture(test_case_name, time_controller, audio_quality_analyzer, video_quality_analyzer)`：

- `test_case_name` — 测试用例名称，用于所有指标报告
- `time_controller` — 时间控制器，管理所有 Thread 和 TaskQueue 实例
- `audio_quality_analyzer` — 音频质量分析器
- `video_quality_analyzer` — 视频质量分析器

返回 `PeerConnectionE2EQualityTestFixture` 实例。

## 实现文件 (.cc)

- 创建 `PeerConnectionE2EQualityTest` 实例（位于 `test/pc/e2e/`）。
- 传入 `test::GetGlobalMetricsLogger()` 作为全局指标记录器。

## 设计模式

- **工厂方法模式** — 封装了测试夹具的创建。
- **策略模式** — 允许注入不同的质量分析器策略。
