# 熔断

本任务展示如何为连接、请求以及异常检测配置熔断。

熔断，是创建弹性微服务应用程序的重要模式。熔断能够使您的应用程序具备应对来自故障、潜在峰值和其他 未知网络因素影响的能力。

这个任务中，你将配置熔断规则，然后通过有意的使熔断器“跳闸”来测试配置。



## 开始之前

- 跟随[安装指南](https://istio.io/latest/zh/docs/setup/)安装 Istio。

- 启动 [httpbin](https://github.com/istio/istio/tree/release-1.6/samples/httpbin) 样例程序。

  如果您启用了 [sidecar 自动注入](https://istio.io/latest/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，通过以下命令部署 `httpbin` 服务：

  ```shell
  $ kubectl apply -f samples/httpbin/httpbin.yaml
  ```

  否则，您必须在部署 `httpbin` 应用程序前进行手动注入，部署命令如下：

  ```shell
  $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
  ```

应用程序 `httpbin` 作为此任务的后端服务。



## 配置熔断器

1. 创建一个[目标规则](https://istio.io/latest/zh/docs/reference/config/networking/destination-rule/)，在调用 `httpbin` 服务时应用熔断设置：

   > 如果您的 Istio 启用了双向 TLS 身份验证，则必须在应用目标规则之前将 TLS 流量策略 `mode：ISTIO_MUTUAL` 添加到 `DestinationRule` 。否则请求将产生 503 错误，如[这里](https://istio.io/latest/zh/docs/ops/common-problems/network-issues/#service-unavailable-errors-after-setting-destination-rule)所述。

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.istio.io/v1alpha3
   kind: DestinationRule
   metadata:
     name: httpbin
   spec:
     host: httpbin
     trafficPolicy:
       connectionPool:
         tcp:
           maxConnections: 1
         http:
           http1MaxPendingRequests: 1
           maxRequestsPerConnection: 1
       outlierDetection:
         consecutiveErrors: 1
         interval: 1s
         baseEjectionTime: 3m
         maxEjectionPercent: 100
   EOF
   ```

2. 验证目标规则是否已正确创建：

   ```shell
   $ kubectl get destinationrule httpbin -o yaml
   ```

## 增加一个客户

创建客户端程序以发送流量到 `httpbin` 服务。这是一个名为 [Fortio](https://github.com/istio/fortio) 的负载测试客户的，其可以控制连接数、并发数及发送 HTTP 请求的延迟。通过 Fortio 能够有效的触发前面 在 `DestinationRule` 中设置的熔断策略。

1. 向客户端注入 Istio Sidecar 代理，以便 Istio 对其网络交互进行管理：

   ```shell
   $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/sample-client/fortio-deploy.yaml)
   ```

2. 登入客户端 Pod 并使用 Fortio 工具调用 `httpbin` 服务。`-curl` 参数表明发送一次调用：

   ```shell
   $ FORTIO_POD=$(kubectl get pod | grep fortio | awk '{ print $1 }')
   $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -curl  http://httpbin:8000/get
   ```

可以看到调用后端服务的请求已经成功！接下来，可以测试熔断。



## 触发熔断器

在 `DestinationRule` 配置中，您定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。 这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或 连接将被阻止。

1. 发送并发数为 2 的连接（`-c 2`），请求 20 次（`-n 20`）：

   ```shell
   $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
   ```

2. 将并发连接数提高到 3 个：

   ```shell
   $ kubectl exec -it $FORTIO_POD  -c fortio /usr/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
   ```

3. 查询 `istio-proxy` 状态以了解更多熔断详情:

   ```shell
   $ kubectl exec $FORTIO_POD -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
   ```

   可以看到 `upstream_rq_pending_overflow` 值 `12`，这意味着，目前为止已有 12 个调用被标记为熔断。

## 清理

1. 清理规则:

   ```shell
   $ kubectl delete destinationrule httpbin
   ```

2. 下线 [httpbin](https://github.com/istio/istio/tree/release-1.6/samples/httpbin) 服务和客户端：

   ```shell
   $ kubectl delete deploy httpbin fortio-deploy
   $ kubectl delete svc httpbin
   ```

   