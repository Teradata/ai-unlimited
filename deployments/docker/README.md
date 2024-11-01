# Deploy AI Unlimited with Docker Compose

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. Pre-requisite Steps](#1-pre-requisite-steps)
  - [1.1 Cleanup](#11-cleanup)
  - [1.2 Initial API Key](#12-initial-api-key)
    - [On macOS/Linux](#on-macoslinux)
    - [On Windows](#on-windows)
  - [1.3 TLS/SSL Certificates](#13-tlsssl-certificates)
  - [1.4 Debug mode](#14-debug-mode)
- [2. Deploy AI Unlimited with AWS](#2-deploy-ai-unlimited-with-aws)
- [3. Deploy AI Unlimited with Azure](#3-deploy-ai-unlimited-with-azure)
- [4. Deploy Jupyter](#4-deploy-jupyter)
- [5. Deploy Jupyter and AI Unlimited](#5-deploy-jupyter-and-ai-unlimited)
  - [5.1 With AWS](#51-with-aws)
  - [5.2 With Azure](#52-with-azure)
  - [5.3 With AWS and Azure](#53-with-aws-and-azure)

<!-- /code_chunk_output -->

## 1. Pre-requisite Steps

### 1.1 Cleanup

If you spun up AI Unlimited previously on the same domain (i.e. `localhost` or `my.ai-unlimited.local`) we recommend to cleanup the browser cache.

If you pulled or used the Docker images previously, and are still there, we recommend to delete them, like so:

```bash
docker-compose -f ai-unlimited.yaml down
docker-compose -f ai-unlimited.yaml rm -fsv
docker rmi $(docker images 'teradata/ai-unlimited*' -qa | sort | uniq) || true
docker images 'teradata/ai-unlimited*'
```

If you'd like a new fresh installation with no previous users in AI Unlimited, TLS/SSL certificates, or configuration, we recommend to delete these files or the files with the configration you don't want to persist:

```bash
rm -rf ./volumes 
rm -rf ./ssl
```

### 1.2 Initial API Key

An Initial API Key is required in the `AI_UNLIMITED_INIT_API_KEY` environment variable to start the docker-compose stack. You can generate one by doing the following:

#### On macOS/Linux

```bash
source generate_api_key.sh
```

#### On Windows

Execute this script and follow the instructions from the scripts output.

```powershell
./generate_api_key.ps1
```

### 1.3 TLS/SSL Certificates

To execute AI Unlimited with TLS/SSL enabled you need a Certificate & Private Key pair and (optional but recommended) a CA certificate. There are many different ways to generate them for testing environments on localhost, here is one of them using `mkcert`:

1. Install `mkcert` following the instructions according to your OS from its [Github repository](https://github.com/FiloSottile/mkcert). If you are on macOS execute:

    ```bash
    brew install mkcert
    brew install nss # if you use Firefox
    ```

2. Generate and install the CA certificate, executing:

    ```bash
    mkcert -install
    ```

3. Generate the Certificate and Private Key
    - generate them in the desired directory, for example, in `./ssl/certs/` and `./ssl/private/`
    - if you have a local custom DNS in your `/etc/hosts`, include the hostname at the end of the list, for example, `my.ai-unlimited.local`

    ```bash
    mkdir -p ./ssl/{certs,private}
    mkcert -cert-file ./ssl/certs/ai-unlimited.crt -key-file ./ssl/private/ai-unlimited.key localhost 127.0.0.1 ::1 my.ai-unlimited.local
    ```

Feel free to use `mkcert` as you which - or other tool - as long as you have a valid Certificate & Private Key pair.

### 1.4 Debug mode

To start on debug mode, export the environment variable `AI_UNLIMITED_LOG_LEVEL` with `DEBUG`, like so:

```bash
export AI_UNLIMITED_LOG_LEVEL=DEBUG
```

## 2. Deploy AI Unlimited with AWS

```bash
docker-compose -f ai-unlimited.yaml -f aws-credentials-env-vars.yaml up
```

## 3. Deploy AI Unlimited with Azure

```bash
docker-compose -f ai-unlimited.yaml -f azure-credentials-env-vars.yaml up
```

## 4. Deploy Jupyter

```bash
docker-compose -f jupyter.yaml up
```

## 5. Deploy Jupyter and AI Unlimited

### 5.1 With AWS

If you have the AWS credentials on environment variables, execute:

```bash
docker-compose -f ai-unlimited.yaml -f aws-credentials-env-vars.yaml -f jupyter.yaml up
```

Otherwise, if you are using the AWS configuration files (i.e. `~/.aws/`), execute:

```bash
docker-compose -f ai-unlimited.yaml -f aws-credentials-local-volume.yaml -f jupyter.yaml up
```

### 5.2 With Azure

If you have the Azure credentials on environment variables, execute:

```bash
docker-compose -f ai-unlimited.yaml -f azure-credentials-env-vars.yaml -f jupyter.yaml up
```

Otherwise, if you are using the Azure configuration files (i.e. `~/.azure/`), execute:

```bash
docker-compose -f ai-unlimited.yaml -f azure-credentials-local-volume.yaml -f jupyter.yaml up
```

### 5.3 With AWS and Azure

Same as above but using both files, for AWS and Azure either with the credentials on environment variables or with the configuration files or a conbination of both.
In this example, both environments are using the credentials on environment variables:

```bash
docker-compose -f ai-unlimited.yaml -f aws-credentials-local-volume.yaml -f azure-credentials-local-volume.yaml -f jupyter.yaml up
```
