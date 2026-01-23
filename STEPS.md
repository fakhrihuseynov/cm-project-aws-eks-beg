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

# apply
make apply-dev
make apply-prod

# destroy
make destroy-dev
```

## Folder structure (important)

- `envs/dev/` and `envs/prod/`: per-environment working folders used by the `Makefile` (plan files and logs are stored here).
- `modules/`: Terraform modules (`vpc`, `iam`, `eks`).
- `terraform/*.tfvars`: root tfvar files (dev.tfvars, prod.tfvars) used as the canonical env values when running from root; the Makefile passes these into the env plan commands.
- `kubefiles/`: Kubernetes manifests for the sample application.

## Deploying the sample application (after Terraform apply)

1 Ensure kubeconfig is configured (example):

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)
```

2 Apply manifests

```bash
kubectl apply -f kubefiles/
```

3 Verify deployments and services:

```bash
kubectl get pods,svc -n default
```

## Troubleshooting

- If `kubectl` reports "Unable to connect to the server":
  - Verify `terraform output` for `cluster_name` and `cluster_endpoint`.
  - Re-run `aws eks update-kubeconfig --name <cluster> --region <region>`.
  - Confirm DNS resolution for the `cluster_endpoint`.

- If pods are stuck Pulling or CrashLoopBackOff, describe the pod:

  ```bash
    kubectl describe pod <pod-name>
    kubectl logs <pod-name> --previous
  ```

- Use the included quick-check script `kubefiles/service-check.sh` to validate the sample service is reachable. Example content and checks (quick summary):
  - `service-check.sh` performs a `kubectl get svc` and attempts an HTTP `curl` against the service external IP.
  - If external IP is pending, wait for the LoadBalancer and re-run.

## Delete / removal steps (short)

## Delete / removal steps (detailed)

These steps ensure Kubernetes-created cloud resources (LoadBalancers, ENIs, EIPs) are removed before deleting the VPC and other infra. Run these from your workstation.

1 (Optional) Configure your environment variables used by commands below:

```bash
export REGION=<your_deployed_region>
export VPC=$(terraform output -raw public_vpc_id 2>/dev/null || echo "<your-vpc-id>")
```

2 Delete Kubernetes LoadBalancer Services (imperative):

```bash
# Ensure kubeconfig is configured for the cluster
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)

# Delete any LoadBalancer services (prompt will show the list first)
kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' | tee /tmp/lb-svcs.txt
# Review /tmp/lb-svcs.txt and then delete:
while read -r ns name; do kubectl delete svc -n "$ns" "$name" --ignore-not-found; done < /tmp/lb-svcs.txt
```

3 Wait for AWS Load Balancers and ENIs to be deleted (polling):

```bash
# Poll for remaining ALBs/NLBs in the VPC
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC']" --output json
# Poll ENIs
aws ec2 describe-network-interfaces --region $REGION --filters Name=vpc-id,Values=$VPC --output json
```

If any LoadBalancers or ENIs remain, wait a few minutes and re-check until they are gone.

4 If LBs were created outside the cluster or cannot be removed with `kubectl`, delete them via AWS CLI:

```bash
# List LBs in VPC
aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC'].{Name:LoadBalancerName,ARN:LoadBalancerArn}" --output table
# Delete by ARN
aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn <lb-arn>
```

5 Release any Elastic IPs and delete NAT gateways (if present):

```bash
# List EIPs
aws ec2 describe-addresses --region $REGION --filters Name=domain,Values=vpc --output table
# Disassociate & release (replace ids)
aws ec2 disassociate-address --region $REGION --association-id <assoc-id>
aws ec2 release-address --region $REGION --allocation-id <alloc-id>

# List NAT gateways
aws ec2 describe-nat-gateways --region $REGION --filter Name=vpc-id,Values=$VPC --output json
aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id <nat-id>
```

6 Detach and delete the Internet Gateway (if present):

```bash
aws ec2 describe-internet-gateways --region $REGION --filters Name=attachment.vpc-id,Values=$VPC --output json
aws ec2 detach-internet-gateway --region $REGION --internet-gateway-id <igw-id> --vpc-id $VPC
aws ec2 delete-internet-gateway --region $REGION --internet-gateway-id <igw-id>
```

7 Delete remaining subnets and security groups (non-default):

```bash
aws ec2 describe-subnets --region $REGION --filters Name=vpc-id,Values=$VPC --query 'Subnets[*].SubnetId' --output table
aws ec2 delete-subnet --region $REGION --subnet-id <subnet-id>

aws ec2 describe-security-groups --region $REGION --filters Name=vpc-id,Values=$VPC --output table
# Delete non-default SGs at your discretion
aws ec2 delete-security-group --region $REGION --group-id <sg-id>
```

8 Attempt Terraform destroy (from the appropriate env folder or root, as your workflow dictates):

```bash
# Example using Makefile wrapper
make destroy-dev

# Or run directly from envs folder
cd envs/dev
terraform destroy -var-file=../../dev.tfvars
```

9 If Terraform errors because resources were removed manually, reconcile state:

```bash
# List terraform-managed resources
terraform state list
# Remove entries for resources you manually deleted
terraform state rm <resource-address>
```

Notes:

- Deleting LBs and ENIs can take several minutes; wait until `describe-network-interfaces` returns no entries for the VPC.
- Use `aws ec2 describe-instances` and `aws eks describe-cluster` to verify instances and cluster state.
- Keep a copy of `envs/<env>/destroy.log` for auditing and debugging if deletes fail.

Keep in mind destroying removes AWS resources and may incur data loss; review the plan logs before applying destroy.
