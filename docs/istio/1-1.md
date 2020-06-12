# 安装 Istio

## 下载 Istio

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



## [使用 Istioctl 安装](https://istio.io/zh/docs/setup/install/istioctl/)

#### 1.导入`istio-basic.images`文件夹镜像

```shell
docker load i xxx.tar
```



#### 2.使用默认配置文件安装 Istio

最简单的选择是安装 `default` Istio [配置文件](https://istio.io/zh/docs/setup/additional-setup/config-profiles/)使用以下命令：

```shell
$ istioctl install
```

此命令将在您配置的 Kubernetes 集群上安装 `default` 配置文件。 `default` 配置文件建立生产环境的良好起点，这与旨在评估广泛的 Istio 功能特性的较大的 `demo` 配置文件不同。

如果要在 `default` 配置文件之上启用 Grafana dashboard，用下面的命令设置 `addonComponents.grafana.enabled` 配置参数：

```shell
$ istioctl install --set addonComponents.grafana.enabled=true
```

通常，您可以像使用 [helm](https://istio.io/zh/docs/setup/install/helm/) 一样在 `istioctl` 中配置 `--set` 标志。 唯一的区别是必须为配置路径增加 `values.` 前缀，因为这是 Helm 透传 API 的路径，如下所述。



#### 3.安装其他配置文件

- ##### 3.1 显示可用配置文件的列表

  您可以使用以下 `istioctl` 命令来列出 Istio 配置文件名称：

  ```shell
  $ istioctl profile list
  ```

  ```shell
  [root@k8s-master01 charts]# istioctl profile list
  Istio configuration profiles:
      empty
      minimal
      preview
      remote
      default
      demo
  ```

- ##### 3.2 安装内置配置

  1. **default**: 根据默认的[安装选项](https://istio.io/zh/docs/reference/config/installation-options/)启用组件 (建议用于生产部署)。

  2. **demo**: 这一配置具有适度的资源需求，旨在展示 Istio 的功能。它适合运行 [Bookinfo](https://istio.io/zh/docs/examples/bookinfo/) 应用程序和相关任务。 这是通过[快速开始](https://istio.io/zh/docs/setup/getting-started/)指导安装的配置，但是您以后可以通过[自定义配置](https://istio.io/zh/docs/setup/install/istioctl/#customizing-the-configuration) 启用其他功能来探索更高级的任务。

     > `此配置文件启用了高级别的追踪和访问日志，因此不适合进行性能测试。`

  3. **minimal**: 使用 Istio 的[流量管理](https://istio.io/zh/docs/tasks/traffic-management/)功能所需的最少组件集。

  4. **sds**: 和 **default** 配置类似，但是启用了 Istio 的 SDS (secret discovery service) 功能。 这个配置文件默认启用了附带的认证功能 (Strict Mutual TLS)。

  下表中标记为 **X** 的组件就是包含在配置文件里的内容:

  | default                  | demo | minimal | sds  |      |
  | ------------------------ | ---- | ------- | ---- | ---- |
  | 核心组件                 |      |         |      |      |
  | `istio-citadel`          | X    | X       |      | X    |
  | `istio-egressgateway`    |      | X       |      |      |
  | `istio-galley`           | X    | X       |      | X    |
  | `istio-ingressgateway`   | X    | X       |      | X    |
  | `istio-nodeagent`        |      |         |      | X    |
  | `istio-pilot`            | X    | X       | X    | X    |
  | `istio-policy`           | X    | X       |      | X    |
  | `istio-sidecar-injector` | X    | X       |      | X    |
  | `istio-telemetry`        | X    | X       |      | X    |
  | 插件                     |      |         |      |      |
  | `grafana`                |      | X       |      |      |
  | `istio-tracing`          |      | X       |      |      |
  | `kiali`                  |      | X       |      |      |
  | `prometheus`             | X    | X       |      | X    |

- ##### 3.3 安装其他配置文件(推荐这种方式安装)

  可以通过在命令行上设置配置文件名称安装其他 Istio 配置文件到群集中。 例如，可以使用以下命令，安装 `demo` 配置文件：

  ```shell
  $ istioctl install --set profile=demo
  ```

  为default命名空间添加istio-injection=enabled标签，开启自动 sidecar 注入

  ```shell
  $ kubectl label namespace default istio-injection=enabled
  ```

  ##### 不知道哪里出问题，一直出现prometheus的istio/proxyv2:1.6.1 探针问题503，这边手动操作把探针删除

  - 查看istio-system空间下的prometheus

    ```shell
    $ kubectl get deployment -n istio-system 
    ```

  - 修改prometheus

    ```shell
    $ kubectl edit deployment -n istio-system prometheus
    ```

  - 去掉istio/proxyv2:1.6.1镜像以下的两段

    ```yaml
    imagePullPolicy: Always
    ```

    ```yaml
            readinessProbe:
              failureThreshold: 30
              httpGet:
                path: /healthz/ready
                port: 15021
                scheme: HTTP
              initialDelaySeconds: 1
              periodSeconds: 2
              successThreshold: 1
              timeoutSeconds: 1
    ```

  - 查看 rs ，删除READY的为0的prometheus

    ```shell
    $ kubectl get rs -n istio-system
    ```

    ```shell
    NAME                             DESIRED   CURRENT   READY   AGE
    grafana-75745787f9               1         1         1       10m
    istio-egressgateway-794db4db55   1         1         1       10m
    istio-ingressgateway-799b86d9    1         1         1       10m
    istio-tracing-c7b59f68f          1         1         1       10m
    istiod-55fff4d845                1         1         1       11m
    kiali-85dc7cdc48                 1         1         1       10m
    prometheus-bbf8f7b7              1         1         1       10m
    prometheus-8685fb8c59            1         1         0       10m
    ```

    ```shell
    $ kubectl delete rs -n istio-system prometheus-8685fb8c59 
    ```

    

  - 查看 pod，删除STATUS的为Terminating的prometheus

    ```shell
    $ kubectl get pod -n istio-system
    ```

    ```shell
    [root@k8s-master01 istio-1.6.1]# kubectl get pod -n istio-system
    NAME                                   READY   STATUS        RESTARTS   AGE
    grafana-75745787f9-j4t7f               1/1     Running       0          2m24s
    istio-egressgateway-794db4db55-zkz2m   0/1     Running       0          2m25s
    istio-ingressgateway-799b86d9-qh5gt    0/1     Running       0          2m24s
    istio-tracing-c7b59f68f-62q4d          1/1     Running       0          2m24s
    istiod-55fff4d845-gh9xq                1/1     Running       0          2m29s
    kiali-85dc7cdc48-dw54t                 1/1     Running       0          2m24s
    prometheus-8685fb8c59-5ws29            1/2     Terminating   0          2m24s
    prometheus-bbf8f7b7-5xh6r              2/2     Running       0          92s
    ```

    ```shell
    $ kubectl delete pod -n istio-system prometheus-8685fb8c59-5ws29 
    ```

    删除不掉，强制删除

    ```shell
    $ kubectl delete pod -n istio-system prometheus-8685fb8c59-5ws29 --force --grace-period=0
    ```

  ##### 运行成功：

  ```shell
  [root@k8s-master01 Istioctl-install]# istioctl install --set profile=demo
  Detected that your cluster does not support third party JWT authentication. Falling back to less secure first party JWT. See https://istio.io/docs/ops/best-practices/security/#configure-third-party-service-account-tokens for details.
  ✔ Istio core installed                                                                                                                                          
  ✔ Istiod installed                                                                                                                                              
  ✔ Addons installed                                                                                                                                              
    Processing resources for Egress gateways, Ingress gateways. Waiting for Deployment/istio-system/istio-egressgateway, Deployment/istio-system/istio-ingressg...
  
  ✔ Ingress gateways installed                                                                                                                                    
  ✔ Egress gateways installed                                                                                                                                     
  ✔ Installation complete
  ```

  

- ##### 3.4 显示配置文件的配置

  您可以查看配置文件的配置设置。例如，通过以下命令查看 `default` 配置文件的设置：

  ```shell
  $ istioctl profile dump demo
  ```

  要查看整个配置的子集，可以使用 `--config-path` 标志，该标志仅选择部分给定路径下的配置：

  ```shell
  $ istioctl profile dump --config-path components.pilot demo
  ```

- ##### [Istio修改IngressGateway网络类型](https://www.cnblogs.com/assion/p/11326088.html)（可选）

  修改

  ```shell
  $ kubectl patch service istio-ingressgateway -n istio-system -p '{"spec":{"type":"NodePort"}}'
  ```

  查看ID与端口

  ```shell
  $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
  $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
  ```

  访问方式

  ```
  可通过节点的IP+端口访问，也可以手动挂个LB进来
  ```

  

  

#### 从外部 Chart 安装（不推荐）

通常，`istioctl` 使用内置 Chart 生成安装清单。这些 Chart 与 `istioctl` 一起发布，用于审核和自定义，它们 放置在 `manifests` 目录下。 

```shell
$ istioctl install --charts=manifests/
```





#### 安装前生成清单(暂不推荐)

您可以在安装 Istio 之前使用 `manifest generate` 子命令生成清单，而不是 `manifest apply`。 例如，使用以下命令为 `default` 配置文件生成清单：

```shell
$ istioctl manifest generate > $HOME/generated-manifest.yaml
```

根据需要检查清单，然后使用以下命令应用清单：

```shell
$ kubectl create ns istio-system
$ kubectl apply -f $HOME/generated-manifest.yaml
```

> `由于集群中的资源不可用，此命令可能显示暂时错误。`



#### 验证安装成功

您可以使用 `verify-install` 命令检查 Istio 安装是否成功，它将集群上的安装与您指定的清单进行比较。

如果未在部署之前生成清单，请运行以下命令以现在生成它：

```shell
$ istioctl manifest generate <your original installation options> > $HOME/generated-manifest.yaml
```

然后运行以下 `verify-install` 命令以查看安装是否成功：

```shell
$ istioctl verify-install -f $HOME/generated-manifest.yaml
```



#### 卸载 Istio

可以使用以下命令来卸载 Istio：

卸载会删除RBAC权限，istio-system命名空间及其下的所有资源。可以忽略不存在的资源的错误（因为它们可能已被分层删除）。

```shell
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
```

```shell
$ istioctl manifest generate --set profile=default | kubectl delete -f -
```

如何`istio-system`命名空间下的资源不在需要，可以如下操作

```shell
$ kubectl delete namespace istio-system
```





### 附录：笔记

1.kubernetes 强制删除istio-system空间,强制删除pod

```shell
kubectl delete ns istio-system --grace-period=0 --force
```

2.[github issues](https://github.com/istio/istio/issues/22463)

3.在生产环境部署几乎不会完全使用官方的配置，虽然default是官方推荐的生产环境的基本配置。以下是使用自己的配置文件进行部署，不用profile

```shell
ic manifest apply -f default.yaml --set values.global.jwtPolicy=first-party-jwt
```

4.错误问题：

```shell
Events:
  Type     Reason            Age                From               Message
  ----     ------            ----               ----               -------
  Warning  FailedScheduling  57s (x3 over 59s)  default-scheduler  0/3 nodes are available: 1 node(s) had taints that the pod didn't tolerate, 2 Insufficient memory.
```

解决：

有时候一个pod创建之后一直是pending，没有日志，也没有pull镜像，describe的时候发现里面有一句话： `1 node(s) had taints that the pod didn't tolerate.`

直译意思是节点有了污点无法容忍，执行 `kubectl get no -o yaml | grep taint -A 5` 之后发现该节点是不可调度的。这是因为kubernetes出于安全考虑默认情况下无法在master节点上部署pod，于是用下面方法解决：

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

```shell
[root@k8s-master01 ~]# kubectl taint nodes --all node-role.kubernetes.io/master-
node/k8s-master01 untainted
taint "node-role.kubernetes.io/master:" not found
taint "node-role.kubernetes.io/master:" not found
```













##### 参考网址：

- [Istio的安装与部署](https://www.jianshu.com/p/95721c4836a8)

















