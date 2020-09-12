# Fluxcd kustomization generation

I create the fluxcd manifests manually so that the repo doesn't depend on kustomization being ran

1. Create a file

```
mkdir -p /tmp/fluxcd/
cat > /tmp/fluxcd/kustomization.yaml <<EOF
namespace: flux
bases:
  - github.com/fluxcd/flux//deploy
patchesStrategicMerge:
  - patch.yaml
EOF
```

2. Create the patch

```
cat > /tmp/fluxcd/patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flux
  namespace: flux
spec:
  template:
    spec:
      containers:
        - name: flux
          args:
            - --manifest-generation=true
            - --memcached-hostname=memcached.flux
            - --memcached-service=
            - --ssh-keygen-dir=/var/fluxd/keygen
            - --git-branch=master
            - --git-path=namespaces,workloads
            - --git-user=\${flux_git_user}
            - --git-email=\${flux_git_user}@users.noreply.github.com
            - --git-url=\${flux_git_url}
EOF
```

3. Generate the kustomization

`kustomize build /tmp/fluxcd > cluster_configs/fluxcd.tpl.yaml`
