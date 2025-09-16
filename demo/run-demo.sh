#!/bin/bash

. demo-magic.sh

./setup-eks-access.sh

kubectl delete -f ../chaos-mesh/productcatalogservice_chaos.yaml
kubectl delete -f ../chaos-mesh/frontend_chaos.yaml

clear

ARGOCD_URL=$(kubectl get ingress argocd -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
pe "open http://${ARGOCD_URL}"

STORE_URL=$(kubectl get ingress frontend-ingress -n microservices-demo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
CHAOS_MESH_URL=$(kubectl get ingress chaos-dashboard-ingress -n chaos-mesh -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

clear

pe "open http://${STORE_URL}"

pe "kubectl get pods -n pl"

echo ""
echo "############################ ℹ️ ################################"
echo "#                                                             #"
echo "#  The vizier-pem* are data collectors, deployed to each node #"
echo "#  via a DaemonSet, responsible for the eBPF-based monitoring #"
echo "#  and telemetry collection                                   #"
echo "#                                                             #"
echo "###############################################################"
echo ""

pe "open https://work.getcosmic.ai/live/clusters"

clear

pe "kubectl get pods -n chaos-mesh"

echo ""
echo "########################### ℹ️ ################################"
echo "#                                                             #"
echo "#  The chaos-daemon* runs as a DaemonSet with Privileged      #"
echo "#  permissions to interfere with network, filesystem, and     #"
echo "#  kernel in target Pod Namespaces.                           #"
echo "#                                                             #"
echo "###############################################################"
echo ""

pe "kubectl create token chaos-dashboard-user --duration=1h"

pe "open http://${CHAOS_MESH_URL}"

clear

#baseline
pe "ab -d -n 50 -c 10 http://${STORE_URL}/"

# first chaos experiment
pe "cat ../chaos-mesh/productcatalogservice_chaos.yaml"

pe "kubectl apply -f ../chaos-mesh/productcatalogservice_chaos.yaml"

pe "ab -d -n 50 -c 10 http://${STORE_URL}/"

# remove chaos experiment
pe "kubectl delete -f ../chaos-mesh/productcatalogservice_chaos.yaml"

clear

pe "cat ../chaos-mesh/frontend_chaos.yaml"

#adding chaos experiment
pe "kubectl apply -f ../chaos-mesh/frontend_chaos.yaml"

pe "ab -d -n 50 -c 10 http://${STORE_URL}/"

pe "# ⚠️ Very strange behavior detected! ⚠️ , Why 250ms delay = almost 4s latency? 🔍"

# So how pixie help , its not what its showing in the ui , it's the easy way its helpping you to get without is the tool that will help us understand the latency issue
"./pixie-latency-analysis.sh"