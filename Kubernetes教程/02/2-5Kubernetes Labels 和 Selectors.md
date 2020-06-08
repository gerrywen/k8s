# Kubernetes Labels 和 Selectors

- [1 Motivation](#Motivation)
- [2 语法和字符集](#语法和字符集)
- 3 [Labels选择器](#Labels选择器)
  - [3.1 Equality-based requirement 基于相等的要求](#Equality-based requirement 基于相等的要求)
  - [3.2 Set-based requirement](Set-based requirement)
- 4 API
  - [4.1 LIST和WATCH过滤](#LIST和WATCH过滤)
  - [4.2 API对象中引用](#API对象中引用)
    - [4.2.1 Service和ReplicationController](#Service和ReplicationController)
    - [4.2.2 支持set-based要求的资源](#支持set-based要求的资源)
    - [4.2.3 Selecting sets of nodes](#Selecting sets of nodes)

Labels其实就一对 key/value ，被关联到对象上，标签的使用我们倾向于能够标示对象的特殊特点，并且对用户而言是有意义的，但是标签对内核系统是没有直接意义的。

```json
"labels": {
  "key1" : "value1",
  "key2" : "value2"
}
```



### Motivation

Labels可以让用户将他们自己的有组织目的的结构以一种松耦合的方式应用到系统的对象上，且不需要客户端存放这些对应关系（mappings）。

服务部署和批处理管道通常是多维的实体（例如多个分区或者部署，多个发布轨道，多层，每层多微服务）。管理通常需要跨越式的切割操作，这会打破有严格层级展示关系的封装，特别对那些是由基础设施而非用户决定的很死板的层级关系。

示例标签：

- "release" : "stable"， "release" : "canary"
- "environment" : "dev"，"environment" : "qa"，"environment" : "production"
- "tier" : "frontend"，"tier" : "backend"，"tier" : "cache"
- "partition" : "customerA"， "partition" : "customerB"
- "track" : "daily"， "track" : "weekly"

这些只是常用Labels的例子，你可以按自己习惯来定义，需要注意，每个对象的标签key具有唯一性。



### 语法和字符集

Label其实是一对 key/value。有效的标签键有两个段：可选的前缀和名称，用斜杠（/）分隔，名称段是必需的，最多63个字符，以[a-z0-9A-Z]带有虚线（-）、下划线（_）、点（.）和开头和结尾必须是字母或数字（都是字符串形式）的形式组成。前缀是可选的。如果指定了前缀，那么必须是DNS子域：一系列的DNSlabel通过”.”来划分，不超过253个字符，以斜杠（/）结尾。如果前缀被省略了，这个Label的key被假定为对用户私有的。自动化系统组件有（例如kube-scheduler，kube-controller-manager，kube-apiserver，kubectl，或其他第三方自动化），这些添加标签终端用户对象都必须指定一个前缀。Kuberentes.io 前缀是为Kubernetes 内核部分保留的。

有效的标签值最长为63个字符。要么为空，要么使用[a-z0-9A-Z]带有虚线（-）、下划线（_）、点（.）和开头和结尾必须是字母或数字（都是字符串形式）的形式组成。



### Labels选择器

与[Name和UID](http://docs.kubernetes.org.cn/235.html) 不同，标签不需要有唯一性。一般来说，我们期望许多对象具有相同的标签。

通过标签选择器（Labels Selectors），客户端/用户 能方便辨识出一组对象。标签选择器是kubernetes中核心的组成部分。

API目前支持两种选择器：equality-based（基于平等）和set-based（基于集合）的。标签选择器可以由逗号分隔的多个requirements 组成。在多重需求的情况下，必须满足所有要求，因此逗号分隔符作为AND逻辑运算符。

一个为空的标签选择器（即有0个必须条件的选择器）会选择集合中的每一个对象。

一个null型标签选择器（仅对于可选的选择器字段才可能）不会返回任何对象。

注意：两个控制器的标签选择器不能在命名空间中重叠。



### Equality-based requirement 基于相等的要求

基于相等的或者不相等的条件允许用标签的keys和values进行过滤。匹配的对象必须满足所有指定的标签约束，尽管他们可能也有额外的标签。有三种运算符是允许的，“=”，“==”和“!=”。前两种代表相等性（他们是同义运算符），后一种代表非相等性。例如：

```shell
environment = production
tier != frontend
```

第一个选择所有key等于 environment 值为 production 的资源。后一种选择所有key为 tier 值不等于 frontend 的资源，和那些没有key为 tier 的label的资源。要过滤所有处于 production 但不是 frontend 的资源，可以使用逗号操作符，

```shell
frontend：environment=production,tier!=frontend
```



### Set-based requirement

Set-based 的标签条件允许用一组value来过滤key。支持三种操作符: in ， notin 和 exists(仅针对于key符号) 。

例如：

```shell
environment in (production, qa)
tier notin (frontend, backend)
partition
!partition
```

第一个例子，选择所有key等于 environment ，且value等于 production 或者 qa 的资源。 第二个例子，选择所有key等于 tier 且值是除了 frontend 和 backend 之外的资源，和那些没有标签的key是 tier 的资源。 第三个例子，选择所有有一个标签的key为partition的资源；value是什么不会被检查。 第四个例子，选择所有的没有lable的key名为 partition 的资源；value是什么不会被检查。

类似的，逗号操作符相当于一个AND操作符。因而要使用一个 partition 键（不管value是什么），并且 environment 不是 qa 过滤资源可以用 partition,environment notin (qa) 。

Set-based 的选择器是一个相等性的宽泛的形式，因为 environment=production 相当于environment in (production) ，与 != and notin 类似。

Set-based的条件可以与Equality-based的条件结合。例如， partition in (customerA,customerB),environment!=qa 。



### API

### LIST和WATCH过滤

LIST和WATCH操作可以指定标签选择器来过滤使用查询参数返回的对象集。这两个要求都是允许的（在这里给出，它们会出现在URL查询字符串中）：

LIST和WATCH操作，可以使用query参数来指定label选择器来过滤返回对象的集合。两种条件都可以使用：

- Set-based的要求：?labelSelector=environment%3Dproduction,tier%3Dfrontend
- Equality-based的要求：?labelSelector=environment+in+%28production%2Cqa%29%2Ctier+in+%28frontend%29

两个标签选择器样式都可用于通过REST客户端列出或观看资源。例如，apiserver使用kubectl和使用基于平等的人可以写：

两种标签选择器样式，都可以通过REST客户端来list或watch资源。比如使用 kubectl 来针对 apiserver ，并且使用Equality-based的条件，可以用：

```shell
kubectl get pods -l environment=production,tier=frontend
```

或使用Set-based 要求：

```shell
kubectl get pods -l 'environment in (production),tier in (frontend)'
```

如已经提到的Set-based要求更具表现力。例如，它们可以对value执行OR运算：

```shell
kubectl get pods -l 'environment in (production, qa)'
```

或者通过exists操作符进行否定限制匹配：

```shell
kubectl get pods -l 'environment,environment notin (frontend)'
```

### API对象中引用

一些Kubernetes对象，例如[services](https://kubernetes.io/docs/user-guide/services)和[replicationcontrollers](https://kubernetes.io/docs/user-guide/replication-controller)，也使用标签选择器来指定其他资源的集合，如[pod](https://kubernetes.io/docs/user-guide/pods)。

#### Service和ReplicationController

一个service针对的pods的集合是用标签选择器来定义的。类似的，一个replicationcontroller管理的pods的群体也是用标签选择器来定义的。

对于这两种对象的Label选择器是用map定义在json或者yaml文件中的，并且只支持Equality-based的条件：

```json
"selector": {
    "component" : "redis",
}
```

要么

```yaml
selector:
    component: redis
```

此选择器（分别为json或yaml格式）等同于component=redis或component in (redis)。



#### 支持set-based要求的资源

Job，[Deployment](http://docs.kubernetes.org.cn/317.html)，[Replica Set](http://docs.kubernetes.org.cn/314.html)，和Daemon Set，支持set-based要求。

```yaml
selector:
  matchLabels:
    component: redis
  matchExpressions:
    - {key: tier, operator: In, values: [cache]}
    - {key: environment, operator: NotIn, values: [dev]}
```

matchLabels 是一个{key,value}的映射。一个单独的 {key,value} 相当于 matchExpressions 的一个元素，它的key字段是”key”,操作符是 In ，并且value数组value包含”value”。 matchExpressions 是一个pod的选择器条件的list 。有效运算符包含In, NotIn, Exists, 和DoesNotExist。在In和NotIn的情况下，value的组必须不能为空。所有的条件，包含 matchLabels andmatchExpressions 中的，会用AND符号连接，他们必须都被满足以完成匹配。



#### Selecting sets of nodes

请参考有关[node selection](http://docs.kubernetes.org.cn/304.html)的文档。







