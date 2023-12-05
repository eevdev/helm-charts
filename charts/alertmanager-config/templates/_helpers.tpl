{{/*
Expand the name of the chart.
*/}}
{{- define "alertmanager-config.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "alertmanager-config.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "alertmanager-config.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "alertmanager-config.labels" -}}
helm.sh/chart: {{ include "alertmanager-config.chart" . }}
{{ include "alertmanager-config.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "alertmanager-config.selectorLabels" -}}
app.kubernetes.io/name: {{ include "alertmanager-config.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- /* Generate receivers. */}}
{{- define "alertmanager-config.receivers" -}}
{{- $receiverDefaults := .Values.receiverDefaults -}}
{{- $receivers := list -}}
{{- range $name, $receiverConfig := .Values.alertmanagerConfig.receivers }}
  {{- /* Allow disabling default receivers. */}}
  {{- if or $receiverConfig.enabled (typeIs "<nil>" $receiverConfig.enabled) }}
    {{- $receiver := dict -}}
    {{- $_ := set $receiver "name" $name }}
    {{- /* For each target type (eg. emailConfigs) of receiver, apply default values and add to list of targets. */}}
    {{- range $targetType, $targetTypeConfigs := (omit $receiverConfig "enabled") }}
      {{- $defaults := (get $receiverDefaults $targetType | default dict) }}
      {{- $receiverTargetTypeConfigs := list }}
      {{- range $targetTypeConfig := $targetTypeConfigs }}
        {{- /* Allow enabling a target type without further config to rely entirely on receiverDefaults. */}}
        {{- if or $targetTypeConfig.enabled (typeIs "<nil>" $targetTypeConfig.enabled) }}
          {{- if or $targetTypeConfig.inheritDefaults (typeIs "<nil>" $targetTypeConfig.inheritDefaults) }}
            {{- $receiverTargetTypeConfigs = append $receiverTargetTypeConfigs (mustMergeOverwrite (deepCopy $defaults) (omit $targetTypeConfig "enabled" "inheritDefaults")) }}
          {{- else }}
            {{- $receiverTargetTypeConfigs = append $receiverTargetTypeConfigs (omit $targetTypeConfig "enabled" "inheritDefaults") }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- with $receiverTargetTypeConfigs }}
        {{- $_ := set $receiver $targetType . }}
      {{- end }}
    {{- end }}
    {{- with $receiver }}
      {{- $receivers = append $receivers $receiver }}
    {{- end }}
  {{- end }}
{{- end }}
{{- with $receivers -}}
receivers:
{{ toYaml . }}
{{- end }}
{{- end }}

{{- /* Generate routes from .Values.alertmanagerConfig.route.routes. */}}
{{- define "alertmanager-config.routes" -}}
{{- with .Values.alertmanagerConfig.route -}}
routes:
  {{- /*
    Convert .routes to list if type is dict/map.
    Motivation for supporting dict type is to be able to override values by name.
  */}}
  {{- if (kindIs "map" .routes) }}{{ $_ := set . "routes" (values .routes) }}{{ end }}
  {{- $orderedRoutes := dict }}
  {{- $unorderedRoutes := list }}
  {{- /*
    $route.enabled must be true/non-empty or nil/missing to be included, ie. routes are enabled unless this is false.
    $route.order may be set to specify sorting order for each route.
    If order is not provided for a route it will be put before or after ordered items based on the value of prioritizeOrderedRoutes.
  */}}
  {{- range $route := (.routes | default list) }}
    {{- if or $route.enabled (typeIs "<nil>" $route.enabled) }}
      {{- if (typeIs "<nil>" $route.order) }}
        {{- $unorderedRoutes = append $unorderedRoutes (omit $route "enabled" "order") }}
      {{- else }}
        {{- /*
          Work-around for missing numeric ordering in Helm (at least I couldn't find a proper way).
          As keys are sorted alphabetically with sortAlpha, we need to prefix lower numbers with zeros to get correct
          sorting (otherwise 2 would come after 10 etc.).
          Currently sort order up to 999 is supported, but it could be increased if necessary.
        */}}
        {{- if and (not (kindIs "string" $route.order)) (lt (int $route.order) 100) }}
          {{- $_ := set $route "order" (ternary (printf "00%d" (int $route.order)) (printf "0%d" (int $route.order)) (lt (int $route.order) 10)) }}
        {{- end }}
        {{- if hasKey $orderedRoutes (toString $route.order) }}
          {{- fail (printf "Conflicting order '%s' for routes.\nRoute 1: %s.\nRoute 2: %s." $route.order (omit $route "enabled" "order") (get $orderedRoutes (toString $route.order))) }}
        {{- end }}
        {{- $_ := set $orderedRoutes (toString $route.order) (omit $route "enabled" "order") }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if not $.Values.prioritizeOrderedRoutes }}
    {{- with $unorderedRoutes }}
      {{- toYaml . | nindent 0 }}
    {{- end }}
  {{- end }}
  {{- /* Sort ordered routes alphabetically and print. */}}
  {{- range $key := (keys $orderedRoutes | sortAlpha) }}
    {{- toYaml (list (get $orderedRoutes $key)) | nindent 0 }}
  {{- end }}
  {{- if $.Values.prioritizeOrderedRoutes }}
    {{- with $unorderedRoutes }}
      {{- toYaml . | nindent 0 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
