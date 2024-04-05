# Project Run Guide

The following guide details how to run the Code Green solution locally. 
Our application deployment architecture consists of a local Kubernetes cluster running inside of Docker 
(Any k8s cluster will do, but we chose the Docker Desktop KIND clister for ease of setup).

### Application Deployment Architecture
  
![CodeGreen_AppDeploymentArchitecture_NoHeading](https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/f66346f9-5e91-426b-90e1-d7fad1ed2be9)


### 1. Get started with a Kubernetes Cluster

To run the Code Green project solution, you will need Kubernetes and Docker Desktop installed, with admin access.

* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Kubernetes](https://kubernetes.io/)

Once these are running in the background, install the metrics server.  

```sh
kubectl apply -f <https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml>
```

Install the default Prometheus operator and Grafana stack. For more information see user guide [here](https://prometheus-operator.dev/docs/user-guides/getting-started/)

We make use of [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus.git), a tool that allows us to use Prometheus to monitor Kubernetes and applications running on Kubernetes.

Clone this in a new and separate directory, outside of CARBON-HACK-24.

```sh
git clone https://github.com/prometheus-operator/kube-prometheus.git
```

In the new Prometheus repository directory, run the following commands:

```sh
kubectl apply --server-side -f manifests/setup
kubectl wait \ 
--for condition=Established \
--all CustomResourceDefinition \
--namespace=monitoring
kubectl apply -f manifests/
```
For ease of use, we recommend the following steps.
* Create the Namespace and Custom Resource Definition (CRDs), and then wait for them to be available before creating the remaining resources.

* Note that due to some CRD size we are using `kubectl server-side apply` feature which is generally available since kubernetes 1.22.

* If you are using previous kubernetes versions this feature may not be available and you would need to use `kubectl create` instead.


### 2. Create a service account

Create a service account for the metrics reader by running `\.k8s\sa.yml`.

```sh
kubectl apply -f sa.yml
```

Create a token for the service account, ensure its for an extended duration.

```sh
kubectl -n default create token metrics-reader-sa --duration 999999h
```

Replace the token and kubernetes (k8s) host url located in `server\ie\cluster.yml` and replace with your own values specific to your kubernetes cluster. Note that the k8s host url will be different if your cluster is hosted on Azure or AWS.

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

**[Optional] Modify default metrics**: For more accurate readings, you can replace the default metrics in `server\ie\cluster.yml` by adding values applicable to your cluster.

| Metric                      | Description                                                                                               | Example          |
|-----------------------------|-----------------------------------------------------------------------------------------------------------|------------------|
| device/emissions-embodied  | Total greenhouse gases emitted during the production, transport, and disposal of the device.              | 1533.120 gCO2eq  |
| time-reserved               | Time reserved for some process or task.                                                                   | 15 seconds       |
| device/expected-lifespan   | Expected lifespan of the device.                                                                          | 94608000 seconds |
| resources-reserved          | Number of units of some resource that are reserved.                                                       | 1                |
| resources-total             | Total number of units of some resource.                                                                   | 1                |
| grid/carbon-intensity       | Amount of CO2 emissions produced per unit of electricity consumed.                                       | 800              |
| cpu/thermal-design-power    | Amount of heat a CPU is expected to emit under maximum load, measured in watts.                           | 30 watts         |

### 3. Build the container

Execute the following `\scripts\build.sh` file to build the container. Ensure to run this in the root directory of the carbon hack repo.

```sh
\scripts\build.sh
```

Please note you may need to push this file to a registry if you're running on an external cluster (e.g. AKS, EKS or a custom kubernetes cluster).

### 4. Update the deployment files for your container

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

* Ensure that the namespace references match the newly created `\.k8s\common\namespace.yml` file

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

* Apply the `\.k8s\common\deployment-app.yml` to startup the application. In the common directory, run the following

```sh
kubectl apply -f deployment-app.yml
```

### 5. Connect to Prometheus

Once the application is up and running, you can connect to Prometheus.

Apply the `\.k8s\scrape-config.yml` file which will scrape the metrics for Prometheus.

```sh
kubectl apply -f scrape-config.yml
```

If you made changes in the `\.k8s\common\deployment-app.yml` file, check that the targets referenced in the `.k8s\scrape-config.yml` file are correct.

```yml
spec:
  staticConfigs:
    - labels:
        job: carbon-hack-24-app
      targets:
        - carbon-hack-24-app.carbon-hack-24:4040 # Check this
```

### 6. Connect to Grafana dashboard

If you are running your project locally, you will need to expose a port-forward through kubernetes. This allows the application to expose the grafana instance to your local host.

```sh
kubectl --namespace monitoring port-forward svc/grafana 4300:3000
```

Alternatively, if your project is running externally on kubernetes, an egress will need to be deployed.

### 7. Launch Grafana dashboard

At last, time to launch the grafana dashboard. An instance of grafana will open up in localhost `http://localhost:4300/`.

* Username: admin
* Password: admin

Please see below a few key charts in the Software Carbon Intensity (SCI) dashboard. Using the K8s metrics from your cluster, we provide a sum of the total SCI and map according to the cluster location.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/0dd4c1f3-91c0-4bcb-b917-1b58506ee747">

Average CPU and memory utilisation for the cluster.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/9cd49eb4-deef-4795-9906-4005d9534bf8">

Average CPU and memory utilisation as per namespace, pod and container.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/83971998-d89e-4901-a903-94f571e6997e">

**[Optional] Use our template for your Grafana dashboard**: Make use of default json file for your emission dashboard. Located in the `k8s\docs\default-green-dash.json` file.

### 8. Set up alerts
We believe, a big step towards making tracked emissions usable, is an alert system. 

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/9a71bf10-cea7-46d8-9c0c-40bb453cf331">
