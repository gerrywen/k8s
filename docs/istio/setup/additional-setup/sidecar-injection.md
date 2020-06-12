# 设置 Sidecar

### 注入

为了充分利用 Istio 的所有特性，网格中的 pod 必须运行一个 Istio sidecar 代理。

下面的章节描述了向 pod 中注入 Istio sidecar 的两种方法：使用 [`istioctl`](https://istio.io/latest/zh/docs/reference/commands/istioctl) 手动注入或启用 pod 所属命名空间的 Istio sidecar 注入器自动注入。

手动注入直接修改配置，如 deployment，并将代理配置注入其中。

当 pod 所属命名空间启用自动注入后，自动注入器会使用准入控制器在创建 Pod 时自动注入代理配置。

通过应用 `istio-sidecar-injector` ConfigMap 中定义的模版进行注入。

### 手动注入 sidecar

要手动注入 deployment，请使用 [`istioctl kube-inject`](https://istio.io/latest/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)：

```shell
$ istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl apply -f -
```

查看手动注入istio-injection，不会显示*enabled*

```shell
$ kubectl get namespace -L istio-injection
```

删除手动注入 deployment，请使用 `istioctl kube-inject`：

```shell
$ istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl delete -f -
```

默认情况下将使用集群内的配置，或者使用该配置的本地副本来完成注入

```shell
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > inject-config.yaml
$ kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.values}' > inject-values.yaml
$ kubectl -n istio-system get configmap istio -o=jsonpath='{.data.mesh}' > mesh-config.yaml
```

指定输入文件，运行 `kube-inject` 并部署

```shell
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --valuesFile inject-values.yaml \
    --filename samples/sleep/sleep.yaml \
    | kubectl apply -f -
```

验证 sidecar 已经被注入到 READY 列下 `2/2` 的 sleep pod 中

```shell
$ kubectl get pod  -l app=sleep
NAME                     READY   STATUS    RESTARTS   AGE
sleep-64c6f57bc8-f5n4x   2/2     Running   0          24s
```



### 自动注入 sidecar

使用 Istio 提供的[准入控制器变更 webhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)，可以将 sidecar 自动添加到可用的 Kubernetes pod 中

> 虽然准入控制器默认情况下是启动的，但一些 Kubernetes 发行版会禁用他们。如果出现这种情况，根据说明来[启用准入控制器](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#how-do-i-turn-on-an-admission-controller)。

当你在一个命名空间中设置了 `istio-injection=enabled` 标签，且 injection webhook 被启用后，任何新的 pod 都有将在创建时自动添加 sidecar。

请注意，区别于手动注入，自动注入发生在 pod 层面。你将看不到 deployment 本身有任何更改。取而代之，需要检查单独的 pod（使用 `kubectl describe`）来查询被注入的代理。



#### 禁用或更新注入 webhook

Sidecar 注入 webhook 是默认启用的。如果你希望禁用 webhook，可以使用 [Helm](https://istio.io/latest/zh/docs/setup/install/helm/) 将 `sidecarInjectorWebhook.enabled` 设置为 `false`。

还有很多[其他选项](https://istio.io/latest/zh/docs/reference/config/installation-options/#sidecar-injector-webhook-options)可以配置。



#### 部署应用

部署 sleep 应用。验证 deployment 和 pod 只有一个容器。

```shell
$ kubectl apply -f samples/sleep/sleep.yaml
```

```shell
$ kubectl get deployment,pod -o wide
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                    SELECTOR
deployment.extensions/sleep   1/1     1            1           22s   sleep        governmentpaas/curl-ssl   app=sleep

NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE         NOMINATED NODE   READINESS GATES
pod/sleep-6bdb595bcb-qqpgl   1/1     Running   0          22s   10.244.4.19   k8s-node02   <none>           <none>
```

将 `default` namespace 标记为 `istio-injection=enabled`。

```shell
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection
```

```shell
NAME              STATUS   AGE     ISTIO-INJECTION
dc                Active   27h     
default           Active   26d     enabled
grafana           Active   12d     
ingress-nginx     Active   26d 
```

注入发生在 pod 创建时。杀死正在运行的 pod 并验证新创建的 pod 是否注入 sidecar。原来的 pod 具有 READY 为 1/1 的容器，注入 sidecar 后的 pod 则具有 READY 为 2/2 的容器。

```shell
$ kubectl delete pod -l app=sleep
$ kubectl get pod -l app=sleep
```

```shell
NAME                     READY   STATUS    RESTARTS   AGE
sleep-6bdb595bcb-v4fkw   2/2     Running   0          47s
```

查看已注入 pod 的详细状态。你应该看到被注入的 `istio-proxy` 容器和对应的卷。请确保使用状态为 `Running` pod 的名称替换以下命令。

```shell
$ kubectl describe pod -l app=sleep
```

禁用 `default` namespace 注入，并确认新的 pod 在创建时没有 sidecar。

```shell
$ kubectl label namespace default istio-injection-
$ kubectl delete pod -l app=sleep
$ kubectl get pod
```

```shell
NAME                     READY   STATUS        RESTARTS   AGE
sleep-6bdb595bcb-nw4sh   1/1     Running       0          11s
sleep-6bdb595bcb-v4fkw   2/2     Terminating   0          2m17s
```



#### 卸载 sidecar 自动注入器

```shell
$ kubectl delete mutatingwebhookconfiguration istio-sidecar-injector
$ kubectl -n istio-system delete service istio-sidecar-injector
$ kubectl -n istio-system delete deployment istio-sidecar-injector
$ kubectl -n istio-system delete serviceaccount istio-sidecar-injector-service-account
$ kubectl delete clusterrole istio-sidecar-injector-istio-system
$ kubectl delete clusterrolebinding istio-sidecar-injector-admin-role-binding-istio-system
```

上面的命令不会从 pod 中移除注入的 sidecar。需要进行滚动更新或者直接删除 pod，并强制 deployment 创建它们。

此外，还可以清理在此任务中修改过的其他资源。

```shell
$ kubectl label namespace default istio-injection-
```

