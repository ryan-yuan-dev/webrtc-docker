# create_video_quality_test_fixture

## 概述

创建视频质量测试夹具的工厂函数。创建 `VideoQualityTest` 实例，用于进行端到端视频质量测试。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateVideoQualityTestFixture(components)` | 新版，直接传值类型 `InjectionComponents` |
| `CreateVideoQualityTestFixture(unique_ptr<components>)` | 已废弃，传 unique_ptr 版本 |

`InjectionComponents` 允许注入自定义的编码器工厂和解码器工厂。

## 实现文件 (.cc)

- 两种版本都创建 `VideoQualityTest` 实例（位于 `video/`）。
- unique_ptr 版本解引用后委托给值版本。

## 设计模式

- **工厂方法模式** — 封装 `VideoQualityTest` 的创建。
