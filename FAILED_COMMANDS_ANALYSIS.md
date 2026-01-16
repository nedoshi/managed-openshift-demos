# Failed Commands Analysis

## Failed Commands List

Based on the execution report, the following commands failed:

1. ✗ Wait for remediated app deployment
2. ✗ Wait for model verification job to complete
3. ✗ Wait for security assistant to be ready
4. ✗ Deploy compliance dashboard
5. ✗ Wait for dashboard to be ready
6. ✗ Wait for artifact verification job to complete
7. ✗ Wait for SBOM lineage job to complete
8. ✗ Wait for VEX verification job to complete
9. ✗ Wait for NIST SSDF verification job to complete
10. ✗ Monitor report generation

## Root Cause Analysis

All failed commands are related to **Image Pull BackOff** errors. The root causes are:

### 1. Internal Registry Images (Must Be Built)

**Failed Command**: Wait for remediated app deployment

- **Image**: `image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest`
- **Issue**: Image doesn't exist - must be built using BuildConfig
- **Solution**: Build the image before deployment (see `IMAGE_INVENTORY.md`)

### 2. External Registry Images (Don't Exist)

**Failed Commands**: All other 9 commands

All these commands fail because the images from `quay.io/redhat-appstudio/*` **do not exist** in the registry:

| Failed Command | Image | Resource |
|----------------|-------|----------|
| Wait for model verification job | `quay.io/redhat-appstudio/model-verifier:latest` | `demo2-genai-poisoning/configs/model-verification.yaml` |
| Wait for security assistant | `quay.io/redhat-appstudio/security-assistant:latest` | `demo2-genai-poisoning/security-assistant/security-assistant.yaml` |
| Deploy compliance dashboard | `quay.io/redhat-appstudio/compliance-dashboard:latest` | `demo3-compliance-audit/dashboard/dashboard.yaml` |
| Wait for artifact verification | `quay.io/redhat-appstudio/artifact-verifier:latest` | `demo3-compliance-audit/configs/artifact-verification.yaml` |
| Wait for SBOM lineage | `quay.io/redhat-appstudio/sbom-generator:latest` | `demo3-compliance-audit/configs/sbom-lineage.yaml` |
| Wait for VEX verification | `quay.io/redhat-appstudio/vex-verifier:latest` | `demo3-compliance-audit/configs/vex-verification.yaml` |
| Wait for NIST SSDF verification | `quay.io/redhat-appstudio/compliance-verifier:latest` | `demo3-compliance-audit/configs/nist-ssdf-compliance.yaml` |
| Monitor report generation | `quay.io/redhat-appstudio/report-generator:latest` | `demo3-compliance-audit/configs/report-generation.yaml` |

## Solutions

### Immediate Fix: Replace Non-Existent Images

Replace all `quay.io/redhat-appstudio/*` images with working alternatives:

**For Shell-Based Jobs** (model-verifier, artifact-verifier, sbom-generator, vex-verifier, compliance-verifier):
- Use: `registry.access.redhat.com/ubi8/ubi-minimal:latest`
- **Note**: Requires Red Hat registry authentication

**For Python-Based Services** (security-assistant, compliance-dashboard, report-generator):
- Use: `registry.access.redhat.com/ubi8/python-39:latest`
- **Note**: Requires Red Hat registry authentication

**Alternative: Use Public Images** (if Red Hat auth is not available):
- Shell jobs: `docker.io/library/busybox:latest`
- Python services: `docker.io/library/python:3.9-slim`

### Long-Term Fix: Build Custom Images

If these are meant to be custom images:

1. Create Dockerfiles for each service
2. Build and push to a registry accessible to the cluster
3. Update YAML files with the new image references

### Quick Fix Script

See `IMAGE_INVENTORY.md` for a script to automatically replace all non-existent images.

## Verification Steps

After applying fixes, verify images exist:

```bash
# Check if internal images exist
oc get imagestreamtag vulnerable-app:latest -n demo1-compromised-dependency
oc get imagestreamtag remediated-app:latest -n demo1-compromised-dependency

# Check pod status (should not show ImagePullBackOff)
oc get pods -n demo1-compromised-dependency
oc get pods -n demo2-genai-poisoning
oc get pods -n demo3-compliance-audit

# Check job status
oc get jobs -n demo2-genai-poisoning
oc get jobs -n demo3-compliance-audit
```

## Expected Outcome

After fixes:
- ✅ All deployments should start successfully
- ✅ All jobs should complete successfully
- ✅ No `ImagePullBackOff` errors
- ✅ All wait commands should succeed
