# 从入门到实践：创作一个自己的 Helm Chart 

### 参考资料

- [从入门到实践：创作一个自己的 Helm Chart ](https://www.sohu.com/a/338145305_612370)
- [Helm 从入门到实践](https://www.jianshu.com/p/4bd853a8068b)
- [helm模板文件chart编写语法详解](https://blog.51cto.com/qujunorz/2421328)



### 开始创作

- 创建模块,会得到一个 helm 自动生成的空 chart。

  ```shell
  helm create mall-config
  ```

  **需要注意的是，Chart 里面的 my-hello-world 名称需要和生成的 Chart 文件夹名称一致。**

  **如果修改 my-hello-world，则需要做一致的修改。** 

  现在，我们看到 Chart 的文件夹目录如下：

  ```shell
  [root@k8s-master01 mall-config]# tree
  .
  ├── charts
  ├── Chart.yaml
  ├── templates
  │   ├── deployment.yaml
  │   ├── _helpers.tpl
  │   ├── ingress.yaml
  │   ├── NOTES.txt
  │   ├── service.yaml
  │   └── tests
  │       └── test-connection.yaml
  └── values.yaml
  
  3 directories, 8 files
  [root@k8s-master01 mall-config]# 
  ```

  在根目录下的 Chart.yaml 文件内，声明了当前 Chart 的名称、版本等基本信息，这些信息会在该 Chart 被放入仓库后，供用户浏览检索。

  在 Chart.yaml 里有两个跟版本相关的字段，其中 version 指明的是 Chart 的版本，也就是我们应用包的版本；而 appVersion 指明的是内部实际使用的应用版本。



### 校验打包

- 使用 Helm lint 来粗略地检查一下制作的 Chart 有没有什么语法上的错误

  ```shell
   helm lint --strict mall-config
  ```

  ```shell
  [root@k8s-master01 helm-mall]# helm lint --strict mall-config/
  ==> Linting mall-config/
  Lint OK
  
  1 chart(s) linted, no failures
  ```

  

- 使用 helm package 命令对我们的 Chart 文件夹进行打包

  ```shell
  helm package mall-config
  ```

  ```shell
  [root@k8s-master01 helm-mall]# helm package mall-config
  Successfully packaged chart and saved it to: /root/k8s/helm-mall/mall-config-0.1.0.tgz
  [root@k8s-master01 helm-mall]# ls
  mall-config  mall-config-0.1.0.tgz
  ```

- 使用 helm install 命令尝试安装一下刚刚做好的应用包

  ```shell
  helm install  --name mall-config-service --namespace mall mall-config-0.1.0.tgz 
  ```




### helm微服务部署

```shell
helm install  --name mall-eureka-service --namespace mall mall-eureka-0.1.0.tgz
```

```shell
helm install  --name mall-gateway-service --namespace mall mall-gateway-0.1.0.tgz
```

```shell
helm install  --name mall-auth-service --namespace mall mall-auth-0.1.0.tgz
```

```shell
helm install  --name mall-user-service --namespace mall mall-user-0.1.0.tgz
```

- 有个坑需要注意，url配置微服务的时候一定要加`http://`前缀

  ```shell
  Load balancer does not have available server for client: mall-auth-service:8087
  ```

  ```shell
  http://mall-auth-service:8087
  ```

  

```shell
[root@k8s-master01 helm-mall]# helm list
NAME                	REVISION	UPDATED                 	STATUS  	CHART                     	APP VERSION	NAMESPACE  
kubernetes-dashboard	1       	Sat May 30 14:27:53 2020	DEPLOYED	kubernetes-dashboard-0.6.0	1.8.3      	kube-system
mall-auth-service   	1       	Sat Jun  6 11:52:12 2020	DEPLOYED	mall-auth-0.1.0           	v1.1       	mall       
mall-config-service 	1       	Fri Jun  5 23:01:03 2020	DEPLOYED	mall-config-0.1.0         	v1.4       	mall       
mall-eureka-service 	1       	Sat Jun  6 10:50:13 2020	DEPLOYED	mall-eureka-0.1.0         	v1.3       	mall       
mall-gateway-service	1       	Sat Jun  6 12:43:07 2020	DEPLOYED	mall-gateway-0.1.0        	v1.1       	mall       
mall-user-service   	1       	Sat Jun  6 12:23:03 2020	DEPLOYED	mall-user-0.1.0           	v1.2       	mall  
```

```shell
[root@k8s-master01 helm-mall]# kubectl get svc,pod -n mall
NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
service/mall-auth-service      ClusterIP   10.98.147.81     <none>        8087/TCP    55m
service/mall-config-service    ClusterIP   10.108.245.165   <none>        10011/TCP   13h
service/mall-eureka-service    ClusterIP   10.96.99.112     <none>        10086/TCP   117m
service/mall-gateway-service   ClusterIP   10.98.40.255     <none>        10010/TCP   4m16s
service/mall-user-service      ClusterIP   10.98.176.226    <none>        8085/TCP    24m

NAME                                        READY   STATUS    RESTARTS   AGE
pod/mall-auth-service-995479df9-znvsg       1/1     Running   0          55m
pod/mall-config-service-7dc856c86d-b9476    1/1     Running   1          13h
pod/mall-eureka-service-dfd85f5ff-skwbw     1/1     Running   0          117m
pod/mall-gateway-service-66676d7bdb-brgzw   1/1     Running   0          4m16s
pod/mall-user-service-f86bb46f4-xpt8l       1/1     Running   0          24m
```

```shell
[root@k8s-master01 helm-mall]# kubectl get ingresses. -n mall
NAME                   HOSTS              ADDRESS        PORTS   AGE
mall-auth-service      auth.mall.com      10.104.97.57   80      55m
mall-config-service    config.mall.com    10.104.97.57   80      13h
mall-eureka-service    eureka.mall.com    10.104.97.57   80      117m
mall-gateway-service   gateway.mall.com   10.104.97.57   80      4m52s
mall-user-service      user.mall.com      10.104.97.57   80      24m
```

- 批量移除helm服务

  ```shell
  helm del --purge mall-user-service mall-gateway-service mall-eureka-service mall-config-service mall-auth-service
  ```

  



### 内存运行情况



![image-20200606125545628](./images/image-20200606125545628.png)





### 笔记(忽略)

```shell
cd /Users/gerry/Desktop/document/k8s/spring-cloud
scp -r mall-auth/ mall-gateway/ mall-user/ 10:/root/k8s/spring-cloud/
```

```shell
cd /Users/gerry/Desktop/document/k8s/helm-mall
scp -r mall-auth/ mall-gateway/ mall-user/ 10:/root/k8s/helm-mall/
```

```shell
 kubectl -n mall  logs -f <pod/名称>
```

