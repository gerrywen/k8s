## Helm 基本用法

这里以制作一个简单的网站应用chart包为例子介绍helm的基本用法。

**这里跳过docker镜像制作过程，镜像制作可以参考Docker基础教程**



### 参考资料

- [[Helm教程](https://www.cnblogs.com/lyc94620/p/10945430.html)]
- **[Docker基础教程](https://www.cnblogs.com/lyc94620/p/10758219.html)**



### 1.1.创建chart包

通过helm create命令创建一个新的chart包

例子:在当前目录创建一个myapp chart包

```shell
helm create myapp
```

创建完成后，得到的目录结构如下:

```shell
myapp                                   - chart 包目录名
├── charts                              - 依赖的子包目录，里面可以包含多个依赖的chart包
├── Chart.yaml                          - chart定义，可以定义chart的名字，版本号信息。
├── templates                           - k8s配置模版目录， 我们编写的k8s配置都在这个目录， 除了NOTES.txt和下划线开头命名																					的文件，其他文件可以随意命名。
│   ├── deployment.yaml
│   ├── _helpers.tpl                    - 下划线开头的文件，helm视为公共库定义文件，主要用于定义通用的子模版、函数等，helm不																						会将这些公共库文件的渲染结果提交给k8s处理。
│   ├── ingress.yaml
│   ├── NOTES.txt                       - chart包的帮助信息文件，执行helm install命令安装成功后会输出这个文件的内容。
│   └── service.yaml
└── values.yaml                         - chart包的参数配置文件，模版可以引用这里参数。
```

我们要在k8s中部署一个网站应用，需要编写**deployment、service、ingress**三个配置文件，刚才通过helm create命令已经创建好了。



### 1.2.编写k8s应用部署配置文件

演示chart包模版的用法，我们先把**deployment、service、ingress**三个配置文件的内容清空，重新编写k8s部署文件。

**deployment.yaml 配置文件定义如下：**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
	# deployment应用名
  name: myapp           
  labels:
  	# deployment应用标签定义
    app: myapp          
spec:
  # pod副本数
  replicas: 1          
  selector:
    matchLabels:
      # pod选择器标签
      app: myapp          
  template:
    metadata:
      labels:
        # pod标签定义
        app: myapp          
    spec:
      containers:
        # 容器名
        - name: myapp
          # 镜像地址
          image: xxxxxx:1.7.9    
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
```



**service.yaml定义如下：**

```yaml
apiVersion: v1
kind: Service
metadata:
   # 服务名
  name: myapp-svc
spec:
  # pod选择器定义
  selector: 
    app: myapp
  ports:
  - protocol: TCP 
    port: 80
    targetPort: 80
```



**ingress.yaml定义如下：**

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  # ingress应用名
  name: myapp-ingress 
spec:
  rules:
    # 域名
    - host: www.xxxxx.com  
      http:
        paths: 
          - path: /  
            backend: 
              # 服务名
              serviceName: myapp-svc
              servicePort: 80
```

上面已经完成k8s应用部署配置文件的编写。



### 1.3.提取k8s应用部署配置文件中的参数，作为chart包参数

**为什么要提取上面配置文件中的参数，作为chart包的参数？**

```
因为我们制作好一个chart包之后，如实现chart包更具有通用性，我们如何换域名？换镜像地址？改一下应用部署的名字？  部署多套环境（例如：dev环境、test环境分别以不同的应用名字部署一套）
```

**1.2定义的k8s配置文件**还不能称之为模版，都是固定的配置。**（这里所说的模版就类似大家平时做前端开发的时候用的模版技术是一个概念）**

我们通过提**取配置中的参数**，**注入模版变量，模版表达式**将配置文件转化为**模版文件**，helm在运行的时候**根据参数动态的将模版文件**渲染成最终的配置文件。



下面将**deployment、service、ingress**三个配置文件转换成模版文件。

- **{{  }} 两个花括号包裹的内容为模版表达式，具体含义。** 参考：[03-Helm chart语法.md](./03-Helm chart语法.md)



**deployment.yaml 配置模版如下：**

```yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  # deployment应用名 
  name: {{ .Release.Name }}  								
  labels:
    # deployment应用标签定义
    app: {{ .Release.Name }}          			
spec:
  # pod副本数
  replicas: {{ .Values.replicas}}           
  selector:
    matchLabels:
      # pod选择器标签
      app: {{ .Release.Name }}          		
  template:
    metadata:
      labels:
        # pod标签定义
        app: {{ .Release.Name }}            
    spec:
      containers:
        # 容器名
        - name: {{ .Release.Name }}  
          # 镜像地址
          image: {{ .Values.image }}:{{ .Values.imageTag }}    
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
```



**service.yaml定义如下：**

```yaml
apiVersion: v1
kind: Service
metadata:
  # 服务名
  name: {{ .Release.Name }}-svc 	
spec:
  # pod选择器定义
  selector: 											
    app: {{ .Release.Name }}
  ports:
  - protocol: TCP 
    port: 80
    targetPort: 80
```



**ingress.yaml定义如下：**

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  # ingress应用名 
  name: {{ .Release.Name }}-ingress 								
spec:
  rules:
    # 域名
    - host: {{ .Values.host }}  										
      http:
        paths: 
          - path: /  
            backend: 
              # 服务名
              serviceName: {{ .Release.Name }}-svc 
              servicePort: 80
```



##### values.yaml chart包参数定义：

```yaml
#域名
host: test.gerrywen.com
 
#镜像参数
image: hub.gerrywen.com/library/myapp
imageTag: v1

#pod 副本数
replicas: 1

```



##### 使用 Helm lint 来粗略地检查一下制作的 Chart 有没有什么语法上的错误

```shell
 helm lint --strict ./myapp
```





### 1.4.通过helm命令安装/更新应用

- **安装应用:**命令格式: helm install  chart包目录

  ```shell
   helm install ./myapp
  ```

  指定名称和命名空间运行，方便查找

  ```shell
  helm install  --name demo-myapp --namespace myapp ./myapp
  ```

  查看svc,pod运行状态

  ```shell
  kubectl get svc,pod -o wide -n myapp
  ```

  

  查看ingress运行状态

  ```shell
   kubectl get ingresses. -n myapp
  ```

- ##### 删除应用

  通过helm list -a查看已部署的release

  ```shell
  helm list
  ```

  通过helm del普通删除：

  ```shell
  helm del demo-myapp
  ```

  通过helm status查看release状态：

  ```
  helm status demo-myapp
  ```

  通过helm list -a查看全部的release，tag “-a”是查看全部的release，包括已部署、部署失败、正在删除、已删除release等。

  ```shell
  helm list -a
  ```

  如果希望彻底删除一个release，可以用如下命令：

  ```shell
  helm delete --purge demo-myapp
  ```

  再次查看刚被删除的mysql release，提示已经无法找到，符合预期：

  ```shell
  helm list -a
  helm hist demo-myapp
  ```

  

- **通过命令注入参数**

  - 命令格式: helm install  --set key=value   chart包目录
  - --set 参数可以指定多个参数，他的值会覆盖values.yaml定义的值，对象类型数据可以用 . (点)分割属性名,例子:  --set apiAppResources.requests.cpu=1

  ```shell
  helm install --set replicas=2 --set host=test.gerrywen.com ./myapp
  ```

  ```shell
  helm install --name demo-myapp --namespace myapp --set replicas=2 --set host=test.gerrywen.com ./myapp
  ```

  查看运行状态

  ```yaml
  [root@k8s-master01 demo]# kubectl get svc,pod -o wide -n myapp
  NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
  service/demo-myapp-svc   ClusterIP   10.98.118.228   <none>        80/TCP    12s   app=demo-myapp
  
  NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE         NOMINATED NODE   READINESS GATES
  pod/demo-myapp-7cbd4bb8dd-9gf9w   1/1     Running   0          12s   10.244.2.161   k8s-node01   <none>           <none>
  pod/demo-myapp-7cbd4bb8dd-dxm4m   1/1     Running   0          12s   10.244.1.152   k8s-node02   <none>           <none>
  ```

  

- ##### 版本回滚

  回滚到第一次的版本：

  ```shell
  helm rollback --debug demo-myapp 1
  ```

  ```shell
  [root@k8s-master01 demo]# helm rollback --debug demo-myapp 1
  [debug] Created tunnel using local port: '36811'
  
  [debug] SERVER: "127.0.0.1:36811"
  
  Rollback was a success! Happy Helming!
  ```

  再次查看helm list版本数

  ```shell
  helm hist demo-myapp
  ```

  ```shell
  [root@k8s-master01 demo]# helm list
  NAME                	REVISION	UPDATED                 	STATUS  	CHART                     	APP VERSION	NAMESPACE  
  demo-myapp          	2       	Sat Jun  6 17:54:24 2020	DEPLOYED	myapp-0.1.0               	1.0        	myapp 
  ```

  

- **更新应用：命令格式: helm upgrade release名字  chart包目录**

  ```shell
  helm upgrade myapp ./myapp
  ```

  - 也可以指定--set参数

    ```shell
    helm upgrade --set replicas=2 --set host=test.gerrywen.com demo-myapp ./myapp
    ```

    ```shell
    helm upgrade --set replicas=5 --set host=test.gerrywen.com demo-myapp ./myapp
    ```

    更新分片完的状态

    ```shell
    [root@k8s-master01 demo]# kubectl get svc,pod -o wide -n myapp
    NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
    service/demo-myapp-svc   ClusterIP   10.98.118.228   <none>        80/TCP    94s   app=demo-myapp
    
    NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE         NOMINATED NODE   READINESS GATES
    pod/demo-myapp-7cbd4bb8dd-4g6lj   1/1     Running   0          4s    10.244.2.162   k8s-node01   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-9gf9w   1/1     Running   0          94s   10.244.2.161   k8s-node01   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-dxm4m   1/1     Running   0          94s   10.244.1.152   k8s-node02   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-qb4rs   1/1     Running   0          4s    10.244.1.153   k8s-node02   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-vgvbg   1/1     Running   0          4s    10.244.1.154   k8s-node02   <none>           <none>
    ```

    更新镜像版本

    ```shell
    helm upgrade --set replicas=2 --set imageTag=v3 demo-myapp ./myapp
    ```

    查看状态，可以看到关闭一些pod

    ```shell
    [root@k8s-master01 demo]# kubectl get svc,pod -o wide -n myapp
    NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     SELECTOR
    service/demo-myapp-svc   ClusterIP   10.98.118.228   <none>        80/TCP    4m21s   app=demo-myapp
    
    NAME                              READY   STATUS        RESTARTS   AGE     IP             NODE         NOMINATED NODE   READINESS GATES
    pod/demo-myapp-6c8c55cf54-q7l9q   1/1     Running       0          5s      10.244.1.155   k8s-node02   <none>           <none>
    pod/demo-myapp-6c8c55cf54-qpgj9   1/1     Running       0          7s      10.244.2.163   k8s-node01   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-qb4rs   0/1     Terminating   0          2m51s   10.244.1.153   k8s-node02   <none>           <none>
    pod/demo-myapp-7cbd4bb8dd-vgvbg   0/1     Terminating   0          2m51s   10.244.1.154   k8s-node02   <none>           <none>
    [root@k8s-master01 demo]# kubectl get svc,pod -o wide -n myapp
    NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     SELECTOR
    service/demo-myapp-svc   ClusterIP   10.98.118.228   <none>        80/TCP    4m23s   app=demo-myapp
    
    NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE         NOMINATED NODE   READINESS GATES
    pod/demo-myapp-6c8c55cf54-q7l9q   1/1     Running   0          7s    10.244.1.155   k8s-node02   <none>           <none>
    pod/demo-myapp-6c8c55cf54-qpgj9   1/1     Running   0          9s    10.244.2.163   k8s-node01   <none>           <none>
    ```

    

  - 默认情况下，如果release名字不存在，upgrade会失败，可以加上-i 参数当release不存在的时候则安装，存在则更新，将install和uprade命令合并。

    ```shell
    helm upgrade  -i --set replicas=2 --set host=test.gerrywen.com demo-myapp ./myapp
    ```

  

  

- ### 1.5调试

  编写好chart包的模版之后，我们可以给helm命令加上--debug --dry-run 两个参数，**让helm输出模版结果，但是不把模版输出结果交给k8s处理**

  ```shell
  helm install --debug --dry-run --set replicas=2 --set host=test.gerrywen.com ./myapp 
  ```

  ```shell
  helm install --name demo-myapp --namespace myapp  --debug --dry-run --set replicas=2 --set host=test.gerrywen.com ./myapp
  ```

  

  ```shell
  helm upgrade --debug --dry-run -i --set replicas=5 --set host=test.gerrywen.com  myapp ./myapp
  ```

