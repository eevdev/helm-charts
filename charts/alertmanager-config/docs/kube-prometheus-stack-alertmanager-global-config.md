Example of configuring global Alertmanager config with an AlertmanagerConfig object when using the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart.

`alertmanager-config-values.yaml`:
```yaml
fullnameOverride: global-config
alertmanagerConfig: # https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1alpha1.AlertmanagerConfigSpec
  receivers:
    default:
      # ...
  route:
    receiver: default
    groupBy:
    - alertname
    - namespace
    - severity
    groupWait: 10s
    groupInterval: 5m
    repeatInterval: 3h
```

`kube-prometheus-stack-values.yaml`:
```yaml
alertmanager:
  alertmanagerSpec:
    alertmanagerConfiguration: # https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerConfiguration
      name: global-config
    #   global: # AlertmanagerGlobalConfig: https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerGlobalConfig
    #   templates: # SecretOrConfigMap: https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.SecretOrConfigMap
```
