apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-inteli-api
  namespace: {{ component_ns }}
  annotations:
    fluxcd.io/automated: "false"
    repository.fluxcd.io/app: image.repository
    tag.fluxcd.io/app: image.tag
    filter.fluxcd.io/app: 'glob:v1.0.*'
spec:
  interval: 1m
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/inteli-api
  releaseName: {{ name }}-inteli-api
  values:
    fullnameOverride: {{ name }}-inteli-api
    config:
      port: {{ peer.inteli_api.port }}
      externalPostgresql: {{ db_address }}.{{ component_ns }}
      dbName: {{ peer.inteli_api.db_name }}
      dbPort: {{ peer.postgresql.port }}
      dscpApiHost: {{ dscp_api_addr }}.{{ component_ns }}
      dscpApiPort: {{ peer.api.port }}
      logLevel: info
      identityServiceHost: {{ id_service_addr }}.{{ component_ns }}
      identityServicePort: {{ peer.id_service.port }}
      externalAddress: {{ external_addr }}
      auth:
        type: {{ auth_type }}
{% if auth_type == 'JWT' %}
        jwksUri: {{ org.auth.jwksUri }}
        audience: {{ org.auth.audience }}
        issuer: {{ org.auth.issuer }}
        tokenUrl: {{ org.auth.tokenUrl }}
{% endif %}
    deployment:
      annotations: {}
      livenessProbe:
        enabled: true
      replicaCount: 1

    ingress:
      enabled: false
      annotations: {}
      # className: ""
      paths:
        - /v1/attachment
        - /v1/build
        - /v1/order
        - /v1/part
        - /v1/recipe

    service:
      annotations: {}
      enabled: false
      port: 

    image:
      repository: ghcr.io/inteli-poc/inteli-api # {"$imagepolicy": "flux-{{ network.env.type }}:inteli-api:name"}
      pullPolicy: IfNotPresent
      tag: 'v1.0.0' # {"$imagepolicy": "flux-{{ network.env.type }}:inteli-api:tag"}
      pullSecrets: 

    postgresql:
      enabled: false
      postgresqlDatabase: {{ peer.inteli_api.db_name }}
      postgresqlUsername: {{ peer.postgresql.user }}
      postgresqlPassword: {{ peer.postgresql.password }}


    proxy:
      provider: {{ network.env.proxy }}
      name: {{ org.name | lower }} 
      external_url_suffix: {{ org.external_url_suffix }}
      port: {{ peer.inteli_api.ambassador }}
      issuedFor: {{ org.name | lower }}
