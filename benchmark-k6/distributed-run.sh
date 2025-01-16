#!/usr/bin/env bash

NAMESPACE=keycloak-k6-test

# Install K6 operator
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install k6-operator grafana/k6-operator

# Create Scenario as ConfigMap - update if exists
kubectl create namespace "$NAMESPACE" || true
kubectl -n "$NAMESPACE" create configmap authorization-code --from-file scenarios/authorization-code.js -o yaml --dry-run=client | kubectl -n "$NAMESPACE" apply -f -

# Delete old test run if exists
kubectl delete -n "$NAMESPACE" -f authz-code-distributed-run-prometheus.yaml || true

# Schedule new test run
kubectl apply -n "$NAMESPACE" -f authz-code-distributed-run-prometheus.yaml
