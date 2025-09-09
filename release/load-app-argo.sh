# Create/overwrite the AppProject + Application together
cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd 
spec:
  description: Default project allowing this repo and destination
  sourceRepos:
    - 'https://github.com/elad-ts/kcd-texas-microservices-demo.git'
  destinations:
    - server: 'https://kubernetes.default.svc'
      namespace: 'microservices-demo'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo
  namespace: argocd 
spec:
  project: default
  source:
    repoURL: https://github.com/elad-ts/kcd-texas-microservices-demo.git
    targetRevision: main
    path: release
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices-demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Force the controller/UI to pick it up immediately
kubectl -n argocd annotate application microservices-demo \
  argocd.argoproj.io/refresh=hard --overwrite

# Quick checks
kubectl -n get appproject default
kubectl -n akuity get application microservices-demo -o wide
