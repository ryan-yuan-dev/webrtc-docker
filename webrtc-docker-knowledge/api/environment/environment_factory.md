# environment_factory

## 概述

`environment_factory` 模块提供了 `Environment` 对象的构建工厂。`Environment` 是 WebRTC 中用于聚合和传递公共工具（Utilities）的容器类，包括 FieldTrialsView（功能开关）、Clock（时钟）、TaskQueueFactory（任务队列工厂）、RtcEventLog（事件日志）四种核心工具。

`EnvironmentFactory` 采用 Builder 模式，允许调用方逐个设置工具，最终通过 `Create()` 方法生成不可变的 `Environment` 对象。未显式设置的工具会自动填充默认实现。

## 头文件接口 (.h)

### `EnvironmentFactory` 类

- **`EnvironmentFactory()`** — 默认构造函数，创建一个空工厂实例。
- **`explicit EnvironmentFactory(const Environment& env)`** — 从已有 Environment 构造工厂，继承其工具引用。
- **`Set()`（重载）** — 设置工具，接受四种类型的 unique_ptr 或原始指针版本。

  | 重载类型 | 参数 | 说明 |
  |---------|------|------|
  | `Set(unique_ptr<const FieldTrialsView>)` | 带所有权 | 设置 Field Trials |
  | `Set(unique_ptr<Clock>)` | 带所有权 | 设置时钟 |
  | `Set(unique_ptr<TaskQueueFactory>)` | 带所有权 | 设置任务队列工厂 |
  | `Set(unique_ptr<RtcEventLog>)` | 带所有权 | 设置事件日志 |
  | `Set(const FieldTrialsView*)` | 无所有权 | 设置 Field Trials |
  | `Set(Clock*)` | 无所有权 | 设置时钟 |
  | `Set(TaskQueueFactory*)` | 无所有权 | 设置任务队列工厂 |
  | `Set(RtcEventLog*)` | 无所有权 | 设置事件日志 |

- **`Create()`** — 生成 `Environment` 对象，自动填充未设置工具的默认实现。
- **`CreateWithDefaults()`** — 右值引用版本（`&&`），仅限内部使用。

### `CreateEnvironment()` 模板函数

便捷的变参辅助函数，等价于手动创建 `EnvironmentFactory`、依次调用 `Set`、最后调用 `Create`：

```cpp
// 示例
Environment env = CreateEnvironment(
    std::make_unique<MyTaskQueueFactory>(),
    std::make_unique<MyFieldTrials>()
);
```

`nullptr` 参数会被静默忽略，适用于多个来源提供同一工具时"后来的优先"的场景。

## 实现文件 (.cc)

### 存储管理：`StorageNode` 链表

**所有权管理（`Store` 模板函数）**:
- 对于带所有权的 `unique_ptr` 工具，`EnvironmentFactory` 不直接持有它们。
- 而是将每个工具包装在一个 `StorageNode` 中。`StorageNode` 继承自 `RefCountedBase`，是一个引用计数的节点。
- 节点之间形成链表（树状结构）：新节点的 `parent_` 指向上一个节点。
- `Environment` 和 `EnvironmentFactory` 只持有链表的"叶子"节点引用。

**所有权树结构**:
```
nullptr (根)
  └── StorageNode (field_trials)
        └── StorageNode (clock)
              └── StorageNode (task_queue_factory)  ← leaf_
```

### 默认实现填充 (`CreateWithDefaults`)

当相应工具未设置时自动使用以下默认值：

1. **FieldTrials** → `DeprecatedGlobalFieldTrials`（兼容旧版全局 field trials）。
2. **Clock** → `Clock::GetRealTimeClock()`（系统实时时钟）。
3. **TaskQueueFactory** → `CreateDefaultTaskQueueFactory()`（默认线程池实现）。
4. **RtcEventLog** → `RtcEventLogNull`（空日志实现）。

### 从已有 Environment 构建

`EnvironmentFactory(const Environment& env)` 构造函数拷贝源 Environment 中所有工具的指针和存储引用。这允许新创建的 Environment 与源共享一些工具（如时钟），同时替换另一些工具（如 field trials）。

## 学习扩展

- **引用计数所有权管理**: WebRTC 使用 `RefCountedBase` 和 `scoped_refptr` 来实现共享所有权，允许多个 `Environment` 对象安全地共享工具实例。
- **unique_ptr 与原始指针双接口**: `Set()` 方法提供两种重载，分别适配带所有权和不带所有权的使用场景，体现了 API 设计的灵活性。
- **变参模板 + 递归展开**: `CreateEnvironment` 使用 C++ 变参模板和递归展开技术遍历所有参数。

## 设计模式

- **Builder 模式** — `EnvironmentFactory` 通过链式 `Set` 调用逐步构建复杂对象，通过 `Create()` 生成最终产物。
- **工厂方法模式** — `CreateWithDefaults` 为未设置的依赖提供默认实现。
- **原型模式** — 支持从已有 `Environment` 创建新的工厂实例，克隆其配置。
- **空对象模式** — `RtcEventLogNull` 作为空实现，避免不必要的空指针检查。
