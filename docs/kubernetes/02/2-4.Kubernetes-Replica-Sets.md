# Kubernetes Replica Sets

ReplicaSet（RS）是Replication Controller（RC）的升级版本。ReplicaSet 和  [Replication Controller](http://docs.kubernetes.org.cn/437.html)之间的唯一区别是对选择器的支持。ReplicaSet支持[labels user guide](http://docs.kubernetes.org.cn/247.html#Labels)中描述的set-based选择器要求， 而Replication Controller仅支持equality-based的选择器要求。

### 如何使用ReplicaSet

大多数[kubectl](http://docs.kubernetes.org.cn/61.html) 支持Replication Controller 命令的也支持ReplicaSets。[rolling-update](https://kubernetes.io/docs/user-guide/kubectl/v1.7/#rolling-update)命令除外，如果要使用rolling-update，请使用Deployments来实现。

虽然ReplicaSets可以独立使用，但它主要被 [Deployments](http://docs.kubernetes.org.cn/317.html)用作pod 机制的创建、删除和更新。当使用Deployment时，你不必担心创建pod的ReplicaSets，因为可以通过Deployment实现管理ReplicaSets。



### 何时使用ReplicaSet

ReplicaSet能确保运行指定数量的pod。然而，Deployment 是一个更高层次的概念，它能管理ReplicaSets，并提供对pod的更新等功能。因此，我们建议你使用Deployment来管理ReplicaSets，除非你需要自定义更新编排。

这意味着你可能永远不需要操作ReplicaSet对象，而是使用Deployment替代管理 。



### 示例：ReplicaSet的创建

- [myapp-rs.yaml](./myapp-rs.yaml)

  ```yaml
  apiVersion: apps/v1
  kind: ReplicaSet
  metadata:
    name: frontend
    labels:
      app: guestbook
      tier: frontend
  spec:
    # this replicas value is default
    # modify it according to your case
    replicas: 2
    selector:
      matchLabels:
        tier: frontend
      matchExpressions:
        - {key: tier, operator: In, values: [frontend]}
    template:
      metadata:
        labels:
          app: guestbook
          tier: frontend
      spec:
        containers:
          - name: myapp-container
            image: hub.gerrywen.com/library/myapp:v1
            ports:
              - name: http
                containerPort: 80
  ```

  下面简要解释一下上述RS描述文件中的关键点：

  	-  kind：指定新建的对象类型。
  	-  spec.replicas：指定受此RS管理的Pod需要运行的副本数。
  	-  spec.selector：指定需要管理的Pod的label。这儿将spec.selector设置为app: myapp和release: cannary，意味着所有包含label为app: myapp和release: cannary的Pod都将被这个RS管理。
  	-  template：用于定义Pod，包括Pod的名字，Pod拥有的label以及Pod中运行的应用。

  

- 运行rs

  ```shell
  kubectl create -f myapp-rs.yaml 
  ```

- 通过`kubectl create`创建此RS，可看到分别在node02和node03节点创建了pod，并且pod也打上了app=myapp,environment=qa,release=cannary标签

  ```shell
  [root@k8s-master01 02]# kubectl get pods --show-labels
  NAME          READY   STATUS      RESTARTS   AGE    LABELS
  myapp-8pq5s   1/1     Running     0          10m    app=guestbook,tier=frontend
  myapp-mjs2r   1/1     Running     0          10m    app=guestbook,tier=frontend
  ```

- 当使用`kubectl delete`删除其中一个pod后，会立即重新创建一个新的pod，以确保pod以指定的副本数运行

  ```shell
  kubectl delete pods myapp-8pq5s
  ```

  ```shell
  [root@k8s-master01 02]# kubectl get pods --show-labels
  NAME          READY   STATUS      RESTARTS   AGE    LABELS
  myapp-kt7ws   1/1     Running     0          27s    app=guestbook,tier=frontend
  myapp-mjs2r   1/1     Running     0          12m    app=guestbook,tier=frontend
  ```

  

### ReplicaSet的删除

使用`kubectl delete`命令可以删除RS以及它管理的Pod。在Kubernetes删除RS前，会将RS的replica调整为0，等待所有的Pod被删除后，在执行RS对象的删除。

```shell
kubectl get rs
```

```shell
kubectl delete rs myapp
```

```shell
kubectl get pods
```

```shell
[root@k8s-master01 02]# kubectl get rs
NAME    DESIRED   CURRENT   READY   AGE
myapp   2         2         2       14m
[root@k8s-master01 02]# 
[root@k8s-master01 02]# kubectl delete rs myapp
replicaset.extensions "myapp" deleted
[root@k8s-master01 02]# kubectl get pods
NAME          READY   STATUS        RESTARTS   AGE
myapp-mjs2r   0/1     Terminating   0          15m
myapp-p7wgq   0/1     Terminating   0          2m52s
ubuntu        0/1     Completed     0          170m
[root@k8s-master01 02]# kubectl get pods
NAME     READY   STATUS      RESTARTS   AGE
ubuntu   0/1     Completed   0          170m
[root@k8s-master01 02]# 

```

如果希望仅仅删除RS对象（保留Pod），请使用kubectl delete命令时添加--cascade=false选项。



### ReplicaSet as an Horizontal Pod Autoscaler target

RS可以通过HPA来根据一些运行时指标实现自动伸缩，下面是一个简单的例子：

- [hpa-rs.yaml](./hpa-rs.yaml)

  ```yaml
  apiVersion: autoscaling/v1
  kind: HorizontalPodAutoscaler
  metadata:
    name: frontend-scaler
  spec:
    scaleTargetRef:
      kind: ReplicaSet
      name: frontend
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 50
  ```

  上面的描述文件会创建一个名为frontend-scaler的HorizontalPodAutoscaler，它会根据CPU的运行参数来对名为frontend的RS进行自动伸缩。

  

- 删除hpa

  ```shell
  kubectl delete -f hpa-rs.yaml 
  ```

  

- 普通扩（缩）容

  ```yaml
   kubectl scale  rs frontend --replicas 10
   kubectl scale  rs frontend --replicas 2
  ```

  



