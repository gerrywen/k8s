# Kubernetes Annotations

可以使用Kubernetes Annotations将任何非标识metadata附加到对象。客户端（如工具和库）可以检索此metadata。

### 将metadata附加到对象

可以使用[Labels](http://docs.kubernetes.org.cn/247.html)或Annotations将元数据附加到Kubernetes对象。标签可用于选择对象并查找满足某些条件的对象集合。相比之下，Annotations不用于标识和选择对象。Annotations中的元数据可以是small 或large，structured 或unstructured，并且可以包括标签不允许使用的字符。



### 写法特点

注释是键/值对。有效的注释键有两个段：可选的前缀和名称，用斜线（/）分隔。名称段是必需的，必须不超过63个字符，以字母数字字符（[A-Z0-9A-Z]）开头和结尾，中间有破折号（-）、下划线（u）、点（.）和字母数字。前缀是可选的。如果指定，前缀必须是DNS子域：由点（.）分隔的一系列DNS标签，总共不超过253个字符，后跟斜杠（/）。

如果省略前缀，则注释键被假定为用户专用。向最终用户对象添加注释的自动化系统组件（例如kube调度器、kube控制器管理器、kube apiserver、kubectl或其他第三方自动化）必须指定前缀。

kubernetes.io/和k8s.io/前缀是为kubernetes核心组件保留的。

```
beta.kubernetes.io/arch=amd64
beta.kubernetes.io/os=linux
kubernetes.io/hostname=ip-172-20-114-199.ec2.internal
```



### 用法

Annotations就如标签一样，也是由key/value组成：

```json
"annotations": {
  "key1" : "value1",
  "key2" : "value2"
}
```

以下是在Annotations中记录信息的一些例子：

- 构建、发布的镜像信息，如时间戳，发行ID，git分支，PR编号，镜像hashes和注Registry地址。
- 一些日志记录、监视、分析或audit repositories。
- 一些工具信息：例如，名称、版本和构建信息。
- 用户或工具/系统来源信息，例如来自其他生态系统组件对象的URL。
- 负责人电话/座机，或一些信息目录。

**注意**：Annotations不会被Kubernetes直接使用，其主要目的是方便用户阅读查找。

##### Pod写法举例:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: annotations-demo
  annotations:
    imageregistry: "https://hub.docker.com/"
spec:
  containers:
  - name: nginx
    image: nginx:1.7.9
    ports:
    - containerPort: 80
```

##### istio举例:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: istio-manager
spec:
  replicas: 1
  template:
    metadata:
      annotations:
        alpha.istio.io/sidecar: ignore
      labels:
        istio: manager
    spec:
      serviceAccountName: istio-manager-service-account
      containers:
      - name: discovery
        image: harbor-001.jimmysong.io/library/manager:0.1.5
        imagePullPolicy: Always
        args: ["discovery", "-v", "2"]
        ports:
        - containerPort: 8080
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
      - name: apiserver
        image: harbor-001.jimmysong.io/library/manager:0.1.5
        imagePullPolicy: Always
        args: ["apiserver", "-v", "2"]
        ports:
        - containerPort: 8081
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
```

