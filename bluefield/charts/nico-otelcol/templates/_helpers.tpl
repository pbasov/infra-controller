{{/*
Expand the name of the chart.
*/}}
{{- define "nico-otelcol.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "nico-otelcol.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- /* DPF names the helm release <dpu-cluster>-<dpu-service>-<hash>; */}}
{{- /* use it verbatim so resource names stay short and don't get a   */}}
{{- /* redundant chart-name suffix appended.                          */}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nico-otelcol.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nico-otelcol.labels" -}}
helm.sh/chart: {{ include "nico-otelcol.chart" . }}
{{ include "nico-otelcol.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nico-otelcol.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nico-otelcol.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Prometheus scrape port (must match DPUServiceConfiguration configPorts in NICo dpf_services).
*/}}
{{- define "nico-otelcol.prometheusPort" -}}
{{- default 9999 .Values.prometheusPort -}}
{{- end -}}

{{/*
transceiver-exporter sidecar image.

transceiverExporter.image.repository wins when set. Otherwise the repository is
derived from image.repository by swapping its trailing path segment for
`transceiver-exporter`: the two images are published side by side in the same
registry and namespace by the same CI run, so this resolves to the canonical NGC
path for a canonical install and follows the mirror for a mirrored one.

It is derived rather than hardcoded because NICo writes image.{repository,tag}
into the DPUServiceTemplate values from DpfServiceConfig (otelcol_service,
crates/api-core/src/dpf_services.rs), so a deployment that mirrors the images
gets otelcol-contrib from its mirror but a hardcoded sidecar default from a
registry it may not be able to reach. That is not cosmetic: the sidecar 403s and
never starts, the DPUService never releases its DPUNodeMaintenance requestor,
and the DPU wedges rather than failing cleanly. Deriving the path makes the
sidecar follow otelcol-contrib without a per-site extra_helm_values overlay.

The tag falls back to image.tag and then the chart appVersion, matching the
otelcol-contrib container.
*/}}
{{- define "nico-otelcol.transceiverExporterImage" -}}
{{- $repository := .Values.transceiverExporter.image.repository -}}
{{- if not $repository -}}
{{- $repository = regexReplaceAll "[^/]+$" .Values.image.repository "transceiver-exporter" -}}
{{- end -}}
{{- $tag := .Values.transceiverExporter.image.tag | default .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
