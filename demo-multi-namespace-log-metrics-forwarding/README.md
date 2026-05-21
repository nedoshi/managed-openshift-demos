# Multi-Namespace Log and Metrics Forwarding Demo

This demo showcases a **Multi-Tenant Observability** model on Red Hat OpenShift Service on AWS (ROSA). It demonstrates how individual development teams can self-serve their observability needs by forwarding logs and metrics to a third-party backend (New Relic) without requiring constant Cluster Admin intervention.

## Architecture Overview

The demo consists of two isolated namespaces (`user-a-namespace` and `user-b-namespace`), each representing a different development team with different technical preferences:

| Feature | User A (Prometheus Native) | User B (OTel First) |
| :--- | :--- | :--- |
| **Log Forwarding** | `ClusterLogForwarder` (Local) | `ClusterLogForwarder` (Local) |
| **Metrics Engine** | **Cluster Observability Operator (COO)** | **Red Hat Build of OpenTelemetry** |
| **Logic** | "I want my own Prometheus instance." | "I want a vendor-neutral router." |
| **Backend** | New Relic | New Relic |


## Prerequisites

### 1. Install Operators (Admin)
Ensure the following operators are installed from the OperatorHub:
* **Red Hat OpenShift Logging** (Version 5.8+)
* **Cluster Observability Operator**
* **Red Hat Build of OpenTelemetry**


## Setup Instructions

### 1. Create Namespaces and Permissions

```bash
# Create namespaces
oc new-project user-a-namespace
oc new-project user-b-namespace

# Create ServiceAccounts for logging
oc create sa log-collector -n user-a-namespace
oc create sa log-collector -n user-b-namespace

# Grant 'writer' permissions to the collector
oc adm policy add-cluster-role-to-user logging-collector-logs-writer -z log-collector -n user-a-namespace
oc adm policy add-cluster-role-to-user logging-collector-logs-writer -z log-collector -n user-b-namespace

```

### 2. Configure Credentials

Create the New Relic secret in **both** namespaces:

```bash
oc create secret generic nr-secret \\
  --from-literal=license-key="YOUR_NEW_RELIC_INGEST_KEY" \\
  -n user-a-namespace

oc create secret generic nr-secret \\
  --from-literal=license-key="YOUR_NEW_RELIC_INGEST_KEY" \\
  -n user-b-namespace

```

### 3. Deploy User A (COO Path)

User A uses a dedicated Prometheus stack managed by the Cluster Observability Operator.

* Apply `user-a/clf.yaml`
* Apply `user/coo.yaml`

### 4. Deploy User B (OTel Path)

User B uses an OpenTelemetry Collector to scrape and route metrics.

* Apply `user-b/clf.yaml`
* Apply `user-b/otel.yaml`

## Verification

### Log Forwarding

Check the status of the namespaced `ClusterLogForwarder`:

```bash
oc get clf user-a-logs -n user-a-namespace -o yaml

```

Look for `status.conditions` where `type: Ready` is `True`.

### Metrics Forwarding

* **User A:** Verify a Prometheus pod is running in `user-a-namespace`.
* **User B:** Verify an OTel Collector pod is running in `user-b-namespace`.

Check New Relic's **Log Management** and **Metrics Explorer** to see data faceted by `kubernetes.namespace_name`.
