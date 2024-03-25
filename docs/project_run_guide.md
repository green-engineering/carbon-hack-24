# Project Run Guide

Here we detail how to run the project.

See image architecture here [image to be included]

### Get started with a Kubernetes Cluster

To run the Code Green project solution, you will need Kubernetes and Docker Desktop installed, with admin access.

* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Kubernetes](https://kubernetes.io/)

Once these are running in the background, install the metrics server.  

```sh
kubectl apply -f <https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml>
```

Install the default Prometheus operator and Grafana stack. For more information see user guide [here](https://prometheus-operator.dev/docs/user-guides/getting-started/)

```sh
LATEST=$(curl -s https://api.github.com/repos/prometheus-operator/prometheus-operator/releases/latest | jq -cr .tag_name)

curl -sL https://github.com/prometheus-operator/prometheus-operator/releases/download/${LATEST}/bundle.yaml | kubectl create -f -
```

Next, deploy the kubernetes dashboard.

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

[not sure were to put the below]
We make use of [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus.git), a tool that allows us to use Prometheus to monitor Kubernetes and applications running on Kubernetes.

Clone this in a new and seperate directory, outside of CARBON-HACK-24.

```sh
git clone https://github.com/prometheus-operator/kube-prometheus.git
```

In the new directory, run the following commands
* Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources


* Note that due to some CRD size we are using kubectl server-side apply feature which is generally available since kubernetes 1.22.

* If you are using previous kubernetes versions this feature may not be available and you would need to use kubectl create instead.

```sh
kubectl apply --server-side -f manifests/setup
kubectl wait \ 
--for condition=Established \
--all CustomResourceDefinition \
--namespace=monitoring
kubectl apply -f manifests/
```

### Create a service account

Create a service account for the metrics reader by running the `.k8s\sa.yml` [file](https://github.com/nb-green-ops/carbon-hack-24/blob/main/.k8s/sa.yml)

```sh
kubectl apply -f sa.yml
```

Create a token for the service account, ensure its for an extended duration.

```sh
kubectl -n default create token metrics-reader-sa --duration 999999h
```

Replace the token and kubernetes (k8s) host url located in the `server\ie\cluster.yaml` [file](https://github.com/nb-green-ops/carbon-hack-24/blob/main/server/ie/cluster.yml) and replace with your own values specific to your kubernetes cluster. Note that the k8s host url will be different if your cluster is hosted on Azure or AWS.

```yml
name: k8s-metrics-importer-example
description: k8s-metrics-importer-example
tags:
initialize:
  plugins:
    if-k8s-metrics-importer:
      method: K8sMetricsImporter
      path: "https://github.com/nb-green-ops/if-k8s-metrics-importer"
      global-config:
        token: [REPLACE WITH YOUR CLUSTER TOKEN]
        k8s-host-url: [REPLACE WITH YOUR OWN HOST URL]
```

**[Optional] Modify default metrics**: For more accurate readings, you can replace the default metrics in the `server\ie\cluster.yaml` [file](https://github.com/nb-green-ops/carbon-hack-24/blob/main/server/ie/cluster.yml) by adding values applicable to your cluster.

| Metric                      | Description                                                                                               | Example          |
|-----------------------------|-----------------------------------------------------------------------------------------------------------|------------------|
| device/emissions-embodied  | Total greenhouse gases emitted during the production, transport, and disposal of the device.              | 1533.120 gCO2eq  |
| time-reserved               | Time reserved for some process or task.                                                                   | 15 seconds       |
| device/expected-lifespan   | Expected lifespan of the device.                                                                          | 94608000 seconds |
| resources-reserved          | Number of units of some resource that are reserved.                                                       | 1                |
| resources-total             | Total number of units of some resource.                                                                   | 1                |
| grid/carbon-intensity       | Amount of CO2 emissions produced per unit of electricity consumed.                                       | 800              |
| cpu/thermal-design-power    | Amount of heat a CPU is expected to emit under maximum load, measured in watts.                           | 30 watts         |

### Build the container

Execute the following `\scripts\build.sh` file to build the container.

```sh
build.sh
```

Please note you may need to push this file to a registry if you're running on an external cluster (e.g. AKS, EKS or a custom kubernetes cluster).

### Update the deployment files for your container

Create a namespace file in the common directory (`\.k8s\common\namespace.yml`), and update it with your clusters details.

```yml
kind: Namespace 
apiVersion: v1
metadata:
  name: carbon-hack-24 # update this
  labels:
    kubernetes.io/metadata.name: carbon-hack-24 # update this
```

Once the namespace has been created, run the `\.k8s\common\deployment-app.yml` file to deploy the new namespace.

* Ensure that the namespace references match the newly created `\.k8s\common\namespace.yml` .yml file

* Replace the image name with your containers details. Make sure to prepend with the associated registry.

```yml
containers:
        - name: carbon-hack-24-app
          env:
            - name: NODE_TLS_REJECT_UNAUTHORIZED
              value: "0"
          image: 'ch24/prom-exporter-server:latest' # update this
          imagePullPolicy: IfNotPresent
```

* Apply the `\.k8s\common\deployment-app.yaml` to startup the application. In the common directory, run the following

```sh
kubectl apply -f deployment-app.yml
```

### Connect to Prometheus

Once the application is up and running, you can connect to Prometheus.

Apply the `.k8s\scrape-config.yml` file which will scrape the metrics for Prometheus.

```sh
kubectl apply -f scrape-config.yml
```

If you made changes in the `\.k8s\common\deployment-app.yaml` file, check that the targets referenced in the `.k8s\scrape-config.yml` file are correct.

```yml
spec:
  staticConfigs:
    - labels:
        job: carbon-hack-24-app
      targets:
        - carbon-hack-24-app.carbon-hack-24:4040 # Check this
```

### Connect to Grafana dashboard

If you are running your project locally, you will need to expose a port-forward through kubernetes. This allows the application to expose the grafana instance to your local host.

```sh
kubectl --namespace monitoring port-forward svc/grafana 4300:3000
```

Alternatively, if your project is running externally on kubernetes, an egress will need to be deployed.

### Launch Grafana dashboard

At last, time to launch the grafana dashboard. An instance of grafana will open up in localhost `http://localhost:4300/`.

* Username: admin
* Password: admin

**[Optional] Use our template for your Grafana dashboard**: Make use of default json file for your emission dashboard. Located in the `k8s\docs\default-green-dash.json` file.
