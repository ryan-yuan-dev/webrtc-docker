# WebRTC 其他模块 API 文档

本文件涵盖 `api/` 下的其余小型模块。

---

## 一、crypto/ — 加密选项

### crypto_options.cc
**路径**: `api/crypto/crypto_options.cc`
**关键类**: `CryptoOptions`

DTLS-SRTP 的加密配置选项：
- `srtp` — SRTP (Secure RTP) 加密套件选择
  - `enable_gcm_crypto_suites` — 是否启用 AES-GCM 加密套件
  - `enable_aes128_sha1_*_crypto_suites` — 是否启用 AES-128-SHA1 系列
  - `enable_encrypted_rtp_header_extensions` — 是否加密 RTP 头扩展
- `sframe` — SFrame (Selective Forwarding Frame Encryption) 选项
  - `require_frame_encryption` — 端到端加密要求

**重要**: `enable_encrypted_rtp_header_extensions == false` 是默认值——这意味着 RTP 头扩展（如客户-服务器头的 abs-send-time）默认不加密，以允许 SFU 访问。

---

## 二、environment/ — 环境工厂

### environment_factory.cc
**路径**: `api/environment/environment_factory.cc`
**关键类**: `Environment`, `EnvironmentFactory`

`Environment` 是 WebRTC 的依赖注入容器——它将全局服务（如 FieldTrials、Clock、TaskQueueFactory）打包为一个统一入口，使依赖关系显式化。

**创建**:
```cpp
auto env = CreateEnvironment(std::move(field_trials));
auto env_with_custom_clock = CreateEnvironment(std::move(field_trials),
                                                std::make_unique<SimulatedClock>(start_time));
```

**Environment 提供的服务**:
- `field_trials()` — 特性开关
- `clock()` — 时钟接口
- `task_queue_factory()` — 任务队列工厂

**目标**: 替代全局状态的依赖注入容器——使测试更容易（可注入 SimulatedClock）。

### deprecated_global_field_trials.cc
**路径**: `api/environment/deprecated_global_field_trials.cc`

全局 `FieldTrialsView` 的遗留兼容代码。标记为 deprecated——新代码应使用 `Environment` 注入。

---

## 三、neteq/ — 网络均衡器

### neteq.cc, default_neteq_factory.cc, custom_neteq_factory.cc
**路径**: `api/neteq/`

**NetEQ** 是 WebRTC 的抖动缓冲和丢包隐藏 (PLC) 模块。

**核心接口**:
- `NetEq` — 主接口：插入 RTP 包、获取解码音频、获取统计信息
- `NetEqFactory` — 创建 NetEq 实例的工厂
- `DefaultNetEqControllerFactory` — 默认控制器工厂
- `CustomNetEqControllerFactory` — 自定义控制器工厂（允许注入决策逻辑）

**tick_timer.cc**: NetEq 的定时器抽象，用于驱动解码和 PLC 的时序。

**NetEQ 的作用**:
1. **抖动缓冲**: 吸收网络延迟变化
2. **加速/减速播放**: 当缓冲区过满/过空时调整播放速度
3. **丢包隐藏 (PLC)**: 生成替代音频隐藏丢失的包
4. **合并 (Merge)**: 在无丢包时补偿延迟变化

---

## 四、numerics/ — 数值统计

### samples_stats_counter.cc
**路径**: `api/numerics/samples_stats_counter.cc`
**关键类**: `SamplesStatsCounter`

线程安全的样本统计计算器。支持：
- `AddSample(value)` — 添加样本
- `GetStats()` — 获取统计摘要
- 计算: 平均值、方差、标准差、最小值、最大值、样本数
- O(1) 均值和方差更新（Welford 算法）

---

## 五、rtc_event_log/ — 事件日志

### rtc_event.cc, rtc_event_log.cc, rtc_event_log_factory.cc
**路径**: `api/rtc_event_log/`

RTC 事件日志记录 WebRTC 运行时的关键事件，用于调试和问题分析。

- `RtcEvent` — 事件基类（时间戳 + 类型）
- `RtcEventLog` — 日志记录接口 (StartLogging/StopLogging)
- `RtcEventLogFactory` — 日志工厂

---

## 六、call/ — 呼叫传输

### transport.cc
**路径**: `api/call/transport.cc`
**关键接口**: `Transport`

P2P 传输抽象——将 RTP/RTCP 包发送到网络。PeerConnection 内部使用此接口与实际网络层交互。

---

## 七、adaptation/ — 自适应资源

### resource.cc
**路径**: `api/adaptation/resource.cc`
**关键类**: `Resource`

资源管理抽象——当资源稀缺时（如 CPU 过载），触发视频自适应（降分辨率/降帧率）。

---

## 八、metronome/ — 节拍器

### metronome/test/fake_metronome.cc
**路径**: `api/metronome/test/fake_metronome.cc`

节拍器提供定时 tick 用于驱动编码器帧率。FakeMetronome 用于测试。

---

## 九、voip/ — VoIP 引擎

### voip_engine_factory.cc
**路径**: `api/voip/voip_engine_factory.cc`

轻量级 VoIP 引擎的工厂——为 VoIP 场景提供简化的 API（不需要完整的 PeerConnection）。

---

## 十、test/ — 测试工具

### test/ 目录概览
**路径**: `api/test/`

测试基础设施，包含：

**帧生成器**:
- `create_frame_generator.cc` / `frame_generator_interface.cc` — 生成测试用视频帧
- `create_peer_connection_quality_test_frame_generator.cc` — 质量测试帧生成器

**网络仿真**:
- `create_network_emulation_manager.cc` / `network_emulation_manager.cc` — 网络损伤仿真
- `network_emulation/` — 多种网络队列模型:
  - `leaky_bucket_network_queue.cc` — 漏桶流量整形
  - `dual_pi2_network_queue.cc` — Dual-PI² AQM 队列
  - `ecn_marking_counter.cc` — ECN 标记计数
  - `schedulable_network_node_builder.cc` — 网络节点构建器

**质量测试**:
- `create_peerconnection_quality_test_fixture.cc` — PeerConnection 质量测试框架
- `create_video_quality_test_fixture.cc` — 视频质量测试
- `create_videocodec_test_fixture.cc` — 编解码器测试
- `create_simulcast_test_fixture.cc` — Simulcast 测试

**度量指标** (`test/metrics/`):
- `metrics_logger.cc` — 度量日志记录器
- `metrics_accumulator.cc` — 度量累加器（支持平均值/百分位数/标准差）
- `chrome_perf_dashboard_metrics_exporter.cc` — Chrome 性能面板导出
- `print_result_proxy_metrics_exporter.cc` — 结果打印代理
- `stdout_metrics_exporter.cc` — 标准输出导出

**时间控制**:
- `create_time_controller.cc` / `time_controller.cc` — 仿真时间控制（加速测试）

**PCLF (PeerConnection Level Framework)** (`test/pclf/`):
- `media_configuration.cc` — 媒体配置（音频/视频流参数）
- `peer_configurer.cc` — Peer 配置器

**帧加密测试**:
- `fake_frame_encryptor.cc` / `fake_frame_decryptor.cc` — 端到端加密测试桩
