# Kubectl Config

Useful for switching between multiple clusters.

## Config

This sample config file needs to be updated with:

1. certificate-authority-data:
2. server: IP Address
3. Users: client-certificate-data, and client-key-data

Notes:

1. The sample config file includes config information specific machine. This data will not work with your cluster
2. This information is available when you copy the Kubernetes Config to your local dev machine with:

    ```bash
    scp -r pi@k8smaster.local:~/.kube ./kube
    ```

## Switching Clusters

```bash
kubectl config use-context pi3 or pi4
```

or edit the config file and set the **current-context** property.

## Kubernetes Reference

[Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)