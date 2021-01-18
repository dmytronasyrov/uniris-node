#!/usr/bin/env bash

export PATH=$PWD:$PATH

kubectl delete -f .

# Metrics

kubectl apply -f 1.0-uniris-metrics-namespace.yaml
kubectl apply -f 1.1-influxdb-services.yaml
kubectl apply -f 1.2-influxdb-workload.yaml
kubectl apply -f 2.1-fluentbit-config.yaml
kubectl apply -f 2.2-fluentbit-service.yaml
kubectl apply -f 2.3-fluentbit-utils.yaml
kubectl apply -f 2.4-fluentbit-workload.yaml

# Result

echo ''
eval printf '=%.0s' {1..$(tput cols)}
echo ''
echo ''
echo "IP: $(minikube ip)"
echo ''
echo 'Telemetry:'
echo "StatsD: $(minikube ip):$(kubectl -n uniris-metrics get service influxdb-svc -o jsonpath='{.spec.ports[?(@.name=="udp-statsd")].nodePort}')"
echo "Influx: $(minikube ip):$(kubectl -n uniris-metrics get service influxdb-svc -o jsonpath='{.spec.ports[?(@.name=="tcp-influx")].nodePort}')"
echo "Influx Admin: $(minikube ip):$(kubectl -n uniris-metrics get service influxdb-svc -o jsonpath='{.spec.ports[?(@.name=="http-influx-admin")].nodePort}')"
echo "Fluent Bit TCP: $(minikube ip):$(kubectl -n uniris-metrics get service fluentbit-svc -o jsonpath='{.spec.ports[?(@.name=="tcp-fb-input")].nodePort}')"
echo "Fluent Bit Server: $(minikube ip):$(kubectl -n uniris-metrics get service fluentbit-svc -o jsonpath='{.spec.ports[?(@.name=="tcp-fb-server")].nodePort}')"