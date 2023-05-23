apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-web
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
      chart: {{ charts_dir }}/dscp-frontend
  releaseName: {{ name }}-web
  values:
    fullNameOverride: {{ name }}-web
    config:
      port: 4000
      logLevel: info
      enableLivenessProbe: false
      inteliApiAddr: {{ inteliApiAddr }}
      logo: inteli.svg
      kinaxisUrl: https://na1.kinaxis.net/web/ACCD01_DEM01/
      persona: {{ persona }}
    auth:
      enabled: {{ org.frontendAuth.enabled }}
{% if org.frontendAuth.enabled %}
      frontendDomain: {{ org.frontendAuth.domain }}
      frontendScope: {{ org.frontendAuth.scope }}
      inteliApiAudience: {{ org.auth.audience }}
{% endif %}
    ingress:
      enabled: false
      className: "gce"
      paths:
        - /
    replicaCount: 1
    image:
      repository: ghcr.io/inteli-poc/inteli-frontend  # {"$imagepolicy": "flux-{{ network.env.type }}:inteli-frontend:name"}
      pullPolicy: Always
      tag: 'latest' # {"$imagepolicy": "flux-{{ network.env.type }}:inteli-frontend:tag"}
    vault:
      alpineutils: ghcr.io/hyperledger/alpine-utils:1.0
      address: {{ component_vault.url }}
      secretprefix: {{ component_vault.secret_path | default('secretsv2') }}/data/{{ component_ns }}
      serviceaccountname: vault-auth
      role: vault-role
      authpath: substrate{{ org.name | lower }}
    proxy:
      provider: {{ network.env.proxy }}
      name: {{ org.name | lower }}
      external_url_suffix: {{ org.external_url_suffix }}
      issuedFor: {{ org.name | lower }}
