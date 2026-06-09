# video_decoder_factory_template_tests

## 概述

测试 `VideoDecoderFactoryTemplate` 模板类的正确性，包括单/多 TemplateAdapter 的格式注册、去重和编解码器创建。同时验证实际内置 Adapter（LibvpxVp8、LibvpxVp9、OpenH264、Dav1d）的集成。

## 测试用例

- `OneTemplateAdapterCreateDecoder`：单个 Adapter 注册并创建解码器。
- `TwoTemplateAdaptersNoDuplicates`：两个相同 Adapter 去重。
- `TwoTemplateAdaptersCreateDecoders`：两个不同 Adapter 注册不同格式。
- `LibvpxVp8/LibvpxVp9/OpenH264/Dav1d`：验证各内置 Adapter 的格式名称和创建能力。
