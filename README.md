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

### Container Registry

After creating the cluster, it needs to be connected to the container registry. This is can be done from the web interface.

## Terraform

### Update providers

`terraform init -upgrade`

### Destroy

Make sure to not just delete the resources, because the there will be a mismatch with the state.

`terraform destroy`
