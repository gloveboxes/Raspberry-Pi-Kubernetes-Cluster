# Kube Set Up

## MetalLB

[Installation](https://metallb.universe.tf/installation/)

```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
```

MetalLB remains idle until configured. This is accomplished by creating and deploying a configmap into the same namespace (metallb-system) as the deployment.

```bash
kubectl apply -f metallb.yml
```

```bash
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
```

MetalLB remains idle until configured. This is accomplished by creating and deploying a configmap into the same namespace (metallb-system) as the deployment.

```bash
kubectl apply -f metallb.yml
```

### View MetalLB State

```bash
kubectl get nodes --namespace=metallb-system -o wide

kubectl get pods --namespace=metallb-system -o wide

kubectl get svc --namespace=metallb-system -o wide
```

