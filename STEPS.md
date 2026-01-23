# Steps & Workflow

This repository includes a `Makefile` with convenience targets to operate Terraform for `dev` and `prod` environments using the `envs/` folder layout.

- `make init` — runs `terraform init` for both `envs/dev` and `envs/prod`.
- `make validate` — runs `terraform validate` for both envs (non-fatal).
- `make plan-dev` — produces `envs/dev/dev.plan` (uses `terraform/dev.tfvars`).
- `make apply-dev` — applies `envs/dev/dev.plan` and appends the apply output to `envs/dev/apply.log`.
- `make destroy-dev` — runs `terraform destroy` for dev and appends to `envs/dev/destroy.log`.
- `make plan-prod`, `make apply-prod`, `make destroy-prod` — same as above for prod.

Usage examples:

```bash
# create plans
make plan-dev
make plan-prod
 # Steps & Workflow

This repository uses a root-centric Terraform workflow with a small set of helper scripts and separate Kubernetes manifests in `kubefiles/`.

## Makefile targets

- `make init` — run `terraform init` for both `envs/dev` and `envs/prod`.
- `make validate` — run `terraform validate` for both envs.
- `make plan-dev` / `make plan-prod` — produce per-env plan files under `envs/`.
- `make apply-dev` / `make apply-prod` — apply the per-env plan and append logs to `envs/<env>/apply.log`.
- `make destroy-dev` / `make destroy-prod` — run `terraform destroy` for the selected env (see removal steps).

## Folder structure

- `envs/dev/` and `envs/prod/`: per-environment working folders (plan files, logs).
- `modules/`: Terraform modules (`vpc`, `iam`, `eks`).
- `dev.tfvars` / `prod.tfvars`: root tfvars used when running from the repository root.
- `kubefiles/`: Kubernetes manifests for the sample application (kept outside Terraform).
- `scripts/`: helper scripts (`checker.sh`, `kubernetes-service-check.sh`, `pre-destroy.sh`).

## Deploying the sample application

1. Create infra with Terraform (example):

```bash
make plan-dev
make apply-dev
```

1. Configure `kubectl` for the new cluster:

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)
```

1. Deploy application manifests and verify:

```bash
kubectl apply -f kubefiles/
kubectl get pods,svc -n default
```

## Scripts (helpers)

- `scripts/checker.sh` — account/resource scanner (AWS CLI). Use to inspect EC2, EBS, EIPs, NAT gateways, VPC endpoints, LBs, RDS, EFS, S3, ASGs, and EKS clusters.

### NOTE

#### Before using this script ensure to provide your current deployed REGION variable

  ```bash
  ./scripts/checker.sh > scanner-output.json
  ```

- `scripts/kubernetes-service-check.sh` — quick checks for `my-namespace` (svc/ingress/pods, port-forwarding examples, curl checks).

 ```bash
 ./scripts/kubernetes-service-check.sh
 ```

- `scripts/pre-destroy.sh` — deletes all Services of type `LoadBalancer` and waits for their AWS ingress entries to be removed. Requires `kubectl` and `jq` and a valid kubeconfig.

 ```bash
 ./scripts/pre-destroy.sh
 ```

## Delete / removal steps (recommended)

Follow these steps to avoid orphaned AWS resources (LBs/ENIs/EIPs) that block VPC deletion.

1. (Optional) Set helpful environment variables:

```bash
export REGION=<your_deployed_location>
export VPC=$(terraform output -raw public_vpc_id 2>/dev/null || echo "<your-vpc-id>")
```

1. Remove Kubernetes LoadBalancer services (imperative):

```bash
# Ensure kubeconfig points to the cluster
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)

# Delete LB services via helper
./scripts/pre-destroy.sh
```

1. Verify AWS resource cleanup (poll until empty):

```bash
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC']" --output json
aws ec2 describe-network-interfaces --region $REGION --filters Name=vpc-id,Values=$VPC --output json
```

1. If LBs remain and cannot be removed via Kubernetes, delete them via AWS CLI (list ARNs then delete). If you manually delete resources, note them for state reconciliation.

```bash
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC'].{Name:LoadBalancerName,ARN:LoadBalancerArn}" --output table
aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn <lb-arn>
```

1. Run Terraform destroy (Makefile wrapper or direct):

```bash
make destroy-dev
# or
cd envs/dev
terraform destroy -var-file=../../dev.tfvars
```

1. If you manually deleted resources, reconcile Terraform state:

```bash
terraform state list
terraform state rm <resource-address>
```

## Troubleshooting notes

- Deleting LBs/ENIs can take several minutes — re-check `describe-network-interfaces` until empty.
- If `kubectl` cannot connect, re-run the `aws eks update-kubeconfig` step and confirm DNS resolution of the cluster endpoint.
- Keep `envs/<env>/destroy.log` for debugging.
- Keep in mind destroying resources permanently removes AWS assets and may incur data loss. Review plan logs before applying destroy.

terraform state list
terraform state rm ```<resource-address>```

- Deleting LBs/ENIs can take several minutes — re-check `describe-network-interfaces` until empty.
- If `kubectl` cannot connect, follow the `aws eks update-kubeconfig` step and confirm DNS resolution of the cluster endpoint.
- Keep `envs/<env>/destroy.log` for debugging.

Keep in mind destroying removes AWS resources and may incur data loss; review plans before applying destroy.

aws ec2 release-address --region $REGION --allocation-id ```<alloc-id>```
