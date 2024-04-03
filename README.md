# Carbon Hack 24: Code Green

The following guide details how to run the Code Green solution. 

We present a Kubernetes Impact Engine Metrics application that we believe will expand the uses of the Impact Framework to real-time metric access. Our application deployment architecture consists of Kubernetes(K8s), Prometheus and Grafana applications which communicate through our custom K8s Impact Engine Metrics Application.

![CodeGreen_AppDeploymentArchitecture_NoHeading](https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/f66346f9-5e91-426b-90e1-d7fad1ed2be9)

### Set up local environment

For a local deployment and evaluation the following is assumed about the environment:

- It is based on Unix ( This is for the build script, running `docker build .` on Windows should work as well. See step 3)
- It has docker installed, and contains a local k8s cluster.
- the kubectl comaandline utility is installed.

It is also possible to deploy to a hosted k8s service, but that requires also having access to a container registry.


### 1. Get started with a Kubernetes Cluster

To run the Code Green project solution, you will need Kubernetes and Docker Desktop installed, with admin access.

* [Docker Desktop](https://www.docker.com/products/docker-desktop/)
* [Kubernetes](https://kubernetes.io/)

Once these are running in the background, install the metrics server.  

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Install the default Prometheus operator and Grafana stack. For more information see user guide [here](https://prometheus-operator.dev/docs/user-guides/getting-started/)

We make use of [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus.git), a tool that allows us to use Prometheus to monitor Kubernetes and applications running on Kubernetes.

Clone this in a new and seperate directory, outside of CARBON-HACK-24.

```sh
git clone https://github.com/prometheus-operator/kube-prometheus.git
```

In the new `kube-prometheus` repositorie's root directory, run the following commands:

```sh
kubectl apply --server-side -f manifests/setup
kubectl wait \ 
--for condition=Established \
--all CustomResourceDefinition \
--namespace=monitoring
kubectl apply -f manifests/
```
This will create all the nececary CRD's and resources for the kube-prometheus stack and may take a few seccond to somplete.

### 2. Create a service account

Create a service account for the metrics reader by running `kubectl apply -f .k8s/sa.yml` from the root of the repository.

```sh
kubectl apply -f .k8s/sa.yml
```

Create a token for the service account, ensure its for an extended duration.

```sh
kubectl -n default create token metrics-reader-sa --duration 999999h
```

Replace the token and kubernetes (k8s) host url located in `server/ie/cluster.yml` and replace with your own values specific to your kubernetes cluster. Note that the k8s host url will be different if your cluster is hosted on Azure or AWS.

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

Execute the following `./scripts/build.sh` file to build the container. Ensure to run this in the root directory of the carbon hack repo.

```sh
./scripts/build.sh
```

Please note you may need to push this file to a registry if you're running on an external cluster (e.g. AKS, EKS or a custom kubernetes cluster).

### 4. Update the deployment files for your container

Create a namespace on the cluster using the provided yaml file `.k8s/common/namespace.yml`. Update it if you feel the need but be sure to also update all deployments of the app as well. 

```yml
kind: Namespace 
apiVersion: v1
metadata:
  name: carbon-hack-24 # maybe update this
  labels:
    kubernetes.io/metadata.name: carbon-hack-24 # maybe update this
```

Create the namespace:
```sh
kubectl apply -f .k8s/common/namespace.yml
```

Once the namespace has been created, apply the `.k8s/common/deployment-app.yml` file to deploy the app.

Create the namespace:
```sh
kubectl apply -f .k8s/common/deployment-app.yml
```

* Ensure that the namespace references match the namespace created with the `.k8s/common/namespace.yml` file.

* Replace the image name with your containers details if you changed the build script prior to this step.
* Make sure to prepend with the associated registry if you are deploying to a hosted k8s cluster that is pulling from a registry.

```yml
containers:
        - name: carbon-hack-24-app
          env:
            - name: NODE_TLS_REJECT_UNAUTHORIZED # This value is here to ignore certificates, in the case where you are using test clusters and certs
              value: "0"                         # It is highly reccomended to not set this in any production case and import the propper root certs to your container
          image: 'ch24/prom-exporter-server:latest' # update this
          imagePullPolicy: IfNotPresent
```

### 5. Connect to Prometheus

Once the application is up and running, we can apply a scrape config to let Prometheus know to scrape our app.

Apply the `.k8s/scrape-config.yml` file which will scrape the metrics for Prometheus.

```sh
kubectl apply -f scrape-config.yml
```

If you made changes in the `.k8s/common/deployment-app.yml` file, check that the targets referenced in the `.k8s/scrape-config.yml` file are correct.

```yml
spec:
  staticConfigs:
    - labels:
        job: carbon-hack-24-app
      targets:
        - carbon-hack-24-app.carbon-hack-24:4040 # Check this
```

### 6. Connect to Grafana dashboard

If you are running your project locally, you will need to port-forward Grafana in order to access it. This allows the kubernetes to expose the grafana instance to your local host.

```sh
kubectl --namespace monitoring port-forward svc/grafana 4300:3000
```

Alternatively, if your project is running externally on kubernetes, an ingress will need to be deployed and configured apropriately.

### 7. Launch Grafana dashboard

At last, time to launch the grafana dashboard. Remembering the port we exposed Grafana on, we can open the following url in a browser: [`http://localhost:4300/`](http://localhost:4300/).

The default admin credentials for Grafana:
* Username: admin
* Password: admin

## [Optional] Use our template for your Grafana dashboard

Make use of our default json file for your emission dashboard, located in the `k8s/docs/default-green-dash.json` file. 

Using K8s metrics from the cluster, we provide a sum of the total SCI and map according to the cluster location.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/0dd4c1f3-91c0-4bcb-b917-1b58506ee747">

Average CPU and memory utilisation for the cluster.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/9cd49eb4-deef-4795-9906-4005d9534bf8">

Average CPU and memory utilisation as per namespace, pod and container.

<img width="452" alt="image" src="https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/83971998-d89e-4901-a903-94f571e6997e">


### 8. Set up alerts

To modify the alert system, select the chart of interest. We have created a default alert for illustration, see the red box below.

![image](https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/9124535f-dce8-4aef-baf1-81b035860806)

Select the alert and modify the alert name, query and alert condition. 

![image](https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/1b8e422e-04a5-4180-9e4f-28d73a86e924)

Set threshold for alert to be triggered (currently set to trigger alert above 700).

![image](https://github.com/nb-green-ops/carbon-hack-24/assets/136962406/63ba5b09-696b-4976-9bbf-76bfde3f3d76)

Note that for now, this is all we need. Lave other alert rule values as default.

Save and run the query. 

### Project set up is now complete
