# create_simulcast_test_fixture

## 概述

创建 Simulcast 测试夹具（`SimulcastTestFixture`）的工厂函数，用于测试视频 Simulcast 编码功能和与解码器的交互。

## 头文件接口 (.h)

### 工厂函数

`CreateSimulcastTestFixture(encoder_factory, decoder_factory, video_format)`：

- `encoder_factory` — 视频编码器工厂
- `decoder_factory` — 视频解码器工厂
- `video_format` — SDP 视频格式

## 实现文件 (.cc)

- 创建 `SimulcastTestFixtureImpl` 实例（位于 `modules/video_coding/utility/`）。

## 设计模式

- **工厂方法模式** — 封装 Simulcast 测试夹具的创建。
