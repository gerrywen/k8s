# Ingress (Kubernetes)

此任务描述如何使用Kubernetes配置Istio以在服务网格集群之外公开服务[Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

> 建议使用[Istio网关](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/)，而不要使用Ingress，以利用Istio提供的全部功能集 ，例如丰富的流量管理和安全功能。

## 开始之前

请按照[Ingress Gateway任务](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/)的“[开始](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#before-you-begin)和[确定入口IP和端口](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)”部分中的说明进行操作。

## 使用Ingress资源配置Ingress

A [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.

Let’s see how you can configure a `Ingress` on port 80 for HTTP traffic.

1. 创建一个Istio`Gateway`：

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.k8s.io/v1beta1
   kind: Ingress
   metadata:
     annotations:
       kubernetes.io/ingress.class: istio
     name: ingress
   spec:
     rules:
     - host: httpbin.example.com
       http:
         paths:
         - path: /status/*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   必须使用`kubernetes.io / ingress.class`注释来告诉Istio网关控制器它应该处理该`Ingress`，否则它将被忽略。

2. 使用curl *访问* httpbin 服务：

   ```shell
   $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 48
   ```

   请注意，您使用-H标志将Host HTTP标头设置为“ httpbin.example.com”。 这是必需的，因为Ingress已配置为处理“ httpbin.example.com”，但是在您的测试环境中，该主机没有DNS绑定，而只是将您的请求发送到Ingress IP。

3. 访问其他未明确公开的URL。 您应该看到HTTP 404错误：

   ```shell
   $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

## 接下来

### TLS

`Ingress` supports [specifying TLS settings](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). This is supported by Istio, but the referenced `Secret` must exist in the namespace of the `istio-ingressgateway` deployment (typically `istio-system`). [cert-manager](https://istio.io/latest/docs/ops/integrations/certmanager/) can be used to generate these certificates.

### 指定路径类型

默认情况下，Istio会将路径视为完全匹配，除非它们以“ / *”或“。*”结尾，在这种情况下，它们将成为前缀匹配。 不支持其他正则表达式。

在Kubernetes 1.18中，添加了一个新字段`pathType`。 这允许将路径明确声明为“精确”或“前缀”。

### 指定`IngressClass`

在Kubernetes 1.18中，添加了新资源“ IngressClass”，以替换“ Ingress”资源上的“ kubernetes.io/ingress.class”注释。 如果您正在使用此资源，则需要将“ controller”字段设置为“ istio.io/ingress-controller”。 例如：

```yaml
apiVersion: networking.k8s.io/v1beta1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress
spec:
  ingressClassName: istio
  ...
```





## 清除

删除 `Gateway` 和 `VirtualService` 配置，并关闭服务 [httpbin](https://github.com/istio/istio/tree/release-1.6/samples/httpbin)：

```shell
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f samples/httpbin/httpbin.yaml
```

