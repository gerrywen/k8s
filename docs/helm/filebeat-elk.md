# helm部署Filebeat + ELK

系统架构图：

1) 多个Filebeat在各个Node进行日志采集，然后上传至Logstash

2) 多个Logstash节点并行（负载均衡，不作为集群），对日志记录进行过滤处理，然后上传至Elasticsearch集群

3) 多个Elasticsearch构成集群服务，提供日志的索引和存储能力

4) Kibana负责对Elasticsearch中的日志数据进行检索、分析



## 1.Elasticsearch部署

官方chart地址：https://github.com/elastic/helm-charts/tree/master/elasticsearch

创建logs命名空间

```shell
$ kubectl create ns logs
```

添加elastic helm charts 仓库

```shell
$ helm repo add elastic https://helm.elastic.co
```

查看helm仓库

```shell
$ helm search  elastic/elasticsearch
```

下载远程安装包到本地，默认下载最新版本7.8.1

```shell
$ helm fetch elastic/elasticsearch 
```

安装

```shell
$ helm install --name elasticsearch --namespace logs -f my-values.yaml ./elasticsearch 
```

value.yaml参数说明

- replicas 这里部署1个pod，生产应用可以部署3个以上
- minimumMasterNodes 一般部署3个以上的pod，这里部署2个

```yaml
image: "elastic/elasticsearch"
imageTag: "7.8.1"
imagePullPolicy: "IfNotPresent"
podAnnotations: {}
replicas: 1
minimumMasterNodes: 1
esJavaOpts: "-Xmx1g -Xms1g"
resources:
  requests:
    cpu: "100m"
    memory: "2Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
volumeClaimTemplate:
  accessModes: [ "ReadWriteOnce" ]
  storageClassName: "local-storage"
  resources:
    requests:
      storage: 30Gi
```

pv挂载说明

- 这里启动1个pod对应1个pv，这里只挂载1个pv

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: elasticsearch-pv-0
spec:
  capacity:
    storage: 30Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /home/elasticsearch/01
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - k8s-master01
```



## 2.Filebeat部署

官方chart地址：https://github.com/elastic/helm-charts/tree/master/filebeat

Add the elastic helm charts repo

```shell
$ helm repo add elastic https://helm.elastic.co
```

查看helm仓库

```shell
$ helm search  elastic/filebeat
```

下载远程安装包到本地，默认下载最新版本7.8.1

```shell
$ helm fetch elastic/filebeat
```

Install it

```shell
$ helm install --name filebeat elastic/filebeat --namespace logs
```

参数说明：

```yaml
image: "docker.elastic.co/beats/filebeat"
imageTag: "7.2.0"
imagePullPolicy: "IfNotPresent"
resources:
  requests:
    cpu: "100m"
    memory: "100Mi"
  limits:
    cpu: "1000m"
    memory: "200Mi"
```

那么问题来了，filebeat默认收集宿主机上docker的日志路径：/var/lib/docker/containers。如果我们修改了docker的安装路径要怎么收集呢，很简单修改chart里的DaemonSet文件里边的hostPath参数：

```yaml
- name: varlibdockercontainers
  hostPath:
    path: /var/lib/docker/containers   #改为docker安装路径
```

对java程序的报错异常log实现多行合并，用multiline定义正则来匹配。

```yaml
filebeatConfig:
  filebeat.yml: |
    filebeat.inputs:
    - type: docker
      containers.ids:
      - '*'
      multiline.pattern: '^[0-9]'
      multiline.negate: true
      multiline.match: after
      processors:
      - add_kubernetes_metadata:
          in_cluster: true
 
    output.elasticsearch:
      hosts: '${ELASTICSEARCH_HOSTS:elasticsearch-master:9200}'
```



## 3.Kibana部署

官方chart地址：https://github.com/elastic/helm-charts/tree/master/kibana

Add the elastic helm charts repo

```shell
helm repo add elastic https://helm.elastic.co
```

查看helm仓库

```shell
$ helm search  elastic/kibana
```

下载远程安装包到本地，默认下载最新版本7.8.1

```shell
$ helm fetch elastic/kibana
```

Install it

```shell
helm install --name kibana elastic/kibana --namespace logs
```

参数说明：

```shell
elasticsearchHosts: "http://elasticsearch-master:9200"
replicas: 1
image: "docker.elastic.co/kibana/kibana"
imageTag: "7.2.0"
imagePullPolicy: "IfNotPresent"
resources:
  requests:
    cpu: "100m"
    memory: "500m"
  limits:
    cpu: "1000m"
    memory: "1Gi"
```



## 4.Logstash部署

官方chart地址：https://github.com/helm/charts/tree/master/stable/logstash

Add the elastic helm charts repo

```shell
helm repo add elastic https://helm.elastic.co
```

查看helm仓库

```shell
$ helm search  elastic/logstash
```

下载远程安装包到本地，默认下载最新版本7.8.1

```shell
$ helm fetch elastic/logstash
```

安装

```shell
$ helm install --name logstash elastic/logstash --namespace logs
```

参数说明：

```shell
image:
  repository: docker.elastic.co/logstash/logstash-oss
  tag: 7.2.0
  pullPolicy: IfNotPresent
persistence:
  enabled: true
  storageClass: "nfs-client"
  accessMode: ReadWriteOnce
  size: 2Gi
```

匹配label：json的pod日志，没有的话正常收集。

```shell
filebeatConfig:
  filebeat.yml: |
    filebeat.autodiscover:
      providers:
        - type: kubernetes
          templates:
            - condition:
                equals:
                  kubernetes.labels.logFormat: "json"
              config:
                - type: docker
                  containers.ids:
                    - "${data.kubernetes.container.id}"
                  json.keys_under_root: true
                  json.overwrite_keys: true
                  json.add_error_key: true
            - config:
                - type: docker
                  containers.ids:
                    - "${data.kubernetes.container.id}"
                  processors:
                    - add_kubernetes_metadata:
                        in_cluster: true
    output.elasticsearch:
      hosts: '${ELASTICSEARCH_HOSTS:elasticsearch-master:9200}'
```



## 5.Elastalert部署

官方chart地址：https://github.com/helm/charts/tree/master/stable/elastalert

Add the elastic helm charts repo

```shell
helm repo add stable http://mirror.azure.cn/kubernetes/charts
```

查看helm仓库

```shell
$ helm search stable/elastalert
```

下载远程安装包到本地，默认下载最新版本1.5.0

```shell
$ helm fetch stable/elastalert
```

安装

```shell
$ helm install -name elastalert stable/elastalert --namespace logs
```

