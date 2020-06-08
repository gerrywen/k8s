# gitlab的Git团队协作流程

### 版本号命名规则

版本号的格式为 X.Y.Z(又称 Major.Minor.Patch)，递增的规则为：

- X 表示主版本号，当 API 的兼容性变化时，X 需递增。
- Y 表示次版本号，当增加功能时(不影响 API 的兼容性)，Y 需递增。
- Z 表示修订号，当做 Bug 修复时(不影响 API 的兼容性)，Z 需递增



### 分支模型

##### 简单理解几个概念：

- **master**——最为稳定功能最为完整的随时可发布的代码;

- **develop**——永远是功能最新最全的分支；

  - 开发者直接拉取develop分支，命名规范dev-<名字>

    ```
    dev-zhangsan
    dev-lisi
    ```

- release——发布定期要上线的功能；

- hotfix——修复线上代码的 bug；

  - 命名规范hotfix-<名字>-<版本号>

    ```
    hotfix-zhangsan-1.1.1
    hotfix-lisi-1.1.1
    ```

##### 「master」和「develop」是主要分支，其他分支是派生而来的。各类型分支之间的关系用一张图来体现

<img src="./images/image-20200601111911505.png" alt="image-20200601111911505" style="zoom:50%;" />



##### 开发流程

- 1.开发接收需求，切换到develop分支，pull develop分支最新代码，拉取开发者自己的dev-<name>分支；

- 2.每一个开发者都应该各自使用独立的dev-<name>分支。为了备份或便于团队之间的合作，分支推送到中央仓库。

- 3.功能开发完毕并且自测后，先拉取远程 develop分支最新代码，把develop分支的代码合并到自己的dev-<name>分支，有冲突和配合的人一起解决。

- 4.到 GitLab 上的项目首页创建dev-<name>合并到develop的合并请求（merge request），代码审核的同事合并代码。

  ![image-20200601094715500](./images/image-20200601094715500.png)

  <img src="./images/image-20200601095349289.png" alt="image-20200601095349289" style="zoom:50%;" />

  ![image-20200601095457993](./images/image-20200601095457993.png)

  <img src="./images/image-20200601095651197.png" alt="image-20200601095651197" style="zoom:50%;" />

- 5.点击Submit merge request 请求合并，列表会有刚刚提交的记录，通知合并代码同事。

  <img src="./images/image-20200601095939200.png" alt="image-20200601095939200" style="zoom:50%;" />

  <img src="./images/image-20200601100408725.png" alt="image-20200601100408725" style="zoom:50%;" />

<img src="./images/image-20200601100534187.png" alt="image-20200601100534187" style="zoom:50%;" />

- 6.负责测试的人从develop创建一个 release 分支部署到测试环境进行测试，打上版本号。

- 7.当确保某次发布的功能可以发布时，负责发布的人将 release 分支合并进 master 并打上 tag，然后打包发布到线上环境。

- 8.已经上线版本的master出现bug修复流程：

  - 1.release相关人员会从**release-1.1.0**拉取一个**release-1.1.1**版本。

  - 2.张三 从**release-1.1.1**拉取**hotfix-zhangsan-1.1.1分支**进行线版本修复。

  - 3.修复完bug合并到**dev**分支和**release-1.1.1**分支

  - 4.测试人员测试**release-1.1.1**完毕合并到**master**分支，打上标签版本号**tag-v1.1.1**

    

