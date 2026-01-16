# Image Pull Error Explanation

## Error Messages

### Vulnerable App
```
Back-off pulling image "image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/vulnerable-app:latest": 
ErrImagePull: unable to pull image or OCI artifact: pull image err: initializing source docker://image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/vulnerable-app:latest: 
reading manifest latest in image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/vulnerable-app: manifest unknown
```

### Remediated App
```
Failed to pull image "image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest": 
unable to pull image or OCI artifact: pull image err: initializing source docker://image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app:latest: 
reading manifest latest in image-registry.openshift-image-registry.svc:5000/demo1-compromised-dependency/remediated-app: name unknown
```

## Root Cause

**This is EXPECTED behavior** - The deployment is trying to use an image that doesn't exist yet in the registry.

- **vulnerable-app:latest** must be built first by the Tekton pipeline before the deployment can successfully start pods.
- **remediated-app:latest** must be built first using the BuildConfig (binary build) before the deployment can successfully start pods.

## What's Happening

1. ✅ **Deployment is created successfully** - The deployment object exists in the cluster
2. ❌ **Pods cannot start** - Pods fail with `ImagePullBackOff` because the image doesn't exist
3. ⏳ **Image needs to be built** - The Tekton pipeline must build the image first

## Solution

### For Vulnerable App: Build Using Tekton Pipeline

**Step 1: Create PVC for pipeline workspace:**
```bash
# Create the PVC for the pipeline workspace
oc apply -f all-demo-files/demo1-compromised-dependency/configs/pipeline-workspace-pvc.yaml -n demo1-compromised-dependency
```

**Step 2: Start the pipeline to build the image:**
```bash
# Start the pipeline with the workspace PVC
tkn pipeline start vulnerable-app-complete-pipeline \
  -n demo1-compromised-dependency \
  -p git-url=https://github.com/nedoshi/demo1-vulnerable-app.git \
  -p git-revision=main \
  -w name=source,claimName=source-pvc \
  --showlog
```

### For Remediated App: Build Using BuildConfig

**Step 1: Create remediated app source ConfigMap:**
```bash
# Create ConfigMap with remediated source code
oc apply -f all-demo-files/demo1-compromised-dependency/app-source/remediated-app.yaml -n demo1-compromised-dependency
```

**Step 2: Create ImageStream and BuildConfig:**
```bash
# Create ImageStream and BuildConfig
oc apply -f all-demo-files/demo1-compromised-dependency/configs/remediated-buildconfig.yaml -n demo1-compromised-dependency
```

**Step 3: Build the image using binary build:**
```bash
# Extract source files from ConfigMap to temporary directory
TEMP_DIR=$(mktemp -d)
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.package\.json}' > "$TEMP_DIR/package.json"
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.app\.js}' > "$TEMP_DIR/app.js"
oc get configmap remediated-app-source -n demo1-compromised-dependency -o jsonpath='{.data.Dockerfile}' > "$TEMP_DIR/Dockerfile"

# Start binary build
ORIG_DIR=$(pwd)
cd "$TEMP_DIR"
oc start-build remediated-app-build -n demo1-compromised-dependency --from-dir=. --wait
cd "$ORIG_DIR"
rm -rf "$TEMP_DIR"
```

**Alternative: Use PipelineRun YAML (automatically creates PVC):**
```bash
# Create a PipelineRun that automatically creates the PVC
cat <<EOF | oc apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: vulnerable-app-build-
  namespace: demo1-compromised-dependency
spec:
  pipelineRef:
    name: vulnerable-app-complete-pipeline
  params:
    - name: git-url
      value: https://github.com/nedoshi/demo1-vulnerable-app.git
    - name: git-revision
      value: main
  workspaces:
    - name: source
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 5Gi
EOF

# Wait for the pipeline to complete
tkn pipelinerun logs -n demo1-compromised-dependency --last -f
```

### Option 2: Use a Temporary Image

For testing purposes, you can temporarily use a different image:

```bash
oc set image deployment/vulnerable-app app=quay.io/redhat-appstudio/nodejs:latest -n demo1-compromised-dependency
```

### Option 3: Wait for Image to be Built

If the pipeline is already running, wait for it to complete. The pods will automatically retry pulling the image once it's available.

## Verification

### Check if Image Exists

**For vulnerable-app:**
```bash
# Check ImageStream
oc get imagestream vulnerable-app -n demo1-compromised-dependency

# Check if image tag exists
oc get imagestreamtag vulnerable-app:latest -n demo1-compromised-dependency
```

**For remediated-app:**
```bash
# Check ImageStream
oc get imagestream remediated-app -n demo1-compromised-dependency

# Check if image tag exists
oc get imagestreamtag remediated-app:latest -n demo1-compromised-dependency

# Check build status
oc get builds -n demo1-compromised-dependency -l buildconfig=remediated-app-build
```

### Check Pod Status

**For vulnerable-app:**
```bash
# Check pod status (will show ImagePullBackOff until image exists)
oc get pods -n demo1-compromised-dependency -l app=vulnerable-app

# Check pod events
oc describe pod -n demo1-compromised-dependency -l app=vulnerable-app | grep -A 10 "Events:"
```

**For remediated-app:**
```bash
# Check pod status (will show ImagePullBackOff until image exists)
oc get pods -n demo1-compromised-dependency -l app=remediated-app

# Check pod events
oc describe pod -n demo1-compromised-dependency -l app=remediated-app | grep -A 10 "Events:"
```

### Check Pipeline Status

```bash
# Check if pipeline is running/completed
oc get pipelineruns -n demo1-compromised-dependency

# Check pipeline logs
tkn pipeline logs vulnerable-app-complete-pipeline -n demo1-compromised-dependency --last
```

## Expected Workflow

### For Vulnerable App:
1. **Create ImageStream and BuildConfig** (already done)
2. **Run Tekton Pipeline** to build the image
3. **Deploy the application** - Deployment is created
4. **Pods start successfully** - Once image is available

### For Remediated App:
1. **Create ConfigMap** with remediated source code
2. **Create ImageStream and BuildConfig** for remediated app
3. **Build the image** using `oc start-build` (binary build)
4. **Deploy the application** - Deployment is created
5. **Pods start successfully** - Once image is available

## Notes

- The deployment object is created successfully even if the image doesn't exist
- Pods will show `ImagePullBackOff` or `ErrImagePull` until the image is built
- Once the image is built, pods will automatically retry and start successfully
- This is normal Kubernetes behavior - deployments can exist without running pods

## Fixes Applied

1. ✅ Added `imagePullPolicy: IfNotPresent` to deployment (more tolerant)
2. ✅ Added resource limits to prevent resource constraint issues
3. ✅ Updated documentation to explain this is expected behavior
