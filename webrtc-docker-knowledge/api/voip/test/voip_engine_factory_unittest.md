# voip_engine_factory_unittest

## 概述

`voip_engine_factory_unittest` 对 `CreateVoipEngine()` 工厂函数进行单元测试。测试使用 mock 模块验证不同配置组合下引擎能否正确创建。

### 测试用例

| 测试 | 说明 |
|------|------|
| `CreateEngineWithMockModules` | 使用 mock 音频编码器、解码器、音频设备、音频处理模块创建引擎，验证返回非空指针 |
| `UseNoAudioProcessing` | 不设置 `audio_processing_builder` 创建引擎，验证在缺少音频处理的情况下引擎也能正常创建 |
