apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-id-service
  namespace: {{ component_ns }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  interval: 1m
  chart:
    spec:
      interval: 1m
      sourceRef:
        kind: GitRepository
        name: flux-{{ network.env.type }}
        namespace: flux-{{ network.env.type }}
      chart: {{ charts_dir }}/dscp-identity-service
  releaseName: {{ name }}-id-service
  values:
    fullNameOverride: {{ name }}-id-service
    config:
      externalNodeHost: {{ name }}
      externalPostgresql: {{ db_address }}.{{ component_ns }}
      port: {{ peer.id_service.port }}
      logLevel: info
      dbName: {{ peer.id_service.db_name }}
      dbPort: {{ peer.postgresql.port }}
      enableLivenessProbe: true
      selfAddress: 
      auth:
        type: NONE
        jwksUri: {{ auth_jwksUri }}
        audience: {{ auth_audience }}
        issuer: {{ auth_issuer }}
        tokenUrl: {{ auth_tokenUrl }}
    ingress:
      enabled: false
      # annotations: {}
      # className
      paths:
        - /v1/members
    replicaCount: 1
    image:
      repository: ghcr.io/digicatapult/dscp-identity-service
      pullPolicy: IfNotPresent
      tag: 'v1.6.0'
      pullSecrets: 

    postgresql:
      enabled: false
      postgresqlDatabase: {{ peer.id_service.db_name }}
      postgresqlUsername: {{ peer.postgresql.user }}
      postgresqlPassword: {{ peer.postgresql.password }}
    dscpNode:
      enabled: false

    vault:
      alpineutils: ghcr.io/hyperledger/alpine-utils:1.0
      address: {{ component_vault.url }}
      secretprefix: {{ component_vault.secret_path | default('secretsv2') }}/data/{{ component_ns }}/{{ peer.name }}
      serviceaccountname: vault-auth
      role: vault-role
      authpath: substrate{{ org.name | lower }}
