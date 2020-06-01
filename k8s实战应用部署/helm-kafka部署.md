## helm在k8s上部署kafka

- 参考资料

  - ##### [Helm 安装Kafka](https://www.cnblogs.com/hongdada/p/11424579.html) [推荐 stable/kafka-manager ]

  - ##### [使用helm在k8s上部署kafka](https://www.cnblogs.com/skgoo/p/11971883.html) [helm自动部署]

  - ##### [在kubernetes上部署zookeeper,kafka集群](https://www.cnblogs.com/xuliang666/p/11847270.html)  [手动部署]

  - ##### [https://github.com/helm/charts/tree/master/incubator/kafka](https://github.com/helm/charts/tree/master/incubator/kafka)

### 创建Kafka和Zookeeper的Local PV

- ##### 创建Kafka的Local PV

  这里的部署环境是本地的测试环境，存储选择Local Persistence Volumes。首先，在k8s集群上创建本地存储的StorageClass

  `local-storage.yaml`：

  ```yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: local-storage
  provisioner: kubernetes.io/no-provisioner
  volumeBindingMode: WaitForFirstConsumer
  reclaimPolicy: Retain
  ```

  ```shell
  kubectl apply -f local-storage.yaml 
  ```

  ```shell
  kubectl get sc --all-namespaces -o wide
  ```

  这里要在`k8s-master01`,`k8s-node01`,`k8s-node02`这三个k8s节点上部署3个kafka的broker节点，因此先在三个节点上创建这3个kafka broker节点的Local PV

  `kafka-local-pv.yaml`:

  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-0
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/data-0
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-master01
  ---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-1
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/data-1
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node01
  ---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-2
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/data-2
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node02
  ```

  - 根据上面创建的local pv
    - 在`k8s-master01`上创建目录`/home/kafka/data-0`
    - 在`k8s-node01`上创建目录`/home/kafka/data-1`
    - 在`k8s-node02`上创建目录`/home/kafka/data-2`

  ```shell
  kubectl apply -f kafka-local-pv.yaml
  ```

- ##### 创建Zookeeper的Local PV

  这里要在`k8s-master01`,`k8s-node01`,`k8s-node02`这三个k8s节点上部署3个zookeeper节点，因此先在三个节点上创建这3个zookeeper节点的Local PV

  `zookeeper-local-pv.yaml`:

  ```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-zookeeper-0
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/zkdata-0
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-master01
  ---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-zookeeper-1
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/zkdata-1
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node01
  ---
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-kafka-zookeeper-2
  spec:
    capacity:
      storage: 5Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/kafka/zkdata-2
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node02
  ```

  - 根据上面创建的local pv
    - 在`k8s-master01`上创建目录`/home/kafka/zkdata-0`
    - 在`k8s-node01`上创建目录`/home/kafka/zkdata-1`
    - 在`k8s-node02`上创建目录`/home/kafka/zkdata-2`

  ```shell
  kubectl apply -f zookeeper-local-pv.yaml
  ```

  ```shell
  kubectl get pv,pvc --all-namespaces
  ```

### 部署Kafka

​    编写kafka chart的vaule文件

​	`kafka-values.yaml`:

```yaml
replicas: 3
tolerations:
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: NoSchedule
- key: node-role.kubernetes.io/master
  operator: Exists
  effect: PreferNoSchedule
persistence:
  storageClass: local-storage
  size: 5Gi
zookeeper:
  persistence:
    enabled: true
    storageClass: local-storage
    size: 5Gi
  replicaCount: 3
  tolerations:
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: NoSchedule
  - key: node-role.kubernetes.io/master
    operator: Exists
    effect: PreferNoSchedule
```

```shell
helm install --name kafka --namespace kafka -f kafka-values.yaml incubator/kafka 
```

- 问题处理

  ```shell
  [root@k8s-master01 helm-kafka]# kubectl get pod -n kafka
  NAME                READY   STATUS             RESTARTS   AGE
  kafka-0             0/1     ErrImagePull       0          7m13s
  kafka-zookeeper-0   0/1     ImagePullBackOff   0          7m13s
  ```

  ```shell
  kubectl describe pod -n kafka kafka-0
  
  sponse from daemon: Get https://registry-1.docker.io/v2/: net/http: TLS handshake timeout
    Warning  Failed     17s (x2 over 4m36s)   kubelet, k8s-master01  Error: ErrImagePull
    Normal   BackOff    5s (x2 over 4m35s)    kubelet, k8s-master01  Back-off pulling image "confluentinc/cp-kafka:5.0.1"
    Warning  Failed     5s (x2 over 4m35s)    kubelet, k8s-master01  Error: ImagePullBackOff
  ```

  ```shell
  kubectl describe pod -n kafka kafka-zookeeper-0
  
  aemon: Get https://registry-1.docker.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
    Normal   BackOff    1s (x3 over 2m11s)   kubelet, k8s-master01  Back-off pulling image "zookeeper:3.5.5"
    Warning  Failed     1s (x3 over 2m11s)   kubelet, k8s-master01  Error: ImagePullBackOff
  ```

  - 下载镜像问题，外面下载好镜像导入

- 查看

  ```
  kubectl get po,svc -n kafka -o wide
  ```

  ```
  kubectl get pv,pvc --all-namespaces
  ```

  ```
  kubectl get statefulset -n kafka
  ```

### 安装后的测试

- 进入一个broker容器查看

  ```shell
  kubectl -n kafka exec kafka-0 -it sh
  ```

  ```shell
  ls /usr/bin |grep kafka
  ls /usr/share/java/kafka | grep kafka
  ```

  可以看到对应apache kafka的版本号是`2.11-2.0.1`，前面`2.11`是Scala编译器的版本，Kafka的服务器端代码是使用Scala语言开发的，后边`2.0.1`是Kafka的版本。 即CP Kafka 5.0.1是基于Apache Kafka 2.0.1的。

### 安装Kafka Manager

​	Helm的官方repo中已经提供了[Kafka Manager的Chart](https://github.com/helm/charts/tree/master/stable/kafka-manager)。

​	创建`kafka-manager-values.yaml`：

```yaml
image:
  repository: zenko/kafka-manager
  tag: 1.3.3.22
zkHosts: kafka-zookeeper:2181
basicAuth:
  enabled: true
  username: admin
  password: admin
ingress:
  enabled: true
  hosts: 
   - km.hongda.com
  tls:
    - secretName: hongda-com-tls-secret
      hosts:
      - km.hongda.com
```

- 使用helm部署kafka-manager：

  ```shell
  helm install --name kafka-manager --namespace kafka -f kafka-manager-values.yaml stable/kafka-manager
  ```

- 安装完成后，确认kafka-manager的Pod已经正常启动：

  ```shell
  kubectl get pod -n kafka -l app=kafka-manager
  ```

  ```
  NAME                             READY   STATUS    RESTARTS   AGE
  kafka-manager-757668fd56-4jnxb   1/1     Running   0          8s
  ```

- 查看kafka的po,svc:

  ```shell
  kubectl get po,svc -n kafka -o wide
  ```

  ![image-20200531203016265](/Users/gerry/Desktop/document/k8s/helm/images/image-20200531203016265.png)

- ingress查看

  ```
  kubectl get ingresses. -n kafka
  ```

- 删除

  ```
  helm list 
  helm del --purge kafka-manager
  ```

- 访问地址，默认会重定向到https，这里30010是我服务器ingress的HTTPS端口

  ```shell
  https://km.hongda.com:30010/
  ```

  并配置`Cluster Zookeeper Hosts`为`kafka-zookeeper:2181`，即可将前面部署的kafka集群纳入`kafka-manager`管理当中。

  ![image-20200531210910730](/Users/gerry/Desktop/document/k8s/helm/images/image-20200531210910730.png)

  















