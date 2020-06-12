# istioctl

### istioctl kube-inject

kube-inject手动将Envoy sidecar注入Kubernetes工作负载中。 不支持的资源将保持不变，因此可以安全地对包含一个复杂应用程序的多个Service，ConfigMap，Deployment等定义的单个文件运行kube-inject。 最初创建资源时最好这样做。

已针对Job，DaemonSet，ReplicaSet，Pod和Deployment YAML资源文档更新了k8s.io/docs/concepts/workloads/pods/pod-overview/#pod-templates。 可以根据需要添加对其他基于pod的资源类型的支持。

Istio项目在不断发展，因此Istio sidecar配置可能会有所更改。 如有疑问，请在部署上重新运行istioctl kube-ject以获取最新的更改。

```shell
$ istioctl kube-inject [flags]
```

| Flags                            | Shorthand | Description                                                  |
| -------------------------------- | --------- | ------------------------------------------------------------ |
| `--context <string>`             |           | The name of the kubeconfig context to use (default ``)       |
| `--filename <string>`            | `-f`      | Input Kubernetes resource filename (default ``)              |
| `--injectConfigFile <string>`    |           | injection configuration filename. Cannot be used with --injectConfigMapName (default ``) |
| `--injectConfigMapName <string>` |           | ConfigMap name for Istio sidecar injection, key should be "config". (default `istio-sidecar-injector`) |
| `--istioNamespace <string>`      | `-i`      | Istio system namespace (default `istio-system`)              |
| `--kubeconfig <string>`          | `-c`      | Kubernetes configuration file (default ``)                   |
| `--log_output_level <string>`    |           | Comma-separated minimum per-scope logging level of messages to output, in the form of <scope>:<level>,<scope>:<level>,... where scope can be one of [ads, all, analysis, attributes, authn, cacheLog, citadelClientLog, configMapController, conversions, default, googleCAClientLog, grpcAdapter, kube, kube-converter, mcp, meshconfig, model, patch, processing, rbac, resource, runtime, sdsServiceLog, secretFetcherLog, source, stsClientLog, tpath, translator, util, validation, vaultClientLog] and level can be one of [debug, info, warn, error, fatal, none] (default `default:info,validation:error,processing:error,source:error,analysis:warn`) |
| `--meshConfigFile <string>`      |           | mesh configuration filename. Takes precedence over --meshConfigMapName if set (default ``) |
| `--meshConfigMapName <string>`   |           | ConfigMap name for Istio mesh configuration, key should be "mesh" (default `istio`) |
| `--namespace <string>`           | `-n`      | Config namespace (default ``)                                |
| `--output <string>`              | `-o`      | Modified output Kubernetes resource filename (default ``)    |
| `--valuesFile <string>`          |           | injection values configuration filename. (default ``)        |

### Examples

