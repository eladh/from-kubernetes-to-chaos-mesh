#!/bin/bash

. demo-magic.sh

./setup-eks-access.sh

kubectl delete -f ../chaos-mesh/productcatalogservice_chaos.yaml
kubectl delete -f ../chaos-mesh/frontend_chaos.yaml

clear

pe "kubectl get nodes"

pe "kubectl get pods -n microservices-demo"

pe "kubectl get svc -n microservices-demo"

pe "kubectl get ingress -n microservices-demo"

STORE_URL=$(kubectl get ingress frontend-ingress -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
CHAOS_MESH_URL=$(kubectl get ingress chaos-dashboard-ingress -n chaos-mesh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

pe "open http://${STORE_URL}"

pe "kubectl get pods -n pl"

pe " # The vizier-pem* are data collectors, deployed to each node via a daemonset, responsible for the eBPF-based monitoring and telemetry collection "

# invite link - https://getcosmic.ai/invite?invite_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTc5NzQxODksInN1YiI6ImU0NWI2NmM2LWVhZmQtNGEwYi1iZTQ4LWFjYWFiMGJjODgzOCJ9.MQ46zU24DwgRn4XLNv_HpKL-95G-unWL4H5BeMhcAgg
pe "open https://work.getcosmic.ai/live/clusters"

pe "kubectl get pods -n chaos-mesh"

pe " # The chaos-daemon* runs as a DaemonSet with Privileged permissions to interfere with network, filesystem, and kernel in target Pod Namespaces."

pe "kubectl create token chaos-dashboard-user --duration=1h"

pe "open http://${CHAOS_MESH_URL}"

#baeline
pe "ab -d -n 50 -c 10 http://${STORE_URL}/"

# first chaos experiment
pe "cat ../chaos-mesh/productcatalogservice_chaos.yaml"

pe "kubectl apply -f ../chaos-mesh/productcatalogservice_chaos.yaml"

pe "ab -d -n 50 -c 10 http://${STORE_URL}/"
# remove chaos experiment
pe "kubectl delete -f ../chaos-mesh/productcatalogservice_chaos.yaml"

pe "cat ../chaos-mesh/frontend_chaos.yaml"
#adding chaos experiment
pe "kubectl apply -f ../chaos-mesh/frontend_chaos.yaml"

pe "ab -d -n 50 -c 10 http://${STORE_URL}/"

pe "open http://${STORE_URL} && clear"

pe "# ⚠️ Very strange behavior detected! ⚠️ , Why 250ms delay = almost 3.5s+ latency? 🔍"

# So how pixie help , its not what its showing in the ui , it's the easy way its helpping you to get without is the tool that will help us understand the latency issue
"./pixie-latency-analysis.sh"
