# 安全网关

[控制 Ingress 流量任务](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress)描述了如何配置入口网关以向外部流量公开HTTP服务。 此任务说明如何使用简单或双向TLS公开安全的HTTPS服务。



## 开始之前

1. 执行[开始之前](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress/ingress-control#before-you-begin)任务和[控制 Ingress 流量](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress)任务中的[确认 ingress 的 IP 和端口](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)小节中的步骤。执行完毕后，Istio 和 [httpbin](https://github.com/istio/istio/tree/release-1.6/samples/httpbin) 服务都已经部署完毕。环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 也已经设置。

2. 对于 macOS 用户，确认您的 *curl* 使用了 [LibreSSL](http://www.libressl.org/) 库来编译：

   ```shell
   $ curl --version | grep LibreSSL
   curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
   ```
   

如果以上输出打印了 *LibreSSL* 的版本，则 *curl* 应该可以按照此任务中的说明正常工作。否则，请尝试另一种 *curl* 版本，例如运行于 Linux 计算机的版本。

## 生成服务器证书和私钥

此任务您可以使用您喜欢的工具来生成证书和私钥。下列命令使用了 [openssl](https://man.openbsd.org/openssl.1)

1. 创建一个根证书和私钥以为您的服务所用的证书签名：

   ```shell
   $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
   ```

2. 为 `httpbin.example.com` 创建一个证书和私钥：

   ```shell
   $ openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
   $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
   ```

## 为单个主机配置TLS入口网关

1. 确保从开始之前就已经部署了httpbin服务。

2. 为入口网关创建一个秘钥：

   ```shell
   $ kubectl create -n istio-system secret tls httpbin-credential --key=httpbin.example.com.key --cert=httpbin.example.com.crt
   ```

   > 秘钥名称不应以istio或prometheus开头，并且机密不应包含令牌字段。

3. 为端口443定义一个带有服务器的网关：部分，并将credentialName的值指定为httpbin-credential。 这些值与秘钥名称相同。 TLS模式的值应为SIMPLE。

   ```shell
   $ cat <<EOF | kubectl apply -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: Gateway
   metadata:
     name: mygateway
   spec:
     selector:
       istio: ingressgateway # use istio default ingress gateway
     servers:
     - port:
         number: 443
         name: https
         protocol: HTTPS
       tls:
         mode: SIMPLE
         credentialName: httpbin-credential # must be the same as secret
       hosts:
       - httpbin.example.com
   EOF
   ```

4. 配置路由以让流量从 `Gateway` 进入。定义与[控制 Ingress 流量](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress/ingress-control/#configuring-ingress-using-an-Istio-gateway)任务中相同的 `VirtualService`：

   ```shell
   $ cat <<EOF | kubectl apply -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: httpbin
   spec:
     hosts:
     - "httpbin.example.com"
     gateways:
     - mygateway
     http:
     - match:
       - uri:
           prefix: /status
       - uri:
           prefix: /delay
       route:
       - destination:
           port:
             number: 8000
           host: httpbin
   EOF
   ```

5. 发送HTTPS请求以通过HTTPS访问httpbin服务：

   ```shell
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   ```

   通过发送请求到 `/status/418` URL 路径，您可以很好地看到您的 `httpbin` 服务确实已被访问。 `httpbin` 服务将返回 [418 I’m a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) 代码。

6. 删除网关的秘钥并创建一个新密码以更改入口网关的凭据。

   ```shell
   $ kubectl -n istio-system delete secret httpbin-credential
   ```

   ```shell
   $ mkdir new_certificates
   $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout new_certificates/example.com.key -out new_certificates/example.com.crt
   $ openssl req -out new_certificates/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout new_certificates/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
   $ openssl x509 -req -days 365 -CA new_certificates/example.com.crt -CAkey new_certificates/example.com.key -set_serial 0 -in new_certificates/httpbin.example.com.csr -out new_certificates/httpbin.example.com.crt
   $ kubectl create -n istio-system secret tls httpbin-credential \
   --key=new_certificates/httpbin.example.com.key \
   --cert=new_certificates/httpbin.example.com.crt
   ```

7. 使用新证书链使用curl来访问httpbin服务：

   ```shell
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert new_certificates/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   ...
   HTTP/2 418
   ...
   -=[ teapot ]=-
   
      _...._
    .'  _ _ `.
   | ."` ^ `". _,
   \_;`"---"`|//
     |       ;/
     \_     _/
       `"""`
   ```

8. 如果您尝试使用先前的证书链访问httpbin，则尝试现在失败。

   ```shell
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   ...
   * TLSv1.2 (OUT), TLS handshake, Client hello (1):
   * TLSv1.2 (IN), TLS handshake, Server hello (2):
   * TLSv1.2 (IN), TLS handshake, Certificate (11):
   * TLSv1.2 (OUT), TLS alert, Server hello (2):
   * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
   ```

## 配置双向 TLS ingress 网关

您可以为多个主机（例如httpbin.example.com和helloworld-v1.example.com）配置入口网关。 入口网关检索与特定凭据名称相对应的唯一凭据。

1. 要恢复httpbin的凭据，请删除其秘钥并重新创建。

   ```shell
   $ kubectl -n istio-system delete secret httpbin-credential
   $ kubectl create -n istio-system secret tls httpbin-credential \
   --key=httpbin.example.com.key \
   --cert=httpbin.example.com.crt
   ```

2. 开始`helloworld-v1`例子。

   ```shell
   $ cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: Service
   metadata:
     name: helloworld-v1
     labels:
       app: helloworld-v1
   spec:
     ports:
     - name: http
       port: 5000
     selector:
       app: helloworld-v1
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: helloworld-v1
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: helloworld-v1
         version: v1
     template:
       metadata:
         labels:
           app: helloworld-v1
           version: v1
       spec:
         containers:
         - name: helloworld
           image: istio/examples-helloworld-v1
           resources:
             requests:
               cpu: "100m"
           imagePullPolicy: IfNotPresent #Always
           ports:
           - containerPort: 5000
   EOF
   ```

3. 为helloworld-v1.example.com生成证书和私钥：

   ```shell
   $ openssl req -out helloworld-v1.example.com.csr -newkey rsa:2048 -nodes -keyout helloworld-v1.example.com.key -subj "/CN=helloworld-v1.example.com/O=helloworld organization"
   $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in helloworld-v1.example.com.csr -out helloworld-v1.example.com.crt
   ```

4. 创建 `helloworld-credential` 秘钥:

   ```shell
   $ kubectl create -n istio-system secret tls helloworld-credential --key=helloworld-v1.example.com.key --cert=helloworld-v1.example.com.crt
   ```

5. 为端口443定义一个具有两个服务器部分的网关。将每个端口上的credentialName的值分别设置为httpbin-credential和helloworld-credential。 将TLS模式设置为SIMPLE。

   ```shell
   $ cat <<EOF | kubectl apply -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: Gateway
   metadata:
     name: mygateway
   spec:
     selector:
       istio: ingressgateway # use istio default ingress gateway
     servers:
     - port:
         number: 443
         name: https-httpbin
         protocol: HTTPS
       tls:
         mode: SIMPLE
         credentialName: httpbin-credential
       hosts:
       - httpbin.example.com
     - port:
         number: 443
         name: https-helloworld
         protocol: HTTPS
       tls:
         mode: SIMPLE
         credentialName: helloworld-credential
       hosts:
       - helloworld-v1.example.com
   EOF
   ```

6. 配置网关的流量路由。 定义相应的虚拟服务。

   ```shell
   $ cat <<EOF | kubectl apply -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: VirtualService
   metadata:
     name: helloworld-v1
   spec:
     hosts:
     - helloworld-v1.example.com
     gateways:
     - mygateway
     http:
     - match:
       - uri:
           exact: /hello
       route:
       - destination:
           host: helloworld-v1
           port:
             number: 5000
   EOF
   ```

7. 发送HTTPS请求到helloworld-v1.example.com：

   ```shell
   $ curl -v -HHost:helloworld-v1.example.com --resolve "helloworld-v1.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt "https://helloworld-v1.example.com:$SECURE_INGRESS_PORT/hello"
   HTTP/2 200
   ```

8. 向httpbin.example.com发送HTTPS请求，但仍然得到一个茶壶：

   ```shell
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   ...
   -=[ teapot ]=-
   
      _...._
    .'  _ _ `.
   | ."` ^ `". _,
   \_;`"---"`|//
     |       ;/
     \_     _/
       `"""
   ```



## 为多主机配置 TLS ingress 网关

You can extend your gateway’s definition to support [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication). Change the credentials of the ingress gateway by deleting its secret and creating a new one. The server uses the CA certificate to verify its clients, and we must use the name `cacert` to hold the CA certificate.

```
$ kubectl -n istio-system delete secret httpbin-credential
$ kubectl create -n istio-system secret generic httpbin-credential --from-file=tls.key=httpbin.example.com.key \
--from-file=tls.crt=httpbin.example.com.crt --from-file=ca.crt=example.com.crt
```



1. Change the gateway’s definition to set the TLS mode to `MUTUAL`.

   ```
   $ cat <<EOF | kubectl apply -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: Gateway
   metadata:
    name: mygateway
   spec:
    selector:
      istio: ingressgateway # use istio default ingress gateway
    servers:
    - port:
        number: 443
        name: https
        protocol: HTTPS
      tls:
        mode: MUTUAL
        credentialName: httpbin-credential # must be the same as secret
      hosts:
      - httpbin.example.com
   EOF
   ```

   

2. Attempt to send an HTTPS request using the prior approach and see how it fails:

   ```
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   
   * TLSv1.3 (OUT), TLS handshake, Client hello (1):
   * TLSv1.3 (IN), TLS handshake, Server hello (2):
   * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
   * TLSv1.3 (IN), TLS handshake, Request CERT (13):
   * TLSv1.3 (IN), TLS handshake, Certificate (11):
   * TLSv1.3 (IN), TLS handshake, CERT verify (15):
   * TLSv1.3 (IN), TLS handshake, Finished (20):
   * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
   * TLSv1.3 (OUT), TLS handshake, Certificate (11):
   * TLSv1.3 (OUT), TLS handshake, Finished (20):
   * TLSv1.3 (IN), TLS alert, unknown (628):
   * OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
   ```

   

3. Generate client certificate and private key:

   ```
   $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
   $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
   ```

   

4. Pass a client certificate and private key to `curl` and resend the request. Pass your client’s certificate with the `--cert` flag and your private key with the `--key` flag to `curl`.

   ```
   $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
   --cacert example.com.crt --cert client.example.com.crt --key client.example.com.key \
   "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
   
   ...
   -=[ teapot ]=-
   
      _...._
    .'  _ _ `.
   | ."` ^ `". _,
   \_;`"---"`|//
     |       ;/
     \_     _/
       `"""`
   ```

   

Istio supports reading a few different Secret formats, to support integration with various tools such as [cert-manager](https://istio.io/latest/docs/ops/integrations/certmanager/):

- A TLS Secret with keys `tls.key` and `tls.crt`, as described above. For mutual TLS, a `ca.crt` key can be used.
- A generic Secret with keys `key` and `cert`. For mutual TLS, a `cacert` key can be used.
- A generic Secret with keys `key` and `cert`. For mutual TLS, a separate generic Secret named `<secret>-cacert`, with a `cacret` key. For example, `httpbin-credential` has `key` and `cert`, and `httpbin-credential-cacert` has `cacert`.



## 问题排查

- 检查环境变量 `INGRESS_HOST` 和 `SECURE_INGRESS_PORT` 的值。通过下列命令的输出确保它们都有有效值：

  ```shell
  $ kubectl get svc -n istio-system
  $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
  ```

- 验证 `istio-ingressgateway` pod 已经成功加载了私钥和证书：

  ```shell
  $ kubectl logs -n istio-system "$(kubectl get pod -l istio=ingressgateway \
  -n istio-system -o jsonpath='{.items[0].metadata.name}')"
  ```

- 对于 macOS 用户，验证您是否使用的是用 [LibreSSL](http://www.libressl.org/) 库编译的`curl`，如[开始之前](https://istio.io/latest/zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/#before-you-begin)部分中所述。

- 验证秘钥已在“ istio-system”名称空间中成功创建：

  ```shell
  $ kubectl -n istio-system get secrets
  ```

  `httpbin-credential` 和 `helloworld-credential` 需要显示在秘钥列表.

- 检查日志以确认入口网关代理已将密钥/证书对推送到入口网关。

  ```
  $ kubectl logs -n istio-system "$(kubectl get pod -l istio=ingressgateway \
  -n istio-system -o jsonpath='{.items[0].metadata.name}')"
  ```

  

  日志应显示已添加“ httpbin-credential”密钥。 如果使用双向TLS，则还将出现“ httpbin-credential-cacert”密钥。 验证日志是否显示网关代理收到来自入口网关的SDS请求，资源名称为“ httpbin-credential”，以及入口网关已获得密钥/证书对。 如果使用双向TLS，则日志应显示密钥/证书已发送到入口网关，网关代理已收到带有“ httpbin-credential-cacert”资源名称的SDS请求，并且入口网关已获得根证书。



## 清理

1. 删除 `Gateway` 配置、`VirtualService` 和 secrets：

   ```shell
   $ kubectl delete gateway mygateway
   $ kubectl delete virtualservice httpbin
   $ kubectl delete --ignore-not-found=true -n istio-system secret httpbin-credential \
   helloworld-credential
   $ kubectl delete --ignore-not-found=true virtualservice helloworld-v1
   ```

2. 删除证书目录和用于生成证书的存储库：

   ```shell
   $ rm -rf example.com.crt example.com.key httpbin.example.com.crt httpbin.example.com.key httpbin.example.com.csr helloworld-v1.example.com.crt helloworld-v1.example.com.key helloworld-v1.example.com.csr client.example.com.crt client.example.com.csr client.example.com.key ./new_certificates
   ```

3. 关闭 [httpbin](https://github.com/istio/istio/tree/release-1.6/samples/httpbin) 和 `helloworld-v1`服务：

   ```
   $ kubectl delete deployment --ignore-not-found=true httpbin helloworld-v1
   $ kubectl delete service --ignore-not-found=true httpbin helloworld-v1
   ```













