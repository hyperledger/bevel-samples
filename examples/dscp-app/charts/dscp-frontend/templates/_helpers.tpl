{{/*
Create name to be used with deployment.
*/}}
{{- define "inteli-frontend.fullname" -}}
    {{- if .Values.fullNameOverride -}}
        {{- .Values.fullNameOverride | trunc 63 | trimSuffix "-"| lower -}}
    {{- else -}}
      {{- $name := default .Chart.Name .Values.nameOverride -}}
      {{- if contains $name .Release.Name -}}
        {{- .Release.Name | trunc 63 | trimSuffix "-" | lower -}}
      {{- else -}}
        {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" | lower -}}
      {{- end -}}
    {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "inteli-frontend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" | lower }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "inteli-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "inteli-frontend.fullname" . }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "inteli-frontend.labels" -}}
helm.sh/chart: {{ include "inteli-frontend.chart" . }}
{{ include "inteli-frontend.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
