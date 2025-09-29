## 镜像管理

- 构建镜像

  ```shell
  docker build -t webrtc-docker:latest .
  ```

- 查看所有镜像

  ```shell
  docker images
  # or
  docker image ls
  ```

- 删除镜像
  ```shell
  docker rmi 镜像id
  # or
  docker rmi 镜像名称:镜像标签
  ```

## 容器管理

- 启动容器

  ```shell
  # 启动一个挂载本地目录的交互式容器（适用于 Windows 系统）
  # --name webrtcdocker-01：将容器命名为 "webrtcdocker-01"
  # -v 参数：将主机目录挂载到容器内（可以多个 -v 挂载多个目录）
  #    - C:/Users/ryany/ryan-workspace/cpp-project/webrtc-docker/webrtc-workspace/webrtc：主机上的源目录
  #    - /workspace/webrtc：容器内的目标目录（需确保容器内此路径存在）
  # -it：开启交互式终端
  # bash：容器启动后执行 bash 命令
  docker run --name webrtcdocker-01 -v C:/Users/ryany/ryan-workspace/cpp-project/webrtc-docker/webrtc-workspace/webrtc:/workspace/webrtc -it webrtc-docker:latest bash
  ```

- 查看运行中的容器

  ```shell
  docker ps
  ```

- 查看所有容器
  ```shell
  docker ps -a
  ```
- 删除容器
  ```shell
  docker rm 容器id
  # or
  docker rm 容器名称
  ```
