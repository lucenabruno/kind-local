#!/usr/bin/env bash
[[ "$DEBUG" ]] && set -x # Print commands and their arguments as they are executed.

deps() {
    local ARG1="$1"
    local ARG2="$2"
    # Path
    BIN=$HOME/.local/bin
    # create bin folder
    if [[ ! -f $BIN ]]
    then
        mkdir -p $BIN
    fi

    case "$ARG1" in
        kind)
            if [[ ! -f $BIN/kind ]]
            then
	            echo "installing kind..."
                curl -LO https://github.com/kubernetes-sigs/kind/releases/download/${ARG2}/kind-linux-amd64
                mv kind-linux-amd64 ${BIN}/kind
                chmod +x ${BIN}/kind
            fi
        ;;
        kubectl)
            if [[ ! -f $BIN/kubectl ]]
            then
	            echo "installing kubectl..."
                curl -LO https://dl.k8s.io/release/${ARG2}/bin/linux/amd64/kubectl
                mv kubectl ${BIN}/kubectl
                chmod +x ${BIN}/kubectl
            fi
        ;;
        k9s)
            if [[ ! -f $BIN/k9s ]]
            then
	            echo "installing k9s..."
                curl -LO https://github.com/derailed/k9s/releases/download/${ARG2}/k9s_Linux_x86_64.tar.gz
                tar xvf k9s_Linux_x86_64.tar.gz
                mv k9s ${BIN}/k9s
                chmod +x ${BIN}/k9s
                rm k9s_Linux_x86_64.tar.gz
            fi
        ;;
        terraform)
            if [[ ! -f $BIN/terraform ]]
            then
	            echo "installing terraform..."
                curl -LO https://releases.hashicorp.com/terraform/${ARG2}/terraform_${ARG2}_linux_amd64.zip
                unzip terraform_${ARG2}_linux_amd64.zip
                mv terraform ${BIN}/terraform
                rm terraform_${ARG2}_linux_amd64.zip
                chmod +x ${BIN}/terraform
            fi
        ;;
    esac
}

bootstrap_cluster() {
    local CLUSTER_NAME="$1"
    local CLUSTER_VERSION="$2"
    local CLUSTER_CONFIG="$3"

    # bootstrap cluster
	kind delete cluster --name ${CLUSTER_NAME}
	kind create cluster --name ${CLUSTER_NAME} --config ${CLUSTER_CONFIG} --image=kindest/node:${CLUSTER_VERSION}
	kind get kubeconfig --name ${CLUSTER_NAME} > ./kubeconfig
    kubectl -n kube-system delete ds kube-proxy
    kubectl -n kube-system delete cm kube-proxy

    # get apiserver node ip and add to cilium.yaml
    NODE_IP=$(kubectl get node kind-local-control-plane -o jsonpath='{.status.addresses[0].address}'; echo)
    cp helm/cilium.yaml.template helm/cilium.yaml
    sed -i "s/%CHANGE-ME%/${NODE_IP}/g" helm/cilium.yaml

    # setup local registry
    set_local_registry

    # apply config
    terraform init
    terraform apply -auto-approve
}

# set_local_registry creates a local Docker registry for K8s.
set_local_registry() {
    local RUNNING="$(docker inspect -f '{{.State.Running}}' "${CLUSTER_NAME}-registry" 2>/dev/null || true)"
    local REG_PORT=5000
    local DOCKER_NETWORK=kind

    echo "removing old registry:"
    docker rm -f "${CLUSTER_NAME}-registry"

    echo "starting local registry..."
    docker run \
        -d --restart=always -p "${REG_PORT}:5000" --name "${CLUSTER_NAME}-registry" --network ${DOCKER_NETWORK} \
        registry:2
    local IP="$(docker inspect -f '{{.NetworkSettings.Networks.kind.IPAddress}}' "${CLUSTER_NAME}-registry" 2>/dev/null || true)"
    echo "docker registry ip:" $IP

    # point kind configuration to local registry
    cp config.yaml.template config.yaml
    sed -i "s~%REG_IP%~${IP}~g" config.yaml

    for NODE in $(kind get nodes --name ${CLUSTER_NAME}); do
        kubectl annotate node "${NODE}" "kind.x-k8s.io/registry=localhost:${REG_PORT}";
    done
}

delete_cluster() {
    local CLUSTER_NAME="$1"
	kind delete cluster --name ${CLUSTER_NAME}
    rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
}

start_cluster() {
    local CLUSTER_NAME="$1"
	kind start cluster --name ${CLUSTER_NAME}
}

stop_cluster() {
    docker stop kind-local-control-plane
    docker stop kind-local-worker
}

status_cluster() {
	kubectl get all -A
}

main() {
  local ARG1="$1" # task
  local ARG2="$2"
  local ARG3="$3"
  local ARG4="$4"
  case "$ARG1" in
    deps)
        deps ${ARG2} ${ARG3}
    ;;
    bootstrap)
        bootstrap_cluster ${ARG2} ${ARG3} ${ARG4}
    ;;
    delete)
        delete_cluster ${ARG2} 
    ;;
    start)
        start_cluster ${ARG2}
    ;;
    stop)
        stop_cluster
    ;;
    status)
        status_cluster
    ;;
  esac
}

main "$@"
