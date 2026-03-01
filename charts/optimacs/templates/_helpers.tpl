{{/*
Expand the name of the chart.
*/}}
{{- define "ac-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated to 63 chars to satisfy DNS naming constraints.
*/}}
{{- define "ac-server.fullname" -}}
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
Chart label — name + version.
*/}}
{{- define "ac-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "ac-server.labels" -}}
helm.sh/chart: {{ include "ac-server.chart" . }}
{{ include "ac-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used by the ac-server Deployment and Service.
*/}}
{{- define "ac-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ac-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Secret that holds ac_server.conf (rendered with DB credentials).
*/}}
{{- define "ac-server.configSecretName" -}}
{{- include "ac-server.fullname" . }}-config
{{- end }}

{{/*
PVC names for ac-server persistent volumes.
*/}}
{{- define "ac-server.clientDirPvcName" -}}
{{- include "ac-server.fullname" . }}-client-dir
{{- end }}

{{- define "ac-server.fwDirPvcName" -}}
{{- if .Values.persistence.fwDir.existingClaim }}
{{- .Values.persistence.fwDir.existingClaim }}
{{- else }}
{{- include "ac-server.fullname" . }}-fw-dir
{{- end }}
{{- end }}

{{- define "ac-server.imgDirPvcName" -}}
{{- if .Values.persistence.imgDir.existingClaim }}
{{- .Values.persistence.imgDir.existingClaim }}
{{- else }}
{{- include "ac-server.fullname" . }}-img-dir
{{- end }}
{{- end }}

{{/*
──────────────────────────────────────────────────────────────────────────────
MySQL helpers
──────────────────────────────────────────────────────────────────────────────
*/}}

{{/*
Write endpoint hostname.
When the embedded MySQL sub-chart is enabled this resolves to the bitnami/mysql
primary service (<release>-mysql-primary).  For an external DB the operator
must set config.dbHost to their host.
*/}}
{{- define "optimacs.mysql.host" -}}
{{- if .Values.mysql.enabled -}}
{{- printf "%s-mysql-primary" .Release.Name }}
{{- else -}}
{{- .Values.config.dbHost }}
{{- end }}
{{- end }}

{{- define "optimacs.mysql.database" -}}
{{- if .Values.mysql.enabled -}}
{{- .Values.mysql.auth.database }}
{{- else -}}
{{- .Values.config.dbName }}
{{- end }}
{{- end }}

{{- define "optimacs.mysql.user" -}}
{{- if .Values.mysql.enabled -}}
{{- .Values.mysql.auth.username }}
{{- else -}}
{{- .Values.config.dbUser }}
{{- end }}
{{- end }}

{{/*
──────────────────────────────────────────────────────────────────────────────
Web UI helpers
──────────────────────────────────────────────────────────────────────────────
*/}}

{{- define "optimacs.ui.fullname" -}}
{{- printf "%s-ui" (include "ac-server.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "optimacs.ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ac-server.name" . }}-ui
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "optimacs.ui.labels" -}}
helm.sh/chart: {{ include "ac-server.chart" . }}
{{ include "optimacs.ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "optimacs.ui.secretName" -}}
{{- printf "%s-ui-secret" (include "ac-server.fullname" .) }}
{{- end }}

{{/*
──────────────────────────────────────────────────────────────────────────────
Redis helpers
──────────────────────────────────────────────────────────────────────────────
*/}}

{{/*
Redis connection URL.
When the embedded Redis sub-chart is enabled (architecture: replication) this
resolves to the bitnami/redis primary (master) service, which Sentinel keeps
updated after any failover — no URL change required.
For an external Redis instance set redis.url directly.
Returns an empty string when Redis is disabled.
*/}}
{{- define "optimacs.redis.url" -}}
{{- if .Values.redis.enabled -}}
{{- printf "redis://%s-redis-master:6379" .Release.Name }}
{{- else -}}
{{- .Values.redis.url }}
{{- end }}
{{- end }}

{{/*
──────────────────────────────────────────────────────────────────────────────
Databunker PII vault helpers
──────────────────────────────────────────────────────────────────────────────
*/}}

{{- define "optimacs.databunker.fullname" -}}
{{- printf "%s-databunker" (include "ac-server.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "optimacs.databunker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ac-server.name" . }}-databunker
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "optimacs.databunker.labels" -}}
helm.sh/chart: {{ include "ac-server.chart" . }}
{{ include "optimacs.databunker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "optimacs.databunker.secretName" -}}
{{- printf "%s-databunker-secret" (include "ac-server.fullname" .) }}
{{- end }}

{{- define "optimacs.databunker.pvcName" -}}
{{- printf "%s-databunker-data" (include "ac-server.fullname" .) }}
{{- end }}

{{/*
Internal URL at which optimacs-ui reaches Databunker.
When databunker.enabled=true this resolves to the in-cluster ClusterIP service.
Set databunker.enabled=false and databunker.url for an external instance.
*/}}
{{- define "optimacs.databunker.url" -}}
{{- if .Values.databunker.enabled -}}
{{- printf "http://%s:%d" (include "optimacs.databunker.fullname" .) (int .Values.databunker.port) }}
{{- else -}}
{{- .Values.databunker.url | default "" }}
{{- end }}
{{- end }}

{{/*
──────────────────────────────────────────────────────────────────────────────
Telemetry pipeline helpers
──────────────────────────────────────────────────────────────────────────────
*/}}

{{/*
Redpanda broker bootstrap address.
When the embedded Redpanda sub-chart is enabled this resolves to the in-cluster
Kafka listener (<release>-redpanda:9092).
For an external broker supply redpanda.externalBrokers (comma-separated).
Returns an empty string when both are unset — ac-server disables telemetry.
*/}}
{{- define "optimacs.telemetry.redpanda.brokers" -}}
{{- if .Values.redpanda.enabled -}}
{{- printf "%s-redpanda:9092" .Release.Name }}
{{- else -}}
{{- .Values.redpanda.externalBrokers }}
{{- end }}
{{- end }}

{{/*
VictoriaMetrics Prometheus remote-write URL.
Returns victoriametrics.remoteWriteUrl verbatim — the operator must supply the
full URL of the existing in-cluster VictoriaMetrics /api/v1/write endpoint.
Returns an empty string when unset; the Vector deployment is skipped in that case.

Example values:
  http://victoria-metrics.monitoring.svc:8428/api/v1/write
  http://vmsingle-stack.monitoring.svc:8428/api/v1/write
*/}}
{{- define "optimacs.telemetry.victoriametrics.url" -}}
{{- .Values.victoriametrics.remoteWriteUrl }}
{{- end }}

{{/*
Vector deployment fullname.
*/}}
{{- define "optimacs.vector.fullname" -}}
{{- printf "%s-vector" (include "ac-server.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
