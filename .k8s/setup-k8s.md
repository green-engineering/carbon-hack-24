



# install the metrics server

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

# install the prometheus operator and grafana stack

https://prometheus-operator.dev/docs/user-guides/getting-started/


```sh
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)
curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
```

# deploy dashboard

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

kubectl --namespace kubernetes-dashboard port-forward svc/kubernetes-dashboard 4443:443 



# grafana startup
kubectl --namespace monitoring port-forward svc/grafana 3000

kubectl --namespace monitoring port-forward svc/prometheus-k8s 4090:9090 
