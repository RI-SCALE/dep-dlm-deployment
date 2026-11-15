{{- define "dep-dlm.labels" -}}
app.kubernetes.io/name: dep-dlm
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
  ConfigMap data entries for the files matching <glob>, keyed as the testbed
  keys them: the path below <prefix> with "/" replaced by <sep>. files/ holds
  copies made by `make sync` in the testbed's layout, so the keys are the
  testbed's and the subPaths in values.yaml carry over unchanged.

    include "dep-dlm.filesData" (list $ <glob> <prefix> <sep>)
*/}}
{{- define "dep-dlm.filesData" -}}
{{- $root := index . 0 }}{{- $glob := index . 1 }}{{- $prefix := index . 2 }}{{- $sep := index . 3 }}
{{- $files := $root.Files.Glob $glob }}
{{- if not $files }}
{{- fail (printf "nothing matches %s: run `make sync TESTBED=<testbed checkout>`" $glob) }}
{{- end }}
{{- range $path, $_ := $files }}
{{- if not (hasSuffix "_test.rego" $path) }}
  {{ trimPrefix $prefix $path | replace "/" $sep }}: |-
{{ $root.Files.Get $path | indent 4 }}
{{- end }}
{{- end }}
{{- end }}
