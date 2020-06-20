# 配置请求路由

### 开始之前

- 按照[安装指南](https://istio.io/latest/zh/docs/setup/)中的说明安装 Istio。
- 部署 [Bookinfo](https://istio.io/latest/zh/docs/examples/bookinfo/) 示例应用程序。
- 查看[流量管理](https://istio.io/latest/zh/docs/concepts/traffic-management)的概念文档。在尝试此任务之前，您应该熟悉一些重要的术语，例如 *destination rule* 、*virtual service* 和 *subset* 。



### 应用 virtual service

要仅路由到一个版本，请应用为微服务设置默认版本的 virtual service。在这种情况下，virtual service 将所有流量路由到每个微服务的 `v1` 版本。

> 如果您还没有应用 destination rule，请先[应用默认目标规则](https://istio.io/latest/zh/docs/examples/bookinfo/#apply-default-destination-rules)。

1. 运行以下命令以应用 virtual services:

   ```shell
   $ kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
   ```

2. 使用以下命令显示已定义的路由：

   ```shell
   $ kubectl get virtualservices -o yaml
   ```

3. 您还可以使用以下命令显示相应的 `subset` 定义:

   ```shell
   $ kubectl get destinationrules -o yaml
   ```

您已将 Istio 配置为路由到 Bookinfo 微服务的 `v1` 版本，最重要的是 `reviews` 服务的版本 1。

 

### 测试新的路由配置

您可以通过再次刷新 Bookinfo 应用程序的 `/productpage` 轻松测试新配置。

1. 在浏览器中打开 Bookinfo 站点。网址为 `http://$GATEWAY_URL/productpage`，其中 `$GATEWAY_URL` 是外部的入口 IP 地址，如 [Bookinfo](https://istio.io/latest/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port) 文档中所述。

   请注意，无论您刷新多少次，页面的评论部分都不会显示评级星标。这是因为您将 Istio 配置为 将评论服务的所有流量路由到版本 `reviews:v1`，而此版本的服务不访问星级评分服务。

您已成功完成此任务的第一部分：将流量路由到服务的某一个版本。



### 基于用户身份的路由

接下来，您将更改路由配置，以便将来自特定用户的所有流量路由到特定服务版本。在这，来自名为 Jason 的用户的所有流量将被路由到服务 `reviews:v2`。

请注意，Istio 对用户身份没有任何特殊的内置机制。事实上，`productpage` 服务在所有到 `reviews` 服务的 HTTP 请求中都增加了一个自定义的 `end-user` 请求头，从而达到了本例子的效果。

> 请记住，`reviews:v2` 是包含星级评分功能的版本。

1. 运行以下命令以启用基于用户的路由：

   ```shell
   $ kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
   ```

2. 确认规则已创建：

   ```shell
   $ kubectl get virtualservice reviews -o yaml
   ```

3. 在 Bookinfo 应用程序的 `/productpage` 上，以用户 `jason` 身份登录。

   刷新浏览器。你看到了什么？星级评分显示在每个评论旁边。

4. 以其他用户身份登录（选择您想要的任何名称）。

   刷新浏览器。现在星星消失了。这是因为除了 Jason 之外，所有用户的流量都被路由到 `reviews:v1`。

您已成功配置 Istio 以根据用户身份路由流量。



### 理解原理

在此任务中，您首先使用 Istio 将 100% 的请求流量都路由到了 Bookinfo 服务的 v1 版本。 然后设置了一条路由规则，它根据 `productpage` 服务发起的请求中的 `end-user` 自定义请求头内容，选择性地将特定的流量路由到了 `reviews` 服务的 `v2` 版本。

请注意，Kubernetes 中的服务，如本任务中使用的 Bookinfo 服务，必须遵守某些特定限制，才能利用到 Istio 的 L7 路由特性优势。 参考 [Pods 和 Services 需求](https://istio.io/latest/zh/docs/ops/deployment/requirements/)了解详情。

在[流量转移](https://istio.io/latest/zh/docs/tasks/traffic-management/traffic-shifting)任务中，您将按照在此处学习到的相同的基本模式来配置路由规则，以逐步将流量从服务的一个版本迁移到另一个版本。



### 清除

1. 删除应用程序的 virtual service：

   ```shell
   $ kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
   ```

2. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](https://istio.io/latest/zh/docs/examples/bookinfo/#cleanup)的说明关闭应用程序。







### 应用默认目标规则

在使用 Istio 控制 Bookinfo 版本路由之前，您需要在[目标规则](https://istio.io/latest/zh/docs/concepts/traffic-management/#destination-rules)中定义好可用的版本，命名为 *subsets* 。

运行以下命令为 Bookinfo 服务创建的默认的目标规则：

- 如果**没有**启用双向 TLS，请执行以下命令：

  > 如果您是 Istio 的新手，并且使用了 `demo` [配置文件](https://istio.io/latest/zh/docs/setup/additional-setup/config-profiles/)，请选择此步。

  ```shell
  $ kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
  ```

- 如果**启用了**双向 TLS，请执行以下命令：

  ```shell
  $ kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
  ```

等待几秒钟，以使目标规则生效。

您可以使用以下命令查看目标规则：

```shell
$ kubectl get destinationrules -o yaml
```



