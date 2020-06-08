# Swarm Kubernetes Mesos 编排引擎对比剖析

您可能会问自己什么是容器编排引擎，它们解决了哪些问题，以及它们之间的区别。本文对Kubernetes，Docker Swarm和Apache Mesos进行对比，以及它们的一些显着的相似点和不同点。



### 容器编排引擎(Container Orchestration Engines)

虽然定义各不相同，但Kubernetes，Docker和Swarm都属于一类DevOps基础架构管理工具，称为`容器编排引擎`（COE）。 COE在资源池和在这些资源上运行的应用程序容器之间提供抽象层。



#### Kubernetes

Kubernetes（也称为“k8s”）于2014年6月首次发布，用Go编写。从古希腊语翻译，Kubernetes这个词的意思是“舵手。”该项目起源于谷歌开源，并且基于他们大规模运行容器的经验。

Kubernetes使用基于YAML的部署模型。除了在主机上调度容器之外，Kubernetes还提供许多其他功能。

将Kubernetes与Swarm和Mesos区分开来的还是“pods”的概念，它是一组容器，它们被组合在一起构成Kubernetes术语中的“服务”。



#### Swarm

Docker Swarm是Docker的本机Container Orchestration Engine。最初于2015年11月发布，它也是用Go编写的。 Swarmkit是版本1.12中包含的Swarm的Docker本机版本，对于那些希望使用Swarm的人来说，这是Docker的推荐版本。

Swarm与Docker API紧密集成，非常适合与Docker一起使用。这可以简化容器基础架构的管理，因为不需要配置单独的编排引擎，也不需要重新学习Docker概念才能使用Swarm。

与Kubernetes一样，Swarm有一个使用Docker Compose的基于YAML的部署模型。



#### Mesos

Apache Mesos 1.0版本于2016年7月发布，但它的历史可以追溯到2009年，当时它最初是由加州大学伯克利分校的博士生开发的。与Swarm和Kubernetes不同，Mesos是用C ++编写的。

Mesos与前面提到的前两个有些不同，因为它需要更多的分布式方法来管理数据中心和云资源。 Mesos可以拥有多个主服务器，这些主服务器使用Zookeeper来跟踪主服务器中的集群状态，并形成高可用性集群。

其他容器管理框架可以在Mesos上运行，包括Kubernetes，Apache Aurora，Chronos和Mesosphere Marathon。此外，Mesosphere DC / OS是一个分布式数据中心操作系统，基于Apache Mesos。

Mesos可以扩展到数万个节点，其最高可以运行5万多个节点，Kubernetes和Swarm都被限制在1000个节点（大约5万个容器）。





### Swarm、Mesos、和Kubernetes都为各种规模的企业提供了全面的支持，如何选择是好？



#### API

Swarm的 Zero To Dev 快速设置功能拥有巨大的优势，Docker API的灵活性让它易于集成，并允许使用其他工具，如定制脚本或编写的自定义接口以及复杂的调度。

- Swarm：易于集成和设置，灵活的API，有限的定制

- Kubernetes：高度通用，开源
- Mesos：适用于大型系统



#### 可伸缩性&弹性

在可伸缩性和弹性方面，Mesos对于运行着大规模集群的公司来说是最好的选择，在模拟测试中，其最高可以运行5万多个节点，Kubernetes和Swarm都被限制在1000个节点（大约5万个容器）。同时Mesos在大规模解决方案实践上拥有强大的话语权，如Twitter这样的大公司都在使用。

- Swarm：适合中小型系统，在这个范畴它的价值和可扩展性最好 
- Kubernetes：适合中等规模高度冗余的系统 
- Mesos：目前最稳定的平台，适合大规模系统

对于中型企业来说，Kubernetes在多主机集群中具有可靠性和较强的容错力，不过成本较高，因为应用插件的数量越多，就需要越好的安全方案。



#### 可用性

- Docker：

  Docker将单节点Docker的使用概念扩展到Swarm集群。如果你熟悉docker那你学习swarm相当容易。你也可以相当简单将docker环境到迁移到运行swarm集群。

  你只需要在其中的一个docker节点运行使用 docker swarm init命令创建一个集群，在您要添加任何其他节点，通过docker swarm join命令加入到刚才创建的集群中。之后您可以象在一个独立的docker环境下一样使用同样的Docker Compose的模板及相同的docker命令行工具。

- Kubernetes

  从头开始设置Kubernetes是一个困难的过程，因为它需要设置etcd，网络插件，DNS服务器和证书颁发机构一系统操作。

  Kubernetes使用资源类型，如Pods、Deployments、Replication Controllers、Services、Daemon sets等来定义部署。 这些概念都不是Docker词典的一部分，因此您需要在开始创建第一个部署之前熟悉它们。

- Mesos

  与Swarm相比，Mesos有一个相当陡峭的学习曲线，因为它不与Docker分享大部分概念和术语。

  Mesos带有许多使用其资源共享功能的框架和应用栈。每个框架由一个调度器和一个执行器组成。 Marathon是一个框架（或元框架），可以启动应用程序和其他框架。 Marathon还可以作为容器编排平台，为容器工作负载提供扩展和自我修复。

  Marathon 容器可以不受限制的部署在任何节点上。使用Zookeeper支持Mesos和Marathon的高可用性。 Zookeeper提供Mesos和Marathon领导者的选举并维护集群状态。

  



##### 参考网址：

- [聊聊调度框架，K8S、Mesos、Swarm 一个都不能少 ](https://www.sohu.com/a/165637724_332175)

- [Kubernetes vs Mesos vs Swarm](https://www.dazhuanlan.com/2019/10/21/5dad4dfdc40b4/)

- [Swarm Kubernetes Marathon 编排引擎对比剖析](https://www.kubernetes.org.cn/797.html)
- [kubernetes 和 mesos + marathon的对比](https://www.cnblogs.com/sudan5/p/12176153.html)



