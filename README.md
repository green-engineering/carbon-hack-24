# carbon-hack-24


## Local Setup


```sh
npm install -g "@grnsft/if"
npm install -g "@grnsft/if-plugins"
npm install -g "@grnsft/if-unofficial-plugins"
npm install -g "husky"
npm install -g https://github.com/nb-green-ops/if-k8s-metrics-importer
npm install -g https://github.com/nb-green-ops/if-prometheus-exporter


```

## Run it

replace the values in the `./server/ie/cluster.yml` file with your defaults and tokens etc. 

```sh

# only do this if you are testing locally. Please import the right CA's to use for production
export NODE_TLS_REJECT_UNAUTHORIZED=0

node server.js

```