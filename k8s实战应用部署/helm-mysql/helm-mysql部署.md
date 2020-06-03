## helm在k8s上部署mysql

### 创建Mysql的nfs PV

`mysql-pv.yaml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 8Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: 192.168.33.100
    path: /home/grafana/8g
```

```shell
kubectl get pv
```



- 查看msyql配置信息

  ```shell
  helm inspect values stable/mysql
  ```

  

- 下载mysql的helm包

  ```shell
  helm fetch stable/mysql
  ```

  

- 可以查看values.yaml，截取部分示例

  ```yaml
  ## mysql image version
  ## ref: https://hub.docker.com/r/library/mysql/tags/
  ##
  image: "mysql"
  imageTag: "5.7.30"
  
  strategy:
    type: Recreate
  
  busybox:
    image: "busybox"
    tag: "1.31.1"
  
  testFramework:
    enabled: true
    image: "dduportal/bats"
    tag: "0.4.0"
  
  ## Specify password for root user
  ##
  ## Default: random 10 character string
  # mysqlRootPassword: testing
  
  ## Create a database user
  ##
  # mysqlUser:
  ## Default: random 10 character string
  # mysqlPassword:
  
  ## Allow unauthenticated access, uncomment to enable
  ##
  # mysqlAllowEmptyPassword: true
  
  ## Create a database
  ##
  # mysqlDatabase:
  ```

- 安装 mysql chart 

  ```shell
  helm install stable/mysql  --set mysqlRootPassword=root --name mysql --namespace mysql
  ```

  

- 查看运行状态

  ```shell
  helm status mysql
  ```

  

- 查看运行的各种资源状态

  ```shell
  kubectl get pod,rs,deployment,svc,pvc -n mysql -o wide
  ```

  ```shell
  [root@k8s-master01 mysql]# kubectl get pod,rs,deployment,svc,pvc -n mysql -o wide
  NAME                         READY   STATUS    RESTARTS   AGE   IP             NODE         NOMINATED NODE   READINESS GATES
  pod/mysql-79b4688d45-nhdkd   1/1     Running   0          22m   10.244.2.129   k8s-node01   <none>           <none>
  
  NAME                                     DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES         SELECTOR
  replicaset.extensions/mysql-79b4688d45   1         1         1       22m   mysql        mysql:5.7.30   app=mysql,pod-template-hash=79b4688d45,release=mysql
  
  NAME                          READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
  deployment.extensions/mysql   1/1     1            1           22m   mysql        mysql:5.7.30   app=mysql,release=mysql
  
  NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
  service/mysql   ClusterIP   10.106.96.145   <none>        3306/TCP   22m   app=mysql
  
  NAME                          STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
  persistentvolumeclaim/mysql   Bound    mysql-pv   8Gi        RWO                           22m   Filesystem
  ```

  

- 查看 release 列表：

  ```shell
  helm list
  ```

  

- 查看root用户密码

  ```shell
  kubectl get secret --namespace mysql mysql -o jsonpath="{.data.mysql-root-password}" | base64 --decode; echo
  ```

  

- 使用Ubuntu连接数据库

  ```shell
  kubectl run -i --tty ubuntu --image=hub.gerrywen.com/library/ubuntu:16.04 --restart=Never -- bash -il
  apt-get update && apt-get install mysql-client -y
  mysql -h10.106.96.145 mysql -p
  ```

  

- k8s的mysql暴露给外部访问,这里测试操作用，正常MySQL服务不会暴露给外部访问

  ```shell
  kubectl get svc -n mysql
  ```

  ```shell
  kubectl edit svc -n mysql mysql
  ```

  - 原ClusterIP类型

    ```yaml
    spec:
      clusterIP: 10.106.96.145
      ports:
      - name: mysql
        port: 3306
        protocol: TCP
        targetPort: mysql
      selector:
        app: mysql
      sessionAffinity: None
      type: ClusterIP
     
    ```

  - 修改为NodePort类型

    ```yaml
    spec:
      clusterIP: 10.106.96.145
      ports:
      - name: mysql
        port: 3306
        protocol: TCP
        targetPort: mysql
      selector:
        app: mysql
      sessionAffinity: None
      type: NodePort
    ```

  - 查看修改完的svc类型以及暴露的端口号

    ```shell
    kubectl get svc -n mysql
    ```

    ```shell
    [root@k8s-master01 helm-mysql]# kubectl get svc -n mysql
    NAME    TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
    mysql   NodePort   10.106.96.145   <none>        3306:30603/TCP   80m
    ```

  - 连接测试

    ```shell
    mysql -h192.168.33.10 -P30603 -uroot -p
    ```

    ```shell
    gerrydeMBP:mysql gerry$ mysql -h192.168.33.10 -P30603 -uroot -p
    Enter password: 
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 999
    Server version: 5.7.30 MySQL Community Server (GPL)
    
    Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql> 
    mysql> 
    mysql> show databases;
    +--------------------+
    | Database           |
    +--------------------+
    | information_schema |
    | mysql              |
    | performance_schema |
    | sys                |
    +--------------------+
    4 rows in set (0.01 sec)
    
    mysql> 
    ```

    

  

- 测试使用ingress暴露给外部访问msyql。验证结果访问不了

  `mysql-ingress.yaml`

  ```yaml
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: mysql-ingress
    namespace: mysql
    labels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  spec:
    rules:
      - host: mysql.mall.com
        http:
          paths:
          - path: /
            backend:
              serviceName: mysql
              servicePort: 3306
  ```

  ```shell
  kubectl create -f mysql-ingress.yaml
  ```

- 查看prometheus命名空间下的Ingress

  ```shell
  kubectl get ingresses. -n mysql
  ```

  

