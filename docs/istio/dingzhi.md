# 定制istio

- Envoy 转发流量到外部服务

```shell
$ istioctl manifest apply --set values.global.outboundTrafficPolicy.mode=ALLOW_ANY
```

- 检查 Mixer 日志

```shell
$ istioctl manifest apply --set values.global.outboundTrafficPolicy.mode=ALLOW_ANY --set values.mixer.policy.enabled=true  --set values.mixer.telemetry.enabled=true --set addonComponents.grafana.enabled=true
```



