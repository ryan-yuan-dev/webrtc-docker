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
  docker run --name webrtc-docker-02 -it webrtc-docker:latest bash
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