apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: {{ name }}-postgresql
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
      chart: {{ charts_dir }}/postgresql
  releaseName: {{ name }}-postgresql
  values:
    image:
      registry: docker.io
      repository: bitnami/postgresql
      tag: 14.4.0
      pullPolicy: IfNotPresent
      debug: false
    global:
      postgresql:
        auth:
          postgresPassword: {{ password }}
          database: {{ first_db_name }}
        service:
          ports:
            postgresql: {{ postgres_port }}
    primary:
      initdb:
        scripts:
          create_second_db.sql: |
            CREATE DATABASE "{{ second_db_name }}";
            GRANT ALL PRIVILEGES ON DATABASE "{{ second_db_name }}" TO {{ username }};
        user: {{ username }}
        password: {{ password }}
