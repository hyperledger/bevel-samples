## Charts for DSCP Application

***

This folder contains helm charts which are used by the ansible playbooks for the deployment of the application components. Each chart folder contains a directory for templates, chart file and the corresponding values file.

### Example Folder Structure

***

```
/dscp-api
|--templates
|  |-- _helpers.tpl
|  |-- certificate.yaml
|  |-- configmap.yaml
|  |-- deployment.yaml
|  |-- ingress.yaml
|  |-- service.yaml
|--Chart.yaml
|--values.yaml
```

### Charts Description

***

1. ***certissuer*** - This folder contains chart templates for generating a managed tls certificate.

2. ***dscp-api*** - This folder contains chart templates for deploying the dscp api.

3. ***dscp-frontend*** - This folder contains chart templates for deploying the application frontend. WIP

4. ***inteli-api*** - This folder contains chart templates for deploying the inteli-api, which acts as a middleware between the frontend and the dscp api. WIP

5. ***dscp-identity-service*** - This folder contains chart templates for deploying identities used by the dscp api and the react application.

6. ***postgresql*** - This folder contains chart templates for deploying an instance of postgresql on the kubernetes cluster.
