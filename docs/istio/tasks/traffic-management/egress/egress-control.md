# 访问外部服务

由于默认情况下，来自 Istio-enable Pod 的所有出站流量都会重定向到其 Sidecar 代理，群集外部 URL 的可访问性取决于代理的配置。默认情况下，Istio 将 Envoy 代理配置为允许传递未知服务的请求。尽管这为入门 Istio 带来了方便，但是，通常情况下，配置更严格的控制是更可取的。

这个任务向你展示了三种访问外部服务的方法：

1. 允许 Envoy 代理将请求传递到未在网格内配置过的服务。
2. 配置 [service entries](https://istio.io/latest/zh/docs/reference/config/networking/service-entry/) 以提供对外部服务的受控访问。
3. 对于特定范围的 IP，完全绕过 Envoy 代理。



## 开始之前

- 根据[安装指南](https://istio.io/latest/zh/docs/setup/)中的命令设置 Istio。

- 部署 [sleep](https://github.com/istio/istio/tree/release-1.6/samples/sleep) 这个示例应用，用作发送请求的测试源。 如果你启用了[自动注入 sidecar](https://istio.io/latest/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，使用以下的命令来部署示例应用：

  ```bash
  $ kubectl apply -f samples/sleep/sleep.yaml
  ```

  否则，在部署 `sleep` 应用前，使用以下命令手动注入 sidecar：

  ```bash
  $ kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
  ```

  > 您可以使用任何安装了 `curl` 的 pod 作为测试源。

- 设置环境变量 `SOURCE_POD`，值为你的源 pod 的名称：

  ```bash
  $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
  ```

## Envoy 转发流量到外部服务

Istio 有一个[安装选项](https://istio.io/latest/zh/docs/reference/config/installation-options/)， `global.outboundTrafficPolicy.mode`，它配置 sidecar 对外部服务（那些没有在 Istio 的内部服务注册中定义的服务）的处理方式。如果这个选项设置为 `ALLOW_ANY`，Istio 代理允许调用未知的服务。如果这个选项设置为 `REGISTRY_ONLY`，那么 Istio 代理会阻止任何没有在网格中定义的 HTTP 服务或 service entry 的主机。`ALLOW_ANY` 是默认值，不控制对外部服务的访问，方便你快速地评估 Istio。你可以稍后再[配置对外部服务的访问](https://istio.io/latest/zh/docs/tasks/traffic-management/egress/egress-control/#controlled-access-to-external-services) 。



1. 要查看这种方法的实际效果，你需要确保 Istio 的安装配置了 `global.outboundTrafficPolicy.mode` 选项为 `ALLOW_ANY`。它在默认情况下是开启的，除非你在安装 Istio 时显式地将它设置为 `REGISTRY_ONLY`。

   运行以下命令以确认配置是正确的：

   ```shell
   $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY" | uniq
   
   mode: ALLOW_ANY
   ```

   运行结果为空的话,[定制配置](https://preliminary.istio.io/latest/zh/docs/setup/install/istioctl/#customizing-the-configuration)

   可以使用命令上的 `--set` 选项分别设置此 API 中的配置参数。例如，要在 `default` 配置文件之上启用控制面安全特性，请使用以下命令：

   ```shell
   $ istioctl manifest apply --set values.global.outboundTrafficPolicy.mode=ALLOW_ANY
   ```

   如果它开启了，那么输出应该会出现 `mode: ALLOW_ANY`。

   > 如果你显式地设置了 `REGISTRY_ONLY` 模式，可以用以下的命令来改变它：
   >
   > ```shell
   > $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
   > 
   > configmap "istio" replaced
   > ```
   >
   > ```shell
   > $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: REGISTRY_ONLY" | uniq
   > ```

2. 从 `SOURCE_POD` 向外部 HTTPS 服务发出两个请求，确保能够得到状态码为 `200` 的响应：

   ```shell
   $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.baidu.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.taobao.com | grep "HTTP/"
   
   HTTP/2 200
   HTTP/2 200
   ```

恭喜！你已经成功地从网格中发送了 egress 流量。

这种访问外部服务的简单方法有一个缺点，即丢失了对外部服务流量的 Istio 监控和控制；比如，外部服务的调用没有记录到 Mixer 的日志中。下一节将介绍如何监控和控制网格对外部服务的访问。



## 控制对外部服务的访问

使用 Istio `ServiceEntry` 配置，你可以从 Istio 集群中访问任何公开的服务。本节将向你展示如何在不丢失 Istio 的流量监控和控制特性的情况下，配置对外部 HTTP 服务([httpbin.org](http://httpbin.org/)) 和外部 HTTPS 服务([www.google.com](https://www.google.com/)) 的访问。

### 更改为默认的封锁策略

为了演示如何控制对外部服务的访问，你需要将 `global.outboundTrafficPolicy.mode` 选项，从 `ALLOW_ANY`模式 改为 `REGISTRY_ONLY` 模式。



> 你可以向已经在 `ALLOW_ANY` 模式下的可访问服务添加访问控制。通过这种方式，你可以在一些外部服务上使用 Istio 的特性，而不会阻止其他服务。一旦你配置了所有服务，就可以将模式切换到 `REGISTRY_ONLY` 来阻止任何其他无意的访问。

1. 执行以下命令来将 `global.outboundTrafficPolicy.mode` 选项改为 `REGISTRY_ONLY`：

   ```shell
   $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
   
   configmap "istio" replaced
   ```

   

2. 从 `SOURCE_POD` 向外部 HTTPS 服务发出几个请求，验证它们现在是否被阻止：

   ```shell
   $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.baidu.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.taobao.com | grep "HTTP/"
   
   command terminated with exit code 35
   command terminated with exit code 35
   ```

   > 配置更改后肯需要一小段时间才能生效，所以你可能仍然可以得到成功地响应。等待若干秒后再重新执行上面的命令。



## 访问一个外部的 HTTP 服务

1. 创建一个 `ServiceEntry`，以允许访问一个外部的 HTTP 服务：

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.istio.io/v1alpha3
   kind: ServiceEntry
   metadata:
     name: httpbin-ext
   spec:
     hosts:
     - httpbin.org
     ports:
     - number: 80
       name: http
       protocol: HTTP
     resolution: DNS
     location: MESH_EXTERNAL
   EOF
   ```

2. 从 `SOURCE_POD` 向外部的 HTTP 服务发出一个请求：

   ```shell
   $  kubectl exec -it $SOURCE_POD -c sleep -- curl http://httpbin.org/headers
   {
     "headers": {
     "Accept": "*/*",
     "Connection": "close",
     "Host": "httpbin.org",
     "User-Agent": "curl/7.60.0",
     ...
     "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
     }
   }
   ```

   注意由 Istio sidecar 代理添加的 headers: `X-Envoy-Decorator-Operation`。

3. 检查 `SOURCE_POD` 的 sidecar 代理的日志:

   ```shell
   $  kubectl logs $SOURCE_POD -c istio-proxy | tail
   ```

4. 检查 Mixer 日志。如果 Istio 部署的命名空间是 `istio-system`，那么打印日志的命令如下：

   ```shell
   $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'httpbin.org'
   ```

   请注意 `destinationServiceHost` 这个属性的值是 `httpbin.org`。另外，注意与 HTTP 相关的属性，比如：`method`, `url`, `responseCode` 等等。使用 Istio egress 流量控制，你可以监控对外部 HTTP 服务的访问，包括每次访问中与 HTTP 相关的信息。

## 访问外部 HTTPS 服务

1. 创建一个 `ServiceEntry`，允许对外部服务的访问。

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.istio.io/v1alpha3
   kind: ServiceEntry
   metadata:
     name: baidu
   spec:
     hosts:
     - www.baidu.com
     ports:
     - number: 443
       name: https
       protocol: HTTPS
     resolution: DNS
     location: MESH_EXTERNAL
   EOF
   ```

2. 从 `SOURCE_POD` 往外部 HTTPS 服务发送请求：

   ```shell
   $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.baidu.com | grep  "HTTP/"
   ```

3. 检查 `SOURCE_POD` 的 sidecar 代理的日志：

   ```shell
   $ kubectl logs $SOURCE_POD -c istio-proxy | tail
   ```

   请注意与您对 `www.baidu.com` 的 HTTPS 请求相关的条目。

4. 检查 Mixer 日志。如果 Istio 部署的命名空间是 `istio-system`，那么打印日志的命令如下：

   ```shell
   $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'www.baidu.com'
   ```

   请注意 `requestedServerName` 这个属性的值是 `www.google.com`。使用 Istio egress 流量控制，你可以监控对外部 HTTP 服务的访问，特别是 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 和发送/接收的字节数。请注意像 method、URL path、response code 这些与 HTTP 相关的信息，已经被加密了；所以 Istio 看不到也无法对它们进行监控。如果你需要在访问外部 HTTPS 服务时，监控 HTTP 相关的信息, 那么你需要让你的应用发出 HTTP 请求, 并[为 Istio 设置 TLS origination](https://istio.io/latest/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)

   

## 管理到外部服务的流量

与集群内的请求相似，也可以为使用 `ServiceEntry` 配置访问的外部服务设置 [Istio 路由规则](https://istio.io/latest/zh/docs/concepts/traffic-management/#routing-rules)。在本示例中，你将设置对 `httpbin.org` 服务访问的超时规则。

1. 从用作测试源的 pod 内部，向外部服务 `httpbin.org` 的 `/delay` endpoint 发出 *curl* 请求：

   ```shell
   $ kubectl exec -it $SOURCE_POD -c sleep sh
   $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
   ```

   这个请求大约在 5 秒内返回 200 (OK)。

2. 退出测试源 pod，使用 `kubectl` 设置调用外部服务 `httpbin.org` 的超时时间为 3 秒。

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: httpbin-ext
   spec:
     hosts:
       - httpbin.org
     http:
     - timeout: 3s
       route:
         - destination:
             host: httpbin.org
           weight: 100
   EOF
   ```

3. 几秒后，重新发出 *curl* 请求：

   ```shell
   $ kubectl exec -it $SOURCE_POD -c sleep sh
   $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
   ```

   这一次，在 3 秒后出现了 504 (Gateway Timeout)。Istio 在 3 秒后切断了响应时间为 5 秒的 `httpbin.org` 服务。



## 清理对外部服务的受控访问

```shell
$ kubectl delete serviceentry httpbin-ext baidu
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
```



## 清理

闭服务 [sleep](https://github.com/istio/istio/tree/release-1.6/samples/sleep) :

```shell
$ kubectl delete -f samples/sleep/sleep.yaml
```



### 将出站流量策略模式设置为所需的值

1. 检查现在的值:

   ```shell
   $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY" | uniq
   $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: REGISTRY_ONLY" | uniq
   
   mode: ALLOW_ANY
   ```

   

   输出将会是 `mode: ALLOW_ANY` 或 `mode: REGISTRY_ONLY`。

2. 如果你想改变这个模式，执行以下命令：

   change from ALLOW_ANY to REGISTRY_ONLY

   ```shell
   $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
   ```

   change from REGISTRY_ONLY to ALLOW_ANY

   ```shell
   $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
   
   configmap/istio replaced
   ```





