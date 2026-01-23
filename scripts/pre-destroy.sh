#!/usr/bin/env bash
set -euo pipefail

# Safe pre-destroy script to remove Kubernetes Services of type LoadBalancer
# Usage: ./scripts/pre-destroy.sh

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH; install/configure kubectl before running this script"
  exit 1
fi

# Ensure cluster is reachable
if ! kubectl version --short >/dev/null 2>&1; then
  echo "kubectl cannot reach the cluster. Ensure kubeconfig is valid before running this script."
  exit 1
fi

echo "Finding Services of type LoadBalancer..."
svcs=$(kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"')

if [ -z "${svcs}" ]; then
  echo "No LoadBalancer services found."
  exit 0
fi

echo "Deleting services:"
printf "%s\n" "$svcs"

while read -r ns name; do
  echo "Deleting $ns/$name"
  kubectl delete svc -n "$ns" "$name" --ignore-not-found || true
done <<< "$svcs"

# Wait for LB ingress to be removed (polling)
echo "Waiting for LoadBalancer ingress to be removed (up to 5 minutes)..."
for i in {1..30}; do
  remaining=$(kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer" and (.status.loadBalancer.ingress!=null)) | "\(.metadata.namespace) \(.metadata.name)"' | wc -l)
  if [ "${remaining}" -eq 0 ]; then
    echo "No LoadBalancer ingress entries remain."
    exit 0
  fi
  echo "Still ${remaining} LoadBalancer(s) with ingress; sleeping 10s... ($i/30)"
  sleep 10
done

echo "Timed out waiting for LoadBalancer ingress to be removed. Check AWS console or run 'aws elbv2 describe-load-balancers' to investigate."
exit 1
