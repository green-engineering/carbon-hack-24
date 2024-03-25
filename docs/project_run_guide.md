# Project Run Guide


startup K8s cluster

Install metrics server  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)

Install Prometheus operator and Grafana stack

* Clone: (Note in a separate directory outside CARBON-HACK-24)
https://github.com/prometheus-operator/kube-prometheus.git
 
* Run command in directory
  * Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
  * Note that due to some CRD size we are using kubectl server-side apply feature which is generally available since kubernetes 1.22.
  * If you are using previous kubernetes versions this feature may not be available and you would need to use kubectl create instead.

kubectl apply --server-side -f manifests/setup
kubectl wait \
--for condition=Established \
--all CustomResourceDefinition \
--namespace=monitoring
kubectl apply -f manifests/
 
* Create service accounts (Metrics reader SA) -k8s\sa.yml
kubectl apply -f sa.yml

* Create token for service account sa.yml) for extended duration-
kubectl -n default create token metrics-reader-sa --duration 999999h

* Replace token in ie\cluster.yaml token and replace k8s host url & replace default values applicable to your cluster
Execute build.sh run from directory \scripts\build.sh

NOTE ONLY: might need to push to registry if running from a AKS cluster

* create namespace - .k8s\common\deployment-app.yaml (Note: replace image name)
* apply the deployment-app.yaml to startup the app. - in common directory:
common\kubectl apply -f deployment-app.yml
* .k8s\scrape-config.yml apply scrape for Prometheus -
.k8s\kubectl apply -f scrape-config.yml
* setup-k8s.md (grafana startup) - export grafana service port. -
kubectl --namespace monitoring port-forward svc/grafana 4300:3000
 
* Validate carbon data output
ie --manifest ie/cluster.yml

* launch Grafana localhost http://localhost:4300/ (uname: admin, passw: admin)

OPTIONAL: Make use of default json file for sample Carbon emission dashboard (.k8s\docs\default-green-dash.json) 

