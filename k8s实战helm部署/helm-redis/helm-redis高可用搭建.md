# Kubernetes 使用 Helm 部署 redis-ha

### 参考地址

- [Kubernetes 使用 Helm 部署 redis-ha](https://blog.csdn.net/jesse919/article/details/102605178)
- [[helm部署redis主从和哨兵模式](https://www.cnblogs.com/wangzhangtao/p/12593812.html)]



- 创建Kafka的Local PV

  ```shell
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: data-redis-0
  spec:
    capacity:
      storage: 10Gi 
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/redis/10g/0
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
    name: data-redis-1
  spec:
    capacity:
      storage: 10Gi
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/redis/10g/1
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
    name: data-redis-2
  spec:
    capacity:
      storage: 10Gi
    accessModes:
    - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    storageClassName: local-storage
    local:
      path: /home/redis/10g/2
    nodeAffinity:
      required:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
            - k8s-node01
  ```

- 编写 my-values.yaml 

  ```yaml
  auth: true
  redisPassword: "redis1"
  #(仅限当replicas > worker node 节点数时修改)
  hardAntiAffinity: false  
  haproxy:
    service:
      type: NodePort
    persistence:
      storageClass: "local-storage"
  persistentVolume:
    storageClass: "local-storage"
  ```

  

- 部署redis-ha

  ```shell
  $ helm install --name redis --namespace redis -f my-values.yaml ./redis-ha
  ```

- 运行测试

  ```shell
  $ kubectl exec -it redis-redis-ha-server-0 sh -n redis
  $ kubectl exec -it redis-redis-ha-server-1 sh -n redis
  ```

  ```shell
  $ redis-cli
  $ auth redis1
  ```

- 通过svc访问

  ```shell
  $ redis-cli -h 10.105.95.238  -p 26379 -a redis1
  ```

- 通过NodePort测试阶段提供对外访问

  ```shell
  $ redis-cli -h 192.168.33.10  -p 30379 -a redis1
  ```

  