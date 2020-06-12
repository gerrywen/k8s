# 了解Kubernetes对象

### 描述Kubernetes对象

在Kubernetes中创建对象时，必须提供描述其所需Status的对象Spec，以及关于对象（如name）的一些基本信息。当使用Kubernetes API创建对象（直接或通过kubectl）时，该API请求必须将该信息作为JSON包含在请求body中。通常，可以将信息提供给kubectl .yaml文件，在进行API请求时，kubectl将信息转换为JSON。

- 以下示例是一个.yaml文件，显示Kubernetes Deployment所需的字段和对象Spec：

  `nginx-deployment.yaml`

  ```yaml
  apiVersion: apps/v1beta1
  kind: Deployment
  metadata:
    name: nginx-deployment
  spec:
    replicas: 3
    template:
      metadata:
        labels:
          app: nginx
      spec:
        containers:
        - name: nginx
          image: hub.gerrywen.com/library/nginx:1.7.9
          ports:
          - containerPort: 80
  ```

- 使用上述.yaml文件创建Deployment，是通过在kubectl中使用`kubectl create`或`kubectl apply`命令来实现。将该.yaml文件作为参数传递。创建 Deployment 的时候使用了--recored参数可以记录命令，我们可以很方便的查看每次 revision 的变化。

  如下例子：

  ```shell
  kubectl create -f nginx-deployment.yaml --record
  ```

  ```shell
  kubectl apply -f nginx-deployment.yaml --record
  ```



- 查看运行状态

  ```shell
  kubectl get deployments
  kubectl get rs
  kubectl get pods
  ```

  ```shell
  kubectl get deployment,pod
  ```

  ```shell
  kubectl get deployment,pod -o wide
  ```

  ```shell
  [root@k8s-master01 01]# kubectl get deployment,pod
  NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
  deployment.extensions/nginx-deployment   3/3     3            3           17s
  
  NAME                                    READY   STATUS    RESTARTS   AGE
  pod/nginx-deployment-66857fdd4c-2fbzh   1/1     Running   0          17s
  pod/nginx-deployment-66857fdd4c-h87l7   1/1     Running   0          17s
  pod/nginx-deployment-66857fdd4c-x7pwf   1/1     Running   0          17s
  [root@k8s-master01 01]# kubectl get deployment,pod -o wide
  NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                 SELECTOR
  deployment.extensions/nginx-deployment   3/3     3            3           23s   nginx        hub.gerrywen.com/library/nginx:1.7.9   app=nginx
  
  NAME                                    READY   STATUS    RESTARTS   AGE   IP             NODE         NOMINATED NODE   READINESS GATES
  pod/nginx-deployment-66857fdd4c-2fbzh   1/1     Running   0          23s   10.244.2.105   k8s-node01   <none>           <none>
  pod/nginx-deployment-66857fdd4c-h87l7   1/1     Running   0          23s   10.244.2.106   k8s-node01   <none>           <none>
  pod/nginx-deployment-66857fdd4c-x7pwf   1/1     Running   0          23s   10.244.1.100   k8s-node02   <none>           <none>
  ```

- 请求ip地址,默认80端口

  ```shell
  curl 10.244.2.105
  ```

  ```shell
  [root@k8s-master01 01]# curl 10.244.2.105
  <!DOCTYPE html>
  <html>
  <head>
  <title>Welcome to nginx!</title>
  <style>
      body {
          width: 35em;
          margin: 0 auto;
          font-family: Tahoma, Verdana, Arial, sans-serif;
      }
  </style>
  </head>
  <body>
  <h1>Welcome to nginx!</h1>
  <p>If you see this page, the nginx web server is successfully installed and
  working. Further configuration is required.</p>
  
  <p>For online documentation and support please refer to
  <a href="http://nginx.org/">nginx.org</a>.<br/>
  Commercial support is available at
  <a href="http://nginx.com/">nginx.com</a>.</p>
  
  <p><em>Thank you for using nginx.</em></p>
  </body>
  </html>
  ```

- 命令进行扩(缩)容：

  ```shell
  kubectl scale deployment nginx-deployment --replicas 10
  ```

  ```shell
  kubectl scale deployment nginx-deployment --replicas=2
  ```

  假设您的集群中启用了[horizontal pod autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough)，您可以给 Deployment 设置一个 autoscaler，基于当前 Pod的 CPU 利用率选择最少和最多的 Pod 数

  ```shell
  kubectl autoscale deployment nginx-deployment --min=10 --max=15 --cpu-percent=80
  ```

  如果使用了自动扩容，我们可以通过运行来检查autoscaler的当前状态：

  ```shell
  kubectl get hpa
  kubectl describe hpa <name>
  kubectl delete hpa <name>
  ```

- 删除Deployment:

  ```shell
  kubectl delete -f nginx-deployment.yaml 
  ```

  

#### Deployment 升级、回退

- 更新了一个镜像

  ```shell
  kubectl set image deploy/nginx-deployment nginx=hub.gerrywen.com/library/nginx:1.9.1
  ```

  ```shell
  [root@k8s-master01 01]# kubectl get pod
  NAME                                READY   STATUS        RESTARTS   AGE
  nginx-deployment-66857fdd4c-pqzg4   0/1     Terminating   0          10m
  nginx-deployment-c9dd6fd77-98bdr    1/1     Running       0          13s
  nginx-deployment-c9dd6fd77-wltt9    1/1     Running       0          15s
  [root@k8s-master01 01]# kubectl get pod
  NAME                               READY   STATUS    RESTARTS   AGE
  nginx-deployment-c9dd6fd77-98bdr   1/1     Running   0          16s
  nginx-deployment-c9dd6fd77-wltt9   1/1     Running   0          18s
  ```

  镜像更新启动了一个包含ReplicaSet nginx-deployment-c9dd6fd77 的新的rollout

  ```shell
  kubectl get rs -o wide
  ```

  ```shell
  [root@k8s-master01 01]# kubectl get rs -o wide
  NAME                          DESIRED   CURRENT   READY   AGE    CONTAINERS   IMAGES  SELECTOR
  nginx-deployment-66857fdd4c   0         0         0       11m    nginx        hub.gerrywen.com/library/nginx:1.7.9   app=nginx,pod-template-hash=66857fdd4c
  
  nginx-deployment-c9dd6fd77    2         2         2       118s   nginx        hub.gerrywen.com/library/nginx:1.9.1   app=nginx,pod-template-hash=c9dd6fd77
  [root@k8s-master01 01]# 
  
  ```

  

- 检查 Deployment 升级的历史记录

  ```shell
  kubectl rollout history deployment/nginx-deployment
  ```

  ```shell
  [root@k8s-master01 01]# kubectl rollout history deployment/nginx-deployment
  deployment.extensions/nginx-deployment 
  REVISION  CHANGE-CAUSE
  1         kubectl apply --filename=nginx-deployment.yaml --record=true
  2         kubectl apply --filename=nginx-deployment.yaml --record=true
  ```

  查看版本的具体信息：

  ```shell
  kubectl rollout history deployment/nginx-deployment --revision=2
  ```

  ```shell
  [root@k8s-master01 01]# kubectl rollout history deployment/nginx-deployment --revision=2
  deployment.extensions/nginx-deployment with revision #2
  Pod Template:
    Labels:	app=nginx
  	pod-template-hash=c9dd6fd77
    Annotations:	kubernetes.io/change-cause: kubectl apply --filename=nginx-deployment.yaml --record=true
    Containers:
     nginx:
      Image:	hub.gerrywen.com/library/nginx:1.9.1
      Port:	80/TCP
      Host Port:	0/TCP
      Environment:	<none>
      Mounts:	<none>
    Volumes:	<none>
  ```

- 回退到历史版本

  ```shell
  kubectl rollout undo deployment/nginx-deployment --to-revision=1
  ```

#### 暂停和恢复Deployment

- 命令暂停 Deployment

  ```shell
  kubectl rollout pause deployment/nginx-deployment
  ```

- 恢复这个 Deployment，观察完成更新的 ReplicaSet 已经创建出来了

  ```shell
  kubectl rollout resume deployment/nginx-deployment
  ```

  



### Deployment 状态

Deployment 在生命周期中有多种状态。在创建一个新的 ReplicaSet 的时候它可以是 [progressing](https://kubernetes.io/docs/concepts/workloads/controllers/deployment.md#progressing-deployment) 状态， [complete](https://kubernetes.io/docs/concepts/workloads/controllers/deployment.md#complete-deployment) 状态，或者 [fail to progress ](https://kubernetes.io/docs/concepts/workloads/controllers/deployment.md#failed-deployment)状态。

- #### 进行中的 Deployment

  Kubernetes 将执行过下列任务之一的 Deployment 标记为 progressing 状态：

  - Deployment 正在创建新的ReplicaSet过程中。
  - Deployment 正在扩容一个已有的 ReplicaSet。
  - Deployment 正在缩容一个已有的 ReplicaSet。
  - 有新的可用的 pod 出现。

  使用kubectl rollout status命令监控 Deployment 的进度。

  ```shell
  kubectl rollout status deployment/nginx-deployment
  ```

  

- #### 完成的 Deployment

  ```
  Kubernetes 将包括以下特性的 Deployment 标记为 complete 状态：
  Deployment 最小可用。
  最小可用意味着 Deployment 的可用 replica 个数等于或者超过 Deployment 策略中的期望个数。
  所有与该 Deployment 相关的replica都被更新到了您指定版本，也就说更新完成。
  该 Deployment 中没有旧的 Pod 存在。
  ```

  

- #### 失败的 Deployment

  Deployment 在尝试部署新的 ReplicaSet 的时候可能卡住，用于也不会完成。这可能是因为以下几个因素引起的：

  - （1）无效的引用
  - （2）不可读的 probe failure
  - （3）镜像拉取错误
  - （4）权限不够
  - （5）范围限制
  - （6）程序运行时配置错误



### 必填字段

对于要创建的Kubernetes对象的yaml文件，需要为以下字段设置值：

- apiVersion - 创建对象的Kubernetes API 版本
- kind - 要创建什么样的对象？
- metadata- 具有唯一标示对象的数据，包括 name（字符串）、UID和Namespace（可选项）

还需要提供对象Spec字段，对象Spec的精确格式（对于每个Kubernetes 对象都是不同的），以及容器内嵌套的特定于该对象的字段。[Kubernetes API reference](https://kubernetes.io/docs/api/)可以查找所有可创建Kubernetes对象的Spec格式。







