{{- define "librenms.volumes.data" }}
- name: librenms-data
  persistentVolumeClaim:
    claimName: librenms-data
{{- end }}

{{- define "librenms.volumemounts.data" }}
- name: librenms-data
  mountPath: /data
{{- end }}


{{- define "librenms.environment.configmap" }}
- configMapRef:
    name: librenms-config
{{- end }}


{{- define "librenms.scc.default" }}
runAsNonRoot: false
allowPrivilegeEscalation: true
{{- end }}


{{- define "librenms.container.webui" }}
- name: webui
  image: librenms/librenms
  envFrom:
  {{- include "librenms.environment.configmap" . | indent 2 }}
  ports:
  - name: http
    containerPort: 8000
    protocol: TCP
  securityContext:
  {{- include "librenms.scc.default" . | indent 4 }}
  volumeMounts:
  {{- include "librenms.volumemounts.data" . | indent 2 }}
{{- end }}


{{- define "librenms.container.dispatcher" }}
- name: dispacher
  image: librenms/librenms
  envFrom:
  - configMapRef:
      name: librenms-config
  env:
  - name: DISPATCHER_NODE_ID
    value: dispatcher1
  - name: SIDECAR_DISPATCHER
    value: "1"
  securityContext:
  {{- include "librenms.scc.default" . | indent 4 }}
  volumeMounts:
  {{- include "librenms.volumemounts.data" . | indent 2 }}
{{- end }}


{{- define "librenms.container.syslogng" }}
- name: syslogng
  image: librenms/librenms
  envFrom:
  - configMapRef:
      name: librenms-config
  env:
  - name: SIDECAR_SYSLOGNG
    value: "1"
  securityContext:
  {{- include "librenms.scc.default" . | indent 4 }}
  volumeMounts:
  {{- include "librenms.volumemounts.data" . | indent 2 }}
{{- end }}


{{- define "librenms.container.snmptrapd" }}
- name: snmptrapd
  image: librenms/librenms
  envFrom:
  - configMapRef:
      name: librenms-config
  env:
  - name: SIDECAR_SNMPTRAPD
    value: "1"
  ports:
  - name: snmp-tcp
    containerPort: 162
    protocol: TCP
  - name: snmp-udp
    containerPort: 162
    protocol: UDP
  securityContext:
  {{- include "librenms.scc.default" . | indent 4 }}
  volumeMounts:
  {{- include "librenms.volumemounts.data" . | indent 2 }}
{{- end }}


{{- define "librenms.container.rrdcached" }}
- name: rrdcached
  image: ghcr.io/crazy-max/rrdcached
  ports:
  - name: rrdcached
    containerPort: 42217
    protocol: TCP
  securityContext:
  {{- include "librenms.scc.default" . | indent 4 }}
  volumeMounts:
  {{- include "librenms.volumemounts.data" . | indent 2 }}
{{- end }}

{{- define "librenms.ingress.domain" }}
{{- $cluster_ingress := lookup "config.openshift.io/v1" "Ingress" "" "cluster" }}
  {{- if $cluster_ingress }}
    {{- $cluster_ingress_domain := $cluster_ingress.spec.domain }}
    {{- printf "%s" $cluster_ingress_domain  | toString }}
  {{- end }}
{{- end }}

{{- define "librenms.default.route" }}
{{- $domain := include "librenms.ingress.domain" . }}
{{- $name := default .Release.Name .name }}
{{- $namespace := default .Release.Namespace .namespace }}
{{- printf "%s-%s.%s" $name $namespace $domain  }}
{{- end }}
