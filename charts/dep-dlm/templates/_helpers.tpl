{{- define "dep-dlm.labels" -}}
app.kubernetes.io/name: dep-dlm
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
  ConfigMap data entries for the files matching <glob>, keyed as the testbed
  keys them: the path below <prefix> with "/" replaced by <sep>. files/ holds
  symlinks into the vendor/dep-dlm-testbed submodule, so the keys are the
  testbed's and the subPaths in values.yaml carry over unchanged.

    include "dep-dlm.filesData" (list $ <glob> <prefix> <sep>)
*/}}
{{- define "dep-dlm.filesData" -}}
{{- $root := index . 0 }}{{- $glob := index . 1 }}{{- $prefix := index . 2 }}{{- $sep := index . 3 }}
{{- $files := $root.Files.Glob $glob }}
{{- if not $files }}
{{- fail (printf "nothing matches %s: is the submodule checked out? (git submodule update --init)" $glob) }}
{{- end }}
{{- range $path, $_ := $files }}
{{- if not (hasSuffix "_test.rego" $path) }}
  {{ trimPrefix $prefix $path | replace "/" $sep }}: |-
{{ $root.Files.Get $path | indent 4 }}
{{- end }}
{{- end }}
{{- end }}
