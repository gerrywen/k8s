# 安装 Istio

### 下载 Istio

1.访问 [Istio release](https://github.com/istio/istio/releases/tag/1.6.1) 页面下载与您操作系统对应的安装文件

```shell
$ wget https://github.com/istio/istio/releases/download/1.6.1/istio-1.6.1-linux-amd64.tar.gz
```

```shell
$ tar zxvf istio-1.6.1-linux-amd64.tar.gz 
```

2.切换到 Istio 包所在目录下。例如：Istio 包名为 `istio-1.6.1`，则：

```shell
$ cd istio-1.6.1
```

3.将 `istioctl` 客户端路径增加到 path 环境变量中

```shell
$ export PATH=$PWD/bin:$PATH
```

4.在使用 bash 或 ZSH 控制台时，可以选择启动 [auto-completion option](https://istio.io/zh/docs/ops/diagnostic-tools/istioctl#enabling-auto-completion)。

```shell
vi /etc/profile
```

```shell
# set istio
export ISTIO=/root/istio/istio-1.6.1
export PATH=$PATH:$ISTIO/bin::$ISTIO/tools
```



### [使用 Istioctl 安装](https://istio.io/zh/docs/setup/install/istioctl/)

1.导入`istio-basic.images`文件夹镜像

```shell
docker load i xxx.tar
```

https://github.com/istio/istio/issues/22463







您可以在安装 Istio 之前使用 `manifest generate` 子命令生成清单，而不是 `manifest apply`。 例如，使用以下命令为 `default` 配置文件生成清单：

```shell
istioctl manifest generate > ./generated-manifest.yaml
```





1.kubernetes 强制删除istio-system空间,强制删除pod

```shell
kubectl delete ns istio-system --grace-period=0 --force
```







