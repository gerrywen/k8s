## 部署zookeeper

#### 编辑zookeeper-values.yaml

```yaml
replicaCount: 3
image:
  repository: hub.gerrywen.com/library/zookeeper     # Container image repository for zookeeper container.
  tag: 3.5.5                # Container image tag for zookeeper container.
  pullPolicy: IfNotPresent  # Image pull criteria for zookeeper container.
persistence:
  enabled: true
  storageClass: managed-nfs-storage
  size: 5Gi
```

- storageClass使用nfs自动挂载方式

#### 运行命令

```shell script
  helm install --name zookeeper --namespace kafka -f zookeeper-values.yaml ./zookeeper
```



## 部署kafka
```shell script
  helm install --name kafka --namespace kafka -f kafka-values.yaml ./kafka
```

