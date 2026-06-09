# libaom_av1_encoder_factory_test

## 概述

全面测试 AV1 编码器的正确性，包括 SVC 层结构（L3T1、L3T1_KEY、S3T1）、空间层跳过、分辨率切换、多 spatial/temporal 混合编码、CQP/CBR 码率控制和编码质量验证。测试使用 libaom + dav1d 解码器实现编解码闭环验证。

## 测试用例

- `CodecName` / `CodecSpecifics` / `QpRange`：验证工厂信息。
- `KeyframeUpdatesSpecifiedBuffer`：验证关键帧更新指定缓冲区后的 PSNR。
- `MidTemporalUnitKeyframeResetsBuffers`：验证同一个 temporal unit 内关键帧重置缓冲区。
- `ResolutionSwitching` / `InputResolutionSwitching`：验证动态分辨率切换。
- `TempoSpatial`：验证混合 temporal+spatial SVC 编码。
- `SkipMidLayer`：验证跳过中间空间层。
- `L3T1` / `L3T1_KEY` / `S3T1`：验证三种 SVC 模式。
- `HigherEffortLevelYieldsHigherQualityFrames`：验证 effort level 越高 PSNR 越高。
- `KeyframeAndStartrameAreApproximatelyEqual`：验证 Keyframe 和 StartFrame 码率大致相等。
- `BitrateConsistentAcrossSpatialLayers`：验证各空间层 CBR 码率与目标接近。
- `ConstantQp`：验证 CQP 模式的 QP 精确性。
