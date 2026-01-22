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

- To remove dev resources:

```bash
make destroy-dev
```

- To remove prod resources:

```bash
make destroy-prod
```

Keep in mind destroying removes AWS resources and may incur data loss; review the plan logs before applying destroy.
