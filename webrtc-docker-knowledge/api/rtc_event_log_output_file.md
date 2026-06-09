# rtc_event_log_output_file

## 概述

`rtc_event_log_output_file.h` / `rtc_event_log_output_file.cc` 提供了 `RtcEventLogOutputFile` 类，实现了将 RTC 事件日志写入文件的输出端。它封装了 `FileWrapper`，支持限制文件大小的日志写入。

在 WebRTC 架构中，该文件位于 `api/` 层，是 `RtcEventLogOutput` 接口的文件实现，由 `PeerConnection::StartRtcEventLog()` 使用。

## 头文件接口 (.h)

### 类 `RtcEventLogOutputFile`

继承自 `RtcEventLogOutput`。

| 方法 | 说明 |
|------|------|
| `RtcEventLogOutputFile(file_name)` | 打开文件写入，无大小限制 |
| `RtcEventLogOutputFile(file_name, max_size_bytes)` | 打开文件，限制最大大小 |
| `RtcEventLogOutputFile(FILE*, max_size_bytes)` | 从已打开的 FILE* 写入，接管所有权 |
| `IsActive()` | 文件是否打开可用 |
| `Write(output)` | 写入日志数据（超限时关闭） |

常量：

| 常量 | 值 | 说明 |
|------|-----|------|
| `kMaxReasonableFileSize` | `max(size_t)/2` | 合理最大文件大小，防止 Write 溢出 |

## 实现文件 (.cc)

### 构造函数链
所有公开构造函数最终都委托到 `RtcEventLogOutputFile(FileWrapper file, size_t max_size_bytes)`：
1. 文件名构造：通过 `FileWrapper::OpenWriteOnly(file_name)` 获取 FileWrapper。
2. FILE* 构造：通过 `FileWrapper(file)` 包装。
3. 私有构造：`RTC_CHECK` 确保 `max_size_bytes <= kMaxReasonableFileSize`。

### Write 逻辑

```cpp
bool Write(absl::string_view output) {
  RTC_DCHECK(IsActiveInternal());
  RTC_DCHECK_LT(output.size(), kMaxReasonableFileSize);  // 单次写入不可过大

  if (max_size_bytes_ == kUnlimitedOutput ||
      written_bytes_ + output.size() <= max_size_bytes_) {
    if (file_.Write(output.data(), output.size())) {
      written_bytes_ += output.size();
      return true;
    }
    // 写入失败，记录错误
  } else {
    // 达到大小限制
  }
  file_.Close();  // 写入失败或超限后关闭
  return false;
}
```

### IsActiveInternal
检查 `file_.is_open()`，判断文件是否仍然有效。

## 学习扩展

- `kMaxReasonableFileSize` 设为 `max(size_t)/2` 是为了保证 `written_bytes_ + output.size()` 不会发生整数溢出。
- `RtcEventLog::kUnlimitedOutput` 是一个特殊值，表示不限制文件大小。
- `FileWrapper` 在 Windows 上会自动处理 UTF-8 到 `wchar` 的文件名转换。
- RTC Event Log 用于调试和分析 WebRTC 连接的内部行为，包含 RTP/RTCP 头部、ICE 事件、带宽估计等信息。

## 设计模式

**适配器模式 (Adapter)**：`RtcEventLogOutputFile` 将 `FileWrapper`（文件 I/O）适配为 `RtcEventLogOutput`（事件日志输出）接口。

**装饰器模式 (Decorator 变体)**：通过 `max_size_bytes_` 和 `written_bytes_` 在基本的文件写入能力之上添加了大小限制功能。
