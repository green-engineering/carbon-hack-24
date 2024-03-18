

```sh
sa_name="metrics-reader"
kubectl create serviceaccount ${sa_name}
kubectl create clusterrolebinding ${sa_name} \
      --clusterrole=cluster-admin \
      --serviceaccount=default:${sa_name}
kubectl create token ${sa_name}
```