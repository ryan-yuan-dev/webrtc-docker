# create_time_controller

## 概述

创建模拟时间控制器（`SimulatedTimeController`）的工厂函数。模拟时间控制器在使用模拟时间的测试中使用，时间可以从初始值（Unix 纪元后 10000 秒）开始快速推进。

## 头文件接口 (.h)

### 工厂函数

`CreateSimulatedTimeController()` — 返回一个在模拟时间模式下运行的 `TimeController`。

## 实现文件 (.cc)

- 创建 `GlobalSimulatedTimeController`，初始时间戳为 `Timestamp::Seconds(10000)`。
- 初始时间设置是为了避免测试中的时间零值问题。

## 学习扩展

- **GlobalSimulatedTimeController**: 全局模拟时间控制器，通过控制所有线程和任务队列的时间推进，实现确定性测试执行。

## 设计模式

- **工厂方法模式** — 封装模拟时间控制器的创建。
