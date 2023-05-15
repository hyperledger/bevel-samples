apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ component_name }}-auto
  namespace: flux-{{ network.env.type }}
spec:
  releaseName: {{ component_name }}-auto
  interval: 1m
  chart:
   spec:
    chart: platforms/shared/charts/flux-imageautomation
    sourceRef:
      kind: GitRepository
      name: flux-{{ network.env.type }}
      namespace: flux-{{ network.env.type }}
  values:
    image:
      name: {{ component_name }}
      repository: {{ component_repo }}
{% if network.docker.username is defined %}
      pullSecrets: regcred
{% endif %}      
      pollingInterval: 1m0s
      policy: 
        {{ component_policy | to_nice_yaml | indent(6) }}
      filter: 
        {{ component_filter | to_nice_yaml | indent(8) }}
    git:
      fluxrepo: flux-{{ network.env.type }}
      branch: {{ component_branch }}
      commitMessage: "Updated image"
