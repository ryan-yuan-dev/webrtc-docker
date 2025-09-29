# 准备工作

1. 将 webrtc 源码放入 `webrtc-workspace` 目录下；
2. 将 depot_tools 源码放入 `webrtc-workspace/depot_tools` 目录下；
3. 在 docker 中创建 webrtc 容器：
   ```bash
   # 从 webrtc-docker 镜像创建 webrtc 容器，挂在 webrtc-workspace 目录，对应容器的根目录为 /workspace/webrtc。
   # 容器启动后进入容器的 bash 终端，并跳转到 /workspace/webrtc 目录
   docker run -it --name webrtc -v $(pwd)/webrtc-workspace:/workspace/webrtc webrtc-docker /bin/bash
   ```
