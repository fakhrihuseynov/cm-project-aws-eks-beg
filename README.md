# AWS EKS for Beginners - First Cluster Deployment Guide

Welcome to the AWS EKS for Beginners guide! This repository contains a minimal EKS deployment and sample app for a small project called Auronix.
It demonstrates a root-centric Terraform workflow and separate Kubernetes manifests under `kubefiles/`.

## Prerequisites

1. An active AWS account with the necessary permissions to create EKS clusters.
2. Install the AWS CLI and configure it with your credentials: ```https://aws.amazon.com/cli/```
3. A Git client (e.g., Git Bash) for working with code repositories.
4. kubectl, the Kubernetes command-line tool, installed on your local machine: ```https://kubernetes.io/docs/tasks/tools/install-kubectl/```
5. Familiarity with basic Linux commands and JSON syntax.

## Architecture Overview

![EKS Cluster Architecture](architecture_overview.png)

In this guide, we'll create a single-node EKS cluster with the following components:

1. **Amazon VPC:** A virtual private cloud to isolate our resources.
2. **Amazon EKS:** The managed Kubernetes service on AWS.
3. **Worker Nodes:** EC2 instances running the kubelet and other required daemons.
4. **kubectl:** Local command-line tool for managing our cluster and deploying applications.
5. **Application:** A simple web application, such as a Node.js or Python app, that we'll deploy on our EKS cluster.

## Security Best Practices

1. Use IAM roles to grant the necessary permissions to your cluster components.
2. Enable Kubernetes Network Policy to control traffic between pods and nodes.
3. Enable AWS Network Firewall or Amazon VPC Security Groups for additional network protection.
4. Encrypt sensitive data at rest using AWS Key Management Service (KMS).
5. Use TLS/SSL certificates for all communication between cluster components.

## Testing & Validation

These are the minimal checks to validate the infra and application after deployment. Run these from your workstation once the cluster exists.

- Get Terraform outputs (cluster details):

```bash
cd $(git rev-parse --show-toplevel)
terraform output
```

- Configure kubectl (example using AWS CLI):

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)
```

- Check nodes and system pods:

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

- Deploy/verify the sample manifests in `kubefiles/`:

```bash
kubectl apply -f kubefiles/
kubectl get pods,svc -n default
```

- Find the external IP (LoadBalancer) and test HTTP:

```bash
kubectl get svc
# then curl the EXTERNAL-IP on the service port
curl http://<EXTERNAL-IP>
```

- Use the included `service-check.sh` for a quick health check (if present):

```bash
./service-check.sh
```

## Brief explanation (current approach)

- Root-centric Terraform: infrastructure is managed from the repository root. Use `dev.tfvars` / `prod.tfvars` with `-var-file` for environment-specific values.
- Modules: `modules/` contains `vpc`, `iam`, and `eks` modules. Terraform `main.tf` composes them.
- Network: public-only VPC (no NAT) to keep the setup simple and low-cost; services are exposed via LoadBalancer for testing.
- Nodes: small worker nodes (`t3.medium`), autoscaling min=1 max=2 for dev-friendly usage.
- Kubernetes manifests are kept separate under `kubefiles/` and are applied with `kubectl` after the cluster is ready.
- Security: do not commit secrets or sensitive tfvars; `.gitignore` excludes state and tfvars.

If you want I can add a short `terraform/README.md` or a `TESTING.md` with these checks.

## Troubleshooting

1. If you encounter any errors during deployment or resource creation, check the AWS Management Console for any potential issues with your resources.
2. Ensure that your cluster is running the correct version of Kubernetes by checking its version with: `kubectl version`.
3. Make sure to use the appropriate AWS region in all commands.
4. If you have trouble accessing the application, check if the LoadBalancer's external IP has been assigned and if there are no errors in the EKS cluster's CloudWatch logs.

## Final Resource List

- AWS CLI: ```https://aws.amazon.com/cli/```
- kubectl: ```https://kubernetes.io/docs/tasks/tools/install-kubectl/```
- Sample Application Repository: ```<https://github.com/<your-username>/eks-sample-app>```
- AWS EKS Documentation: ```https://aws.amazon.com/eks/```
- Kubernetes Documentation: ```https://kubernetes.io/docs/home/```
