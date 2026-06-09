# video_frame_metadata_unittest

## 概述

`VideoFrameMetadata` 的单元测试，验证元数据的完整 Set/Get 操作：帧类型、尺寸、旋转、内容类型、帧 ID、空间/时间索引、帧依赖、解码目标指示、最后一帧标志、Simulcast 索引、编解码器类型、编解码器特定信息（VP8/VP9/H264 variant）、SSRC/CSRC。同时验证 `operator==` 和 `operator!=` 的正确性。
