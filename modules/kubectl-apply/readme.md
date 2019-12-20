# Kubectl-apply terraform module

This is a simple module which takes in a template, template vars, and a kubeconfig file location

It then uses a provision step to apply the kubernetes manifest to the cluster with a `kubectl apply` command.

We use this instead of the built in kubernetes provider because raw yaml manifests are not supported and there is already missing features, such as affinity, which is not supported.

https://github.com/terraform-providers/terraform-provider-kubernetes/issues/141

https://github.com/terraform-providers/terraform-provider-kubernetes/issues/233

This gives us the following benefits:

1. Applying the raw yaml gives us more control and not having to wait for terraform to add features
2. Still being able to inject environment specific vars
3. Use outputs from other terraform modules (eg endpoints from rds)
4. Some terraform plan/drift capabilities
5. Still a one click terraform apply to deploy everything
6. Keeping manifests in version control.

Some of the downsides with this approach

1. We can't see a diff of the individual parts of the manifest that will change (eg the container image) but rather just see that the whole manifest will be applied.
2. The current implementation can't detect upstream changes. Only changes to the local manifest or vars will trigger a change.

There are some solutions to the downsides that can be used. It sounds like in the upcoming terraform 0.12 features the kuberenetes built in provider might provide a raw manifest.
We can also adapt our approach and run a `kubediff` step prior to applying as a local external data source command or when eks supports 1.13 we can use the built in `kubectl diff` command.

