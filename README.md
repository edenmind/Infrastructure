# Infrastrusture

This is the infrastructure for the project. It is a collection of Terraform modules that can be used to deploy the OpenArabic platform to DigitalOcean.

Some commands to get you started:

## Digital Ocean

### Login

`doctl auth init -t <token>`

### List Kubernetes versions

`doctl kubernetes options versions`

### List droplet machine types

`doctl compute size list`

## Terraform

### Update providers

`terraform init -upgrade`
