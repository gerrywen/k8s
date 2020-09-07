

## Helm部署

##### 使用 Helm 安装 Kubernetes 的常用 组件。 Helm 由客户端命 helm 令行工具和服务端 tiller 组成，Helm 的安装十分简单。 下载 helm 命令行工具到

##### master 节点 的 /usr/local/bin 下，这里下载的 2.13. 1版本，最新版本是：helm-v2.14.0-linux-amd64.tar.gz

- 准备包：helm-v2.13.1-linux-amd64.tar.gz

```
mv helm-v2.13.1-linux-amd64.tar.gz /root/install-k8s/
cd /root/install-k8s/
tar -zxvf helm-v2.13.1-linux-amd64.tar.gz
cd linux-amd64/ 
cp helm /usr/local/bin/
chmod a+x /usr/local/bin/helm
ln -s /usr/local/bin/helm /usr/bin/helm
```



## 安装服务端kubernetes-helm/tiller

因为helm安装过程中会自动拉取gcr.io/kubernetes-helm/tiller镜像，国内可能无法访问，故可以使用下面的命令先查看所需的镜像版本，并在之后的命令行中设置镜像来源，参考[[kubernetes包管理工具Helm安装](https://www.cnblogs.com/hackyo/p/10695613.html)]

```
helm init --dry-run --debug
```

- 准备镜像包

  ```shell
  registry.aliyuncs.com/google_containers/tiller:v2.13.1
  ```

- 推送到本地仓库，供其他节点拉取

  ```shell
  docker tag hub.ccbft.com/library/gcr.io/kubernetes-helm/tiller:v2.13.1 gcr.io/kubernetes-helm/tiller:v2.13.1
  docker push  hub.ccbft.com/library/gcr.io/kubernetes-helm/tiller:v2.13.1
  ```

- 其他node节点拉取镜像,并重命名

  ```
  docker pull hub.ccbft.com/library/gcr.io/kubernetes-helm/tiller:v2.13.1
  docker tag hub.ccbft.com/library/gcr.io/kubernetes-helm/tiller:v2.13.1 gcr.io/kubernetes-helm/tiller:v2.13.1
  ```



##### 为了安装服务端 tiller，还需要在这台机器上配置好 kubectl 工具和 kubeconfig 文件，确保 kubectl 工具可以在这台机器上访问 apiserver 且正常使用。 这里的 node1 节点以及配置好了 kubectl

##### 因为 Kubernetes APIServer 开启了 RBAC 访问控制，所以需要创建 tiller 使用的 service account: tiller 并分配合适的角色给它。 详细内容可以查看helm文档中的 [Role-based Access Control](https://helm.sh/docs/intro/)。对于 Kubernetes v1.16.0 以上的版本，有可能会碰到 Error: error installing: the server could not find the requested resource 的错误。这是由于 extensions/v1beta1 已经被 apps/v1 替代，解决方法是执行命令：

```shell
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -
```

- master节点测试安装是否成功

```
[root@k8s-master01 helm]# helm version
```







