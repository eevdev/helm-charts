Example of global Alertmanager config for the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart.

`alertmanager-config-values.yaml`:
```yaml
fullnameOverride: alertmanager-global-config
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
alertmanagerTemplates:
  enabled: true # creates ConfigMap with templates
```

`kube-prometheus-stack-values.yaml`:
```yaml
alertmanager:
  alertmanagerSpec:
    alertmanagerConfiguration: # https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerConfiguration
      name: alertmanager-global-config
      global: # AlertmanagerGlobalConfig: https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerGlobalConfig
        # httpConfig:
        #   authorization:
        #     type: Bearer
        #     credentials:
        #       key: bot-token
        #       name: alertmanager-slack
        slackApiUrl:
          key: api-url # https://slack.com/api/chat.postMessage
          name: alertmanager-slack # this secret must be manually created, eg. `kubectl create secret generic alertmanager-slack --from-literal=api-url=https://slack.com/api/chat.postMessage` # with bot-token, add: `--from-literal=bot-token=<slack bot token>`
      templates: # []SecretOrConfigMap: https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.SecretOrConfigMap
      - configMap:
          key: all
          name: alertmanager-global-config
      # - configMap:
      #     key: slack
      #     name: alertmanager-global-config
      # - configMap:
      #     key: url
      #     name: alertmanager-global-config
```
