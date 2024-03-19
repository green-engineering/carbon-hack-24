
# Grafana presetup

https://grafana.com/tutorials/provision-dashboards-and-data-sources/

```ini
[paths]
provisioning = <path to config files>
```

```sh
provisioning/
  datasources/
    <yaml files>
  dashboards/
    <yaml files>
  notifiers/
    <yaml files>
```


# Create the ConfigMaps and Secrets

kubectl create secret generic grafana-ini --from-file=grafana.ini -n $(namespace)
kubectl create secret generic ldap-toml --from-file=ldap.toml -n $(namespace)

kubectl create secret generic postgres-yml --from-file=provisioning/datasources/postgres.yml -n $(namespace)



## Crate Granfana DB user

 CREATE USER greenops-grafanareader WITH PASSWORD 'supersecretandcomplicatedpassworrighthere';
 GRANT USAGE ON SCHEMA schema TO greenops-grafanareader;
 GRANT SELECT ON schema.table TO greenops-grafanareader;

### create Storage account Secret
