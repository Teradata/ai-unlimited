# Deploy with Docker Compose

## AI Unlimited

### With AWS

```
docker compose -f ai-unlimited.yaml -f aws-credentials-env-vars.yaml.yaml 
```
### With Azure
```
docker compose -f ai-unlimited.yaml -f azure-credentials-env-vars.yaml.yaml 
```

## Jupyter

```
docker compose -f jupyter.yaml up
```
## Jupyter and AI Unlimited

### With AWS, using environment variables

```
docker compose -f ai-unlimited.yaml -f aws-credentials-env-vars.yaml -f jupyter.yaml up
```

### With AWS, using a local volume with credentials

```
docker compose -f ai-unlimited.yaml -f aws-credentials-local-volume.yaml -f jupyter.yaml up
```

### With Azure, using environment variables

```
docker compose -f ai-unlimited.yaml -f azure-credentials-env-vars.yaml -f jupyter.yaml up
```

### With Azure, using a local volume with credentials

```
docker compose -f ai-unlimited.yaml -f azure-credentials-local-volume.yaml -f jupyter.yaml up
```

### With Aws and Azure, using two local credential volumes

```
docker compose -f ai-unlimited.yaml -f aws-credentials-local-volume.yaml -f azure-credentials-local-volume.yaml -f jupyter.yaml up
```