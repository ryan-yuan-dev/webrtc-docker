# video_encoder_factory_template_tests

## 概述

测试 `VideoEncoderFactoryTemplate` 模板类的正确性，包括单/多 TemplateAdapter 的格式注册、去重、编解码器创建、`QueryCodecSupport` 可伸缩性模式支持检测。同时验证实际内置 Adapter（LibvpxVp8、LibvpxVp9、OpenH264、LibaomAv1）的集成。

## 测试用例

- `OneTemplateAdapterCreateEncoder` / `OneTemplateAdapterCodecSupport`：单个 Adapter 的运行。
- `TwoTemplateAdaptersNoDuplicates` / `TwoTemplateAdaptersCreateEncoders` / `TwoTemplateAdaptersCodecSupport`：双 Adapter 的格式合并和去重。
- `LibvpxVp8` / `LibvpxVp9` / `OpenH264` / `LibaomAv1`：验证各内置 Adapter 的格式名称和可伸缩性模式支持。
