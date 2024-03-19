FROM alpine

ARG user=appuser
ARG group=appuser
ARG uid=1042
ARG gid=1042

RUN mkdir -p /app
COPY /cmd/main  /app/
COPY /opa/policy.rego  /app/opa/
COPY /docs/swagger.yaml  /app/docs/

WORKDIR /app
RUN addgroup -S ${group} && adduser -S ${user} -G ${group}
RUN chown -R ${group}:${user} /app

USER ${user}

CMD ["./main"]