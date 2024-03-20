FROM node:alpine as base

RUN apk update
RUN apk upgrade
RUN apk add git

ARG user=appuser
ARG group=appuser
ARG uid=1042
ARG gid=1042

RUN mkdir -p /app
COPY  server/ /app
RUN mkdir -p /app/public
# RUN touch -p /app/public/metrics.prom
WORKDIR /app
RUN npm i

RUN npm install -g "@grnsft/if"
RUN npm install -g "@grnsft/if-plugins"
RUN npm install -g "@grnsft/if-unofficial-plugins"
RUN npm install -g "husky"

RUN git clone https://github.com/nb-green-ops/if-k8s-metrics-importer 
RUN cd if-k8s-metrics-importer && npm i && npm link
RUN git clone https://github.com/nb-green-ops/if-prometheus-exporter
RUN cd if-prometheus-exporter && npm i && npm link

RUN addgroup -S ${group} && adduser -S ${user} -G ${group}
RUN chown -R ${group}:${user} /app

USER ${user}

CMD ["node", "server.js"]
