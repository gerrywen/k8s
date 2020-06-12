## Helm chart模版语法

### 1.1.表达式

- 模版表达式： {{ 模版表达式 }}
- 模版表达式： {{- 模版表达式 -}} 
  - 表示去掉表达式输出结果前面和后面的空格

- 模版表达式： {{- 模版表达式 }}
  - 去掉前面空格
- 模版表达式： {{ 模版表达式 -}} 
  -  去掉后面空格

### 1.2.变量

- 默认情况点( . ), 代表全局作用域，用于引用全局对象。

  

- **例子**：这里引用了全局作用域下的Values对象中的key属性。 

  ```yaml
  {{ .Values.key }}
  ```

  

- helm全局作用域中有两个重要的全局对象：**Values和Release**

  - `Values`代表的就是values.yaml定义的参数，通过**.Values**可以引用任意参数。

    

  - **例子：引用嵌套对象例子，跟引用json嵌套对象类似**

    ```yaml
    {{ .Values.replicaCount }}
    ```

    ```yaml
    {{ .Values.image.repository }}
    ```

    

  - `Release`代表一次应用发布，下面是Release对象包含的属性字段:

    - Release.Name  \- release的名字，一般通过Chart.yaml定义，或者通过helm命令在安装应用的时候指定。
    - Release.Time   - release安装时间
    - Release.Namespace   - k8s名字空间
    - Release.Revision    - release版本号，是一个递增值，每次更新都会加一
    - Release.IsUpgrade  - true代表，当前release是一次更新.
    - Release.IsInstall    - true代表，当前release是一次安装

  - 例子:

    ```yaml
    {{ .Release.Name }}
    ```

  - 除了系统自带的变量，我们自己也可以自定义模版变量。

    变量名以$开始命名， 赋值运算符是 **:= (冒号+等号)**

    ```yaml
    {{- $relname := .Release.Name -}}
    ```

  - 引用自定义变量:

    不需要 . 引用

    ```yaml
    {{ $relname }}
    ```



### 1.3.函数&管道运算符

- 调用函数的语法：{{ functionName arg1 arg2... }}

  - 例子:调用quote函数，将结果用“”引号包括起来

    ```yaml
    {{ quote .Values.favorite.food }}
    ```

- 管道（pipelines）运算符 |

  类似linux shell命令，通过管道 | 将多个命令串起来，处理模版输出的内容。

  - 例子：将.Values.favorite.food传递给quote函数处理，然后在输出结果

    ```yaml
    {{ .Values.favorite.food | quote  }}
    ```

  - 先将.Values.favorite.food的值传递给upper函数将字符转换成大写，然后专递给quote加上引号包括起来。

    ```
    {{ .Values.favorite.food | upper | quote }}
    ```

  - 如果.Values.favorite.food为空，则使用default定义的默认值

    ```
    {{ .Values.favorite.food | default "默认值" }}
    ```

  - 将.Values.favorite.food输出5次

    ```
    {{ .Values.favorite.food | repeat 5 }}
    ```

  - 对输出结果缩进2个空格

    ```
    {{ .Values.favorite.food | nindent 2 }}
    ```

- 常用的关系运算符>、 >=、 <、!=、与或非在helm模版中都以函数的形式实现。

  关系运算函数定义：

  ```
  eq  相当于 =
  ne  相当于 !=
  lt 相当于 <=
  gt  相当于 >=
  and 相当于 &&
  or  相当于 ||
  not 相当于 !
  ```

  - 例子:相当于 if (`.Values.fooString && (.Values.fooString == "foo")`)

    ```yaml
    {{ if and .Values.fooString (eq .Values.fooString "foo") }}
        {{ ... }}
    {{ end }}
    ```



### 1.4.流程控制语句

#### 1.4.1. IF/ELSE

```
语法:

{{ if 条件表达式 }}
# Do something
{{ else if 条件表达式 }}
# Do something else
{{ else }}
# Default case
{{ end }}
```



```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink | default "tea" | quote }}
  food: {{ .Values.favorite.food | upper | quote }}
  {{if eq .Values.favorite.drink "coffee"}}
    mug: true
  {{end}}
```



#### 1.4.2. `with`

with主要就是用来修改 . 作用域的，默认 . 代表全局作用域，with语句可以修改.的含义.

```
语法:

{{ with 引用的对象 }}
这里可以使用 . (点)， 直接引用with指定的对象
{{ end }}
```



```
例子:

#.Values.favorite是一个object类型

{{- with .Values.favorite }}
drink: {{ .drink | default "tea" | quote }}   #相当于.Values.favorite.drink
food: {{ .food | upper | quote }}
{{- end }}
```



**注意**：不能在with作用域内使用 . 引用全局对象, 如果非要在with里面引用全局对象，可以先在with外面将全局对象复制给一个变量，然后在with内部使用这个变量引用全局对象。

```yaml
例子:

{{- $release:= .Release.Name -}}   #先将值保存起来

{{- with .Values.favorite }}
drink: {{ .drink | default "tea" | quote }}   #相当于.Values.favorite.drink
food: {{ .food | upper | quote }}

release: {{ $release }} #间接引用全局对象的值
{{- end }}
```





#### 1.4.3. range

range主要用于循环遍历数组类型。

```
语法1:

#遍历map类型，用于遍历键值对象

#变量𝑘𝑒𝑦代表对象的属性名，val代表属性值

{{- range 𝑘𝑒𝑦,val := 键值对象 }}
{{ $key }}: {{ $val | quote }}
{{- end}}
```

```
语法2：

{{- range 数组 }}

{{ . | title | quote }} # . (点)，引用数组元素值。

{{- end }}
```

- 例子

  ```yaml
  #values.yaml定义
   
  #map类型
  favorite:
    drink: coffee
    food: pizza
   
  #数组类型
  pizzaToppings:
    - mushrooms
    - cheese
    - peppers
    - onions
   
  map类型遍历例子:
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
   
  数组类型遍历例子:
  {{- range .Values.pizzaToppings}}
  {{ . | quote }}
  {{- end}}
  ```





### 1.5.子模版定义

我们可以在_(下划线)开头的文件中定义子模版，方便后续复用。

helm create默认为我们创建了_helpers.tpl 公共库定义文件，可以直接在里面定义子模版，也可以新建一个，只要以下划线开头命名即可。

- 子模版语法:

  ```
  定义模版
  {{ define "模版名字" }} 模版内容 {{ end }}
  ```

  ```
  引用模版:
  {{ include "模版名字" 作用域}}
  ```

- 例子

  ```yaml
  #模版定义
  {{- define "mychart.app" -}}
  app_name: {{ .Chart.Name }}
  app_version: "{{ .Chart.Version }}+{{ .Release.Time.Seconds }}"
  {{- end -}}
   
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: {{ .Release.Name }}-configmap
    labels:
      {{ include "mychart.app" . | nindent 4 }} #引用mychart.app模版内容，并对输出结果缩进4个空格
  data:
    myvalue: "Hello World"
  ```

  



### 1.6.调试

编写好chart包的模版之后，我们可以给helm命令加上--debug --dry-run 两个参数，**让helm输出模版结果，但是不把模版输出结果交给k8s处理**。

##### 例子：

helm install命令类似，加上--debug --dry-run两个参数即可

```shell
helm install --name mall-config-service --namespace mall mall-config-0.1.0.tgz  --debug --dry-run
```

```shell
helm upgrade --debug --dry-run -i --set replicas=2 --set host=www.xxxx.com myapp ./myapp
```

