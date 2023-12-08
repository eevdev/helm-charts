# AlertmanagerConfig

_Warning: the AlertmanagerConfig CRD from Prometheus Operator is not yet stable ([source](https://prometheus-operator.dev/docs/operator/design/#alertmanagerconfig))._

Specify behavior of Alertmanager with the [AlertmanagerConfig](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1alpha1.AlertmanagerConfig) CRD from Prometheus Operator.

This chart makes it easy to provide common default configs while allowing flexibility to override those defaults for example per namespace. It can also generate Alertmanager templates to be used by a global [AlertmanagerConfiguration](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerConfiguration) (enable with `alertmanagerTemplates.enabled`).

Note: The configuration is scoped to the AlertmanagerConfig namespace; receivers and routes will automatically get a name prefix to avoid conflicts with receivers and routes configured elsewhere. Please see the related configuration options for Alertmanager and Prometheus.

## Configuring Prometheus Operator to support AlertmanagerConfig CRD

### [AlertmanagerSpec](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerSpec)
`alertmanagerConfigSelector` and `alertmanagerConfigNamespaceSelector` specifies which AlertmanagerConfigs to include for your Alertmanager instance. If you have several Alertmanagers in your cluster and you don't want others to include certain AlertmanagerConfigs, you'll need to use these options to specify their inclusion behavior.

The operator injects a label matcher matching the namespace of the AlertmanagerConfig object for all its routes and inhibition rules as the default behavior. [AlertmanagerConfigMatcherStrategy](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.AlertmanagerConfigMatcherStrategy) can be used to disable this constraint.

### [PrometheusSpec](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusSpec)
`enforcedNamespaceLabel` and `excludedFromEnforcement` can be used to enforce a namespace label to alerts etc, which may be useful with the default AlertmanagerConfigMatcherStrategy behavior that applies a namespace label matcher to routes and inhibition rules.

## Chart usage

### Receivers

Receivers can be disabled by setting `enabled: false` to support providing default receivers and overriding those.

You can provide default target type configurations (slackConfigs, pagerdutyConfigs etc.) in `receiverDefaults` (dict) to reduce duplication and support reusability.

By providing a complete configuration as default values for a receiver target type in `receiverDefaults` (eg. for a shared receiver config), it will be possible to enable the target type by setting `- enabled: true` under the related target type config section. Note: there's normally no need to set this `enabled` field in other scenarios, as providing any config will apply the defaults for a given target type, except if you're providing shared AlertmanagerConfig values containing a receiver with multiple target types (eg. send to both Slack and PagerDuty) and you have a case where you want to disable one of the targets for one or more AlertmanagerConfigs.

You can also disable defaults from `receiverDefaults` for certain target type configs with `inheritDefaults: false`, which is useful for uncommon configs, eg. if you use routingKey by default to configure PagerDuty routing but you have a couple of services that use serviceKey instead where you need to remove the defaults.

### Routes

Alerting routes are defined in `alertmanagerConfig.route.routes` either as a list or dict.

Routes can be disabled by setting `enabled: false` to support providing default routes and overriding those.

The motivation for allowing routes as dicts is to override values based on route name rather than list index (ie. by id rather than an arbitrary number that changes when someone reorders the list).

To support routes as dicts, which are unordered (ie. items will not be in a predictable order), the `order` field (int or string) may be added to configure the ordering of any route. The `prioritizeOrderedRoutes` option (bool) controls whether ordered routes (routes with the `order` field) should go before (true, default) or after (false) unordered routes.

Note: The `order` field is sorted using the built-in Helm function sortAlpha because there doesn't seem to be a numeric sorting function available in Helm.

### Examples
`values.yaml`:
```yaml
labels:
  prometheus: somelabel
alertmanagerConfig:
  receivers:
    default:
      slackConfigs:
      - channel: '<channel name or id>'
    critical:
      slackConfigs:
      - channel: '<channel name or id>'
      pagerdutyConfigs:
      - routingKey:
          key: token
          name: pagerduty
  route:
    routes:
      critical:
        receiver: critical
        matchers:
        - name: severity
          matchType: "="
          value: critical
      infoInhibitor:
        matchers:
        - name: alertname
          matchType: "="
          value: InfoInhibitor
        receiver: void
receiverDefaults:
  slackConfigs:
    apiURL:
      key: api-url # https://slack.com/api/chat.postMessage
      name: alertmanager-slack
    httpConfig:
      authorization:
        type: Bearer
        credentials:
          key: bot-token
          name: alertmanager-slack
    sendResolved: true
```

Enable templates ConfigMap for global Alertmanager config:
```yaml
alertmanagerTemplates:
  enabled: true
  # templatesEnabledByDefault: false # disable all predefined templates to start from scratch with your own
  # slack:
  #   enabled: false # disable individual templates
  # example custom template, myCustomTemplates will be the key for this template in the generated ConfigMap:
  myCustomTemplates:
    enabled: true
    templateString: |-
      {{- define "myCustomTemplates.example" -}}
        {{/* my custom templates */}}
      {{- end -}}
```