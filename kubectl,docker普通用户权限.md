# 使用kubectl、docker命令（非root用户）

- 参考https://blog.csdn.net/weixin_30955341/article/details/102018234

一、创建非root用户，赋予权限

- 1、add user

  ```shell
  useradd dtmapp #创建用户,目前这个已经创建了。
  passwd xxxxxpwd #修改密码
  ```

- 2、为新建用户添加 sudo 权限

  ```shell
   ########添加文件的权限
   chmod -v u+w /etc/sudoers
   #添加如下到文件
   ## Allow root to run any commands anywher
   root ALL=(ALL) ALL
   dtmapp ALL=(ALL) ALL #新增用户信息
   
   ########再取消权限
   chmod -v u-w /etc/sudoers
  ```

  

二、配置dev用户使用kubectl使用权限

- 1、切换到普通用户操作：

  ```shell
  su - dtmapp
  mkdir -p $HOME/.kube
  ```

- 2、切换到root用户操作：

  ```shell
  sudo cp -i /etc/kubernetes/admin.config /home/ap/dtmapp/.kube/config
  sudo chown dtmapp:dtmapp /home/ap/dtmapp/.kube/config
  ```

- 3、切换到普通用户,配置环境变量：

  ```shell
  export KUBECONFIG=/home/dev/.kube/config
  ```

  

三、切换到root用户给dtmapp加docker使用权限

```shell
usermod -G docker dtmapp
```

