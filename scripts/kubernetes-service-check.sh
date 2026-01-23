#!/usr/bin/env bash
kubectl get svc -n my-namespace
kubectl get ingress -n my-namespace

curl http://10.100.51.134/

kubectl port-forward svc/nginx-service 8080:80 -n my-namespace
# then in another shell / browser:
curl http://localhost:8080/
# or open http://localhost:8080 in browser

# Port-forward a specific pod (alternative):
kubectl get pods -n my-namespace
kubectl port-forward pod/<pod-name> 8080:80 -n my-namespace

# If you created an Ingress and it has an external hostname:
# (Ensure an ingress controller is installed — e.g., nginx-ingress or AWS ALB controller.)
kubectl get ingress -n my-namespace -o wide
curl http://<INGRESS_HOST>/

# Quick health/log checks
kubectl get pods -n my-namespace
kubectl describe svc nginx-service -n my-namespace
kubectl logs -n my-namespace deployment/nginx-deployment --tail=100
kubectl -n my-namespace get deploy -o wide

