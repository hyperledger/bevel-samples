apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-springboot
  namespace: {{ component_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ name }}-springboot
  interval: 1m
  chart:
    spec:
      chart: {{ component_gitops.chart_source }}/springbootwebserver
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}-app
        namespace: flux-{{ network.env.type }}-app
  values:
    image:
      webserver: {{ network.docker.url }}/bevel-supplychain-corda:springboot-latest
      initContainer: {{ network.docker.url }}/bevel-alpine:latest
      imagePullSecret: regcred
    smartContract:
      JAVA_OPTIONS : -Xmx512m
    nodeConf:
      node: {{ node.name|e }}
      nodeRpcPort: {{ node.rpc.port|e }}
      legalName: {{ node.subject|e }}
      devMode: false
      useSSL: false
      readinessCheckInterval: 10
      readinessThreshold: 15
    credentials:
      rpcUser: nodeoperations
      rpcUserPassword: nodeoperationsAdmin
      keystorePassword: newpass
      truststorePassword: newtrustpass
    resources:
      limits: "512Mi"
      requests: "512Mi"
    storage:
      memory: 512Mi
      name: storage-{{ name }}
    web:
      targetPort: {{ node.springboot.targetPort|e }}
      port: {{ node.springboot.port|e }}
