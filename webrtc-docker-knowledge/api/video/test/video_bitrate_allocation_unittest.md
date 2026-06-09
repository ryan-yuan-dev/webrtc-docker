# video_bitrate_allocation_unittest

## 概述

`VideoBitrateAllocation` 的单元测试，覆盖码率分配的核心功能：`SetBitrate` 和 `GetBitrate` 的正确性、`GetSpatialLayerSum` 求和、`IsSpatialLayerUsed` 判断、码率总和 `get_sum_bps()` 检验、超出上限拒绝、`operator==` 和 `operator!=` 比较、`ToString()` 序列化输出。
