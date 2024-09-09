# OpsFleet
Creating a Terraform Module for EKS with Karpenter and Graviton Instances

# Using the EKS Karpenter Graviton Module

## Prerequisites
* An existing AWS account with the necessary permissions.
* A VPC with subnets and security groups.

## Usage
1. Clone this repository.
2. Run `terraform init` to initialize the module.
3. Run `terraform plan` to view everything is ok
3. Run `terraform apply` to deploy the EKS cluster and Karpenter.

## Deploying a Pod
To deploy a pod on an x86 or Graviton instance, use the following Kubernetes manifest:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: my-deployment
spec:
replicas: 1
selector:
 matchLabels:
   app: my-app
template:
 metadata:
   labels:
     app: my-app
 spec:
   containers:
   - name: my-app   

     image: <your-image>   

     nodeSelector:
       karpenter.sh/instance-type: c6.large # For Graviton, use c6.large
       karpenter.sh/instance-type: m5.large # For x86, use m5.large

