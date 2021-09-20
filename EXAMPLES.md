# Cilium

kubectl create ns cilium-test
kubectl apply -n cilium-test -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/kubernetes/connectivity-check/connectivity-check.yaml
kubectl get pods -n cilium-test
kubectl port-forward -n $CILIUM_NAMESPACE svc/hubble-ui --address 0.0.0.0 --address :: 12000:80


export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz"
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz.sha256sum"
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar zxf hubble-linux-amd64.tar.gz

sudo mv hubble /usr/local/bin

kubectl port-forward -n $CILIUM_NAMESPACE svc/hubble-relay --address 0.0.0.0 --address :: 4245:80

hubble --server localhost:4245 status

hubble --server localhost:4245 observe

## Demo

Source: https://docs.cilium.io/en/v1.9/gettingstarted/http/#gs-http

kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/minikube/http-sw-app.yaml
kubectl get pods,svc
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "rule1"
spec:
  description: "L3-L4 policy to restrict deathstar access to empire ships only"
  endpointSelector:
    matchLabels:
      org: empire
      class: deathstar
  ingress:
  - fromEndpoints:
    - matchLabels:
        org: empire
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP

kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.9/examples/minikube/sw_l3_l4_policy.yaml
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

kubectl -n kube-system exec cilium-1c2cz -- cilium endpoint list

# Linkerd

https://linkerd.io/2.10/getting-started/

# Chaos mesh

https://chaos-mesh.org/docs/define-chaos-experiment-scope/
