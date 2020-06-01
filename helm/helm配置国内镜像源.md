## Kubernetes helm配置国内镜像源，azure镜像更多

### helm配置stable国内镜像源

- 1、删除默认的源

  ```shell
  helm repo remove stable
  ```

- 2、增加新的国内镜像源

  - ```shell
    源1：helm repo add stable https://burdenbear.github.io/kube-charts-mirror/
    ```

  - ```shell
    源2：helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
    ```

- 3、查看helm源添加情况

  ```shell
  helm repo list
  ```

- 4、搜索测试

  ```shell
  helm search mysql
  helm search prometheus
  ```

  ![image-20200531165705127](/Users/gerry/Desktop/document/k8s/helm/images/image-20200531165705127.png)

### helm 配置 chart incubator国内镜像源（推荐）

- 1、删除默认的源

  ```shell
  helm repo remove stable
  helm repo remove incubator
  ```

- 2、增加新的国内镜像源

  ```shell
  helm repo add stable http://mirror.azure.cn/kubernetes/charts
  helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator
  ```

- 3、查看helm源添加情况

  ```shell
  helm repo list
  ```

- 4、搜索测试

  ```shell
  helm search stable/mysql
  helm search incubator/kafka 
  helm search stable/kafka-manager 
  ```

  ![image-20200531165822586](/Users/gerry/Desktop/document/k8s/helm/images/image-20200531165822586.png)















