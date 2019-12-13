# EKS-Cluster

Core functionality is a wrapper around <https://github.com/terraform-aws-modules/terraform-aws-eks> to make it easier to use.

In addition we preform some provisioning steps on the cluster itself, such as adding calico CNI Driver and set it up to work with the VPC CNI Driver, installing the dashboard, installing the alb and dns controller, and updating the EBS Storage Driver.

Some variables and options that are available on the `terraform-aws-eks` module are purposely not exposed here so its simpler and more in-line with how our components can use it.

If in the future additional features are need we can map variables from this module to the wrapped open source one.

## Dashboard

After running you can access the dashboard with
`kubectl --kubeconfig <env>.kubeconfig --namespace kube-system port-forward svc/kubernetes-dashboard  8443:443`

## VPC AWS CNI

Note because we use `calico` if a service needs to be accessible by the control plane (such as dashboard, ability to use `kubectl proxy`, or admission controllers) make sure the service is setup to use the `aws` cni

For example the dashboard will have:

```yaml
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  template:
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      annotations:
        cni: "aws"
```
