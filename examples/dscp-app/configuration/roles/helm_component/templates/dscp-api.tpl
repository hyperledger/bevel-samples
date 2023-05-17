apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-api
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
      chart: {{ charts_dir }}/dscp-api
  releaseName: {{ name }}-api
  values:
    fullNameOverride: {{ name }}-api
    config:
      port: {{ peer.api.port }}
      externalNodeHost: "{{ name }}"
      externalNodePort: {{ peer.ws.port }}
      logLevel: info  
      externalIpfsHost: "{{ name }}-ipfs-api" 
      externalIpfsPort: {{ peer.ipfs.apiPort }} 
      enableLivenessProbe: true
      substrateStatusPollPeriodMs: 10000
      substrateStatusTimeoutMs: 200000
      ipfsStatusPollPeriodMs: 10000
      ipfsStatusTimeoutMs: 200000
      auth:
        type: NONE
{% if auth_type == 'JWT' %}
        jwksUri: {{ org.auth.jwksUri }}
        audience: {{ org.auth.audience }}
        issuer: {{ org.auth.issuer }}
        tokenUrl: {{ org.auth.tokenUrl }}
{% endif %}
    ingress:
      enabled: false
      className: "gce"
      paths:
        - /v3
    replicaCount: 1
    image:
      repository: ghcr.io/digicatapult/dscp-api
      pullPolicy: IfNotPresent
      tag: 'v4.6.7'
    dscpNode:
      enabled: false

    dscpIpfs:
      enabled: false
      dscpNode:
        enabled: false
    vault:
      alpineutils: ghcr.io/hyperledger/alpine-utils:1.0
      address: {{ component_vault.url }}
      secretprefix: {{ component_vault.secret_path | default('secretsv2') }}/data/{{ component_ns }}/{{ peer.name }}
      serviceaccountname: vault-auth
      role: vault-role
      authpath: substrate{{ org.name | lower }}
