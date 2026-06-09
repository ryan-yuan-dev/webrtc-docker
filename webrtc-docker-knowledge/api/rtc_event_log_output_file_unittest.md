# rtc_event_log_output_file_unittest

## 概述

`rtc_event_log_output_file_unittest.cc` 是对 `api/rtc_event_log_output_file.h` 中 `RtcEventLogOutputFile` 类的单元测试文件。

## 测试范围

- 文件创建和打开
- `IsActive()` 状态检查
- `Write()` 写入操作
- 文件大小限制行为（超出限制后写入失败并关闭）
- 无效文件的创建
- 写入空数据
- 大文件回转测试
- 文件关闭后的状态
