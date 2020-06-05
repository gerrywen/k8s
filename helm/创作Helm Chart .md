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

  