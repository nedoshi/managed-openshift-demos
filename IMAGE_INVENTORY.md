# Image Inventory and Pull Error Analysis

This document lists all container images used across all demos and identifies which ones may cause `ImagePullBackOff` errors.

## Image Categories

### 1. Internal Registry Images (Must Be Built)

These images are built within the OpenShift cluster and stored in the internal registry. They **will fail** with `ImagePullBackOff` until built.

#### Demo 1: Compromised Dependency

| Image | Resource | Status | Build Method |
|-------|----------|--------|--------------|
| `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/vulnerable-app:latest` | `vulnerable-deployment.yaml` | ❌ Must be built | Tekton Pipeline |
| `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest` | `remediated-deployment.yaml` | ❌ Must be built | BuildConfig (binary build) |

**Build Steps:**
- **vulnerable-app**: Run Tekton pipeline `vulnerable-app-complete-pipeline`
- **remediated-app**: Use BuildConfig `remediated-app-build` with binary build

---

### 2. External Registry Images (May Require Authentication)

These images are pulled from external registries. Some may require authentication or may not exist.

#### Demo 1: Compromised Dependency

| Image | Resource | Registry | Authentication Required | Likely Status |
|-------|----------|----------|-------------------------|---------------|
| `registry.access.redhat.com/ubi8/python-39:latest` | `admission-webhook/webhook-service.yaml` | Red Hat Registry | ✅ Yes (Red Hat account) | ⚠️ May fail without auth |
| `registry.access.redhat.com/ubi8/ubi-minimal:latest` | `vulnerability-scanner-task.yaml` | Red Hat Registry | ✅ Yes | ⚠️ May fail without auth |
| `registry.access.redhat.com/ubi8/ubi-minimal:latest` | `vex-generator-task.yaml` | Red Hat Registry | ✅ Yes | ⚠️ May fail without auth |
| `registry.access.redhat.com/ubi8/ubi-minimal:latest` | `sbom-scan-task.yaml` | Red Hat Registry | ✅ Yes | ⚠️ May fail without auth |
| `quay.io/redhat-appstudio/rhtas-cli:latest` | `signing-task.yaml` | Quay.io | ⚠️ May require auth | ⚠️ May not exist |
| `quay.io/openshift/origin-cli:latest` | `deploy-task.yaml` | Quay.io | ⚠️ May require auth | ⚠️ May not exist |

#### Demo 2: GenAI Model Poisoning

| Image | Resource | Registry | Authentication Required | Likely Status |
|-------|----------|----------|-------------------------|---------------|
| `quay.io/redhat-appstudio/model-verifier:latest` | `model-verification.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/security-assistant:latest` | `security-assistant/security-assistant.yaml` (Deployment) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/demo/llm-model:latest` | `inference-service.yaml` | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |

#### Demo 3: Multi-Cloud Compliance Audit

| Image | Resource | Registry | Authentication Required | Likely Status |
|-------|----------|----------|-------------------------|---------------|
| `quay.io/redhat-appstudio/compliance-dashboard:latest` | `dashboard/dashboard.yaml` (Deployment) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/artifact-verifier:latest` | `artifact-verification.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/sbom-generator:latest` | `sbom-lineage.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/vex-verifier:latest` | `vex-verification.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/compliance-verifier:latest` | `nist-ssdf-compliance.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/report-generator:latest` | `report-generation.yaml` (Job) | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/compliance-report-generator:latest` | `report-generator/report-generator.yaml` | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/aws-connector:latest` | `multi-cloud/aws-connector.yaml` | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |
| `quay.io/redhat-appstudio/azure-connector:latest` | `multi-cloud/azure-connector.yaml` | Quay.io | ⚠️ May require auth | ❌ **Likely doesn't exist** |

---

## Failed Commands Analysis

Based on the failed commands list, here are the images causing issues:

### ❌ Confirmed Image Pull Failures

1. **Wait for remediated app deployment**
   - Image: `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest`
   - **Solution**: Build using BuildConfig before deployment

2. **Wait for model verification job to complete**
   - Image: `quay.io/redhat-appstudio/model-verifier:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

3. **Wait for security assistant to be ready**
   - Image: `quay.io/redhat-appstudio/security-assistant:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

4. **Deploy compliance dashboard** / **Wait for dashboard to be ready**
   - Image: `quay.io/redhat-appstudio/compliance-dashboard:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

5. **Wait for artifact verification job to complete**
   - Image: `quay.io/redhat-appstudio/artifact-verifier:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

6. **Wait for SBOM lineage job to complete**
   - Image: `quay.io/redhat-appstudio/sbom-generator:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

7. **Wait for VEX verification job to complete**
   - Image: `quay.io/redhat-appstudio/vex-verifier:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

8. **Wait for NIST SSDF verification job to complete**
   - Image: `quay.io/redhat-appstudio/compliance-verifier:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

9. **Monitor report generation**
   - Image: `quay.io/redhat-appstudio/report-generator:latest`
   - **Solution**: Image likely doesn't exist - use a placeholder or mock image

---

## Solutions

### Solution 1: Use Placeholder/Mock Images

Replace non-existent `quay.io/redhat-appstudio/*` images with publicly available placeholder images that can run the same commands:

**Recommended Replacements:**

| Original Image | Replacement | Notes |
|----------------|-------------|-------|
| `quay.io/redhat-appstudio/model-verifier:latest` | `registry.access.redhat.com/ubi8/ubi-minimal:latest` | UBI minimal for shell scripts |
| `quay.io/redhat-appstudio/security-assistant:latest` | `registry.access.redhat.com/ubi8/python-39:latest` | Python runtime for assistant |
| `quay.io/redhat-appstudio/compliance-dashboard:latest` | `registry.access.redhat.com/ubi8/python-39:latest` | Python runtime for dashboard |
| `quay.io/redhat-appstudio/artifact-verifier:latest` | `registry.access.redhat.com/ubi8/ubi-minimal:latest` | UBI minimal for shell scripts |
| `quay.io/redhat-appstudio/sbom-generator:latest` | `registry.access.redhat.com/ubi8/ubi-minimal:latest` | UBI minimal for shell scripts |
| `quay.io/redhat-appstudio/vex-verifier:latest` | `registry.access.redhat.com/ubi8/ubi-minimal:latest` | UBI minimal for shell scripts |
| `quay.io/redhat-appstudio/compliance-verifier:latest` | `registry.access.redhat.com/ubi8/ubi-minimal:latest` | UBI minimal for shell scripts |
| `quay.io/redhat-appstudio/report-generator:latest` | `registry.access.redhat.com/ubi8/python-39:latest` | Python runtime for report gen |
| `quay.io/redhat-appstudio/aws-connector:latest` | `registry.access.redhat.com/ubi8/python-39:latest` | Python runtime |
| `quay.io/redhat-appstudio/azure-connector:latest` | `registry.access.redhat.com/ubi8/python-39:latest` | Python runtime |

**Note**: Red Hat registry images require authentication. See Solution 2.

### Solution 2: Create Pull Secrets for Red Hat Registry

```bash
# Create pull secret for Red Hat registry
oc create secret docker-registry redhat-registry-secret \
  --docker-server=registry.access.redhat.com \
  --docker-username=<your-redhat-username> \
  --docker-password=<your-redhat-password> \
  --docker-email=<your-email> \
  -n <namespace>

# Link to default service account
oc secrets link default redhat-registry-secret --for=pull -n <namespace>
oc secrets link builder redhat-registry-secret --for=pull -n <namespace>
```

### Solution 3: Use Public Alternative Images

For demo purposes, use publicly available images:

| Original Image | Public Alternative |
|----------------|-------------------|
| `quay.io/redhat-appstudio/*` | `docker.io/library/busybox:latest` (for simple shell scripts) |
| `quay.io/redhat-appstudio/*` | `docker.io/library/alpine:latest` (for minimal containers) |
| `quay.io/redhat-appstudio/*` | `docker.io/library/python:3.9-slim` (for Python apps) |

### Solution 4: Build Images Locally

For internal registry images, ensure they are built:

```bash
# Build vulnerable-app
tkn pipeline start vulnerable-app-complete-pipeline \
  -n demo1-compromised-dependency \
  -p git-url=https://github.com/nedoshi/demo1-vulnerable-app.git \
  -p git-revision=main \
  -w name=source,claimName=source-pvc \
  --showlog

# Build remediated-app
oc apply -f all-demo-files/demo1-compromised-dependency/app-source/remediated-app.yaml -n demo1-compromised-dependency
oc apply -f all-demo-files/demo1-compromised-dependency/configs/remediated-buildconfig.yaml -n demo1-compromised-dependency
TEMP_DIR=$(mktemp -d)
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.package\.json}' > "$TEMP_DIR/package.json"
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.app\.js}' > "$TEMP_DIR/app.js"
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.Dockerfile}' > "$TEMP_DIR/Dockerfile"
cd "$TEMP_DIR"
oc start-build remediated-app-build -n demo1-compromised-dependency --from-dir=. --wait
cd -
rm -rf "$TEMP_DIR"
```

---

## Quick Fix Script

Create a script to replace all non-existent images with working alternatives:

```bash
#!/bin/bash
# fix-images.sh - Replace non-existent images with working alternatives

# Use UBI minimal for shell-based jobs
UBI_MINIMAL="registry.access.redhat.com/ubi8/ubi-minimal:latest"
# Use UBI Python for Python-based services
UBI_PYTHON="registry.access.redhat.com/ubi8/python-39:latest"

# Replace images in YAML files
find all-demo-files -name "*.yaml" -type f -exec sed -i.bak \
  -e "s|quay.io/redhat-appstudio/model-verifier:latest|$UBI_MINIMAL|g" \
  -e "s|quay.io/redhat-appstudio/security-assistant:latest|$UBI_PYTHON|g" \
  -e "s|quay.io/redhat-appstudio/compliance-dashboard:latest|$UBI_PYTHON|g" \
  -e "s|quay.io/redhat-appstudio/artifact-verifier:latest|$UBI_MINIMAL|g" \
  -e "s|quay.io/redhat-appstudio/sbom-generator:latest|$UBI_MINIMAL|g" \
  -e "s|quay.io/redhat-appstudio/vex-verifier:latest|$UBI_MINIMAL|g" \
  -e "s|quay.io/redhat-appstudio/compliance-verifier:latest|$UBI_MINIMAL|g" \
  -e "s|quay.io/redhat-appstudio/report-generator:latest|$UBI_PYTHON|g" \
  {} \;
```

---

## Complete Image List

All images found in the codebase:

1. `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/vulnerable-app:latest` (Internal - Must Build)
2. `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest` (Internal - Must Build)
3. `quay.io/demo/llm-model:latest` (External - May Not Exist)
4. `quay.io/openshift/origin-cli:latest` (External - May Require Auth)
5. `quay.io/redhat-appstudio/artifact-verifier:latest` (External - Likely Doesn't Exist)
6. `quay.io/redhat-appstudio/aws-connector:latest` (External - Likely Doesn't Exist)
7. `quay.io/redhat-appstudio/azure-connector:latest` (External - Likely Doesn't Exist)
8. `quay.io/redhat-appstudio/compliance-dashboard:latest` (External - Likely Doesn't Exist)
9. `quay.io/redhat-appstudio/compliance-report-generator:latest` (External - Likely Doesn't Exist)
10. `quay.io/redhat-appstudio/compliance-verifier:latest` (External - Likely Doesn't Exist)
11. `quay.io/redhat-appstudio/model-verifier:latest` (External - Likely Doesn't Exist)
12. `quay.io/redhat-appstudio/report-generator:latest` (External - Likely Doesn't Exist)
13. `quay.io/redhat-appstudio/rhtas-cli:latest` (External - May Require Auth)
14. `quay.io/redhat-appstudio/sbom-generator:latest` (External - Likely Doesn't Exist)
15. `quay.io/redhat-appstudio/security-assistant:latest` (External - Likely Doesn't Exist)
16. `quay.io/redhat-appstudio/vex-verifier:latest` (External - Likely Doesn't Exist)
17. `registry.access.redhat.com/ubi8/python-39:latest` (External - Requires Auth)
18. `registry.access.redhat.com/ubi8/ubi-minimal:latest` (External - Requires Auth)

## Summary

**Total Images**: 18 unique images
- **Internal Registry (Must Build)**: 2
- **External Registry (May Not Exist)**: 16
  - `quay.io/redhat-appstudio/*`: 11 images (likely don't exist)
  - `registry.access.redhat.com/*`: 2 images (require authentication)
  - `quay.io/openshift/*`: 1 image (may require auth)
  - `quay.io/demo/*`: 1 image (may not exist)

**Critical Issues**:
- 11 images from `quay.io/redhat-appstudio/*` likely don't exist
- 2 internal images must be built before deployment
- Red Hat registry images require authentication

**Failed Commands Mapping**:
- All 9 failed commands are directly related to missing images from `quay.io/redhat-appstudio/*`

**Recommended Action**: Replace all `quay.io/redhat-appstudio/*` images with publicly available alternatives or create the images if they're meant to be custom-built.
