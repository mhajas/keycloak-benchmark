# Grafana K6 POC for Keycloak load running

This directory provides a POC implementation for basic load running using K6.

## Limitations

- Only authz-code flow with single user and client

## Running locally

The authorization code test has hardcoded scenario following the settings we use for Gatling: 150 users per second (constant-arrival-rate) for 5 minutes.
To run this execute:
```
k6 run -e KEYCLOAK_URL=<KEYCLOAK_URL_HERE> scenarios/authorization-code.js
```

To quickly test whether it works you can replace the scenario with the following command running for 5s and constant 10 virtual users
```
k6 run --vus 10 --duration 5s -e KEYCLOAK_URL=<KEYCLOAK_URL_HERE> scenarios/authorization-code.js
```


## Running with result exported to Prometheus

### Prometheus monitoring stack

It is not possible to use Prometheus that is part of Openshift because it does not have remote write enabled.
We need to spawn a new Prometheus instance.
Navigate to `provision/openshift` and execute the following command:
```
KC_HOSTNAME_SUFFIX=apps.rosa.gh-keycloak-a.93zu.p3.openshiftapps.com task monitoring-for-k6
```

A new Grafana instance is available at the URL printed at the end of the command above with admin password loaded from aws secret manager.


### Run tests

Open file `authz-code-distributed-run-prometheus.yaml` and replace `KEYCLOAK_URL` with the actual Keycloak URL.
The test expect `realm-0` to be available with `client-0` `client-0-secret` and `user-0` with `user-0-password` in Keycloak.

To run the performance test execute the following:
```
./distributed-run.sh
```

NOTE: The script can be done repeatedly after making changes in `authorization-code.js` or `authz-code-distributed-run-prometheus.yaml`

The script does following:
1. Installs K6 operator
2. Create/Update config map with the content of `authorization-code.js` file
3. Create CR for K6 operator that executes the test

To see the results:
1. You should see 5 new pods created in `keycloak-k6-test` namespace. At the end of the test there should be some statistics printed.
2. Open Grafana created previously and open K6 Grafana dashboard - dashboards need to be imported it is not created in Grafana yet. Click Download JSON and import to Grafana using New button.
   - With native histograms (default in the yaml file) https://grafana.com/grafana/dashboards/18030-k6-prometheus-native-histograms/
   - Without native histograms https://grafana.com/grafana/dashboards/19665-k6-prometheus/

##

1. Configure Grafana cloud token as described here: https://grafana.com/docs/k6/latest/set-up/set-up-distributed-k6/usage/k6-operator-to-gck6/
2. Configure `KEYCLOAK_URL` in `authz-code-distributed-run-cloud.yaml`
3. Configure the following in options within `authorization-code.js`
```
cloud: {
    name: "Keycloak first test",
    projectID: <project_id>,
},
 ```
4. Replace used `yaml` CR file name in `distributed-run.sh` and run it.
5. Navigate to your cloud url `https://<username>.grafana.net/a/k6-app/projects` and see results





