# create_videocodec_test_fixture

## 概述

创建视频编解码器测试夹具的工厂函数。用于测试单个视频编解码器（编码器+解码器对）的编解码性能和正确性。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateVideoCodecTestFixture(config)` | 使用默认编解码器工厂创建 |
| `CreateVideoCodecTestFixture(config, decoder_factory, encoder_factory)` | 使用自定义编解码器工厂创建 |

## 实现文件 (.cc)

- 两种版本都创建 `VideoCodecTestFixtureImpl` 实例（位于 `modules/video_coding/codecs/test/`）。
- 自定义工厂版本允许测试非默认的编解码器实现。

## 设计模式

- **工厂方法模式** — 封装测试夹具创建。
- **依赖注入** — 允许注入自定义的编码器/解码器工厂。
