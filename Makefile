# tools variables
KIND_VERSION       = v0.11.1
KUBECTL_VERSION	   = v1.22.0
K9S_VERSION        = v0.24.15
TERRAFORM_VERSION  = 1.0.1

# cluster variables
CLUSTER_NAME	   = kind-local
CLUSTER_CONFIG	   = config.yaml
CLUSTER_VERSION	   = v1.22.0

help: ## Help 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deps: ## Install dependencies
	@./helper.sh deps kind ${KIND_VERSION}
	@./helper.sh deps kubectl ${KUBECTL_VERSION}
	@./helper.sh deps k9s ${K9S_VERSION}
	@./helper.sh deps terraform ${TERRAFORM_VERSION}
	@echo "deps updated."

bootstrap: ## Bootstraps cluster
	@echo "Bootstraping cluster..."
	@./helper.sh bootstrap ${CLUSTER_NAME} ${CLUSTER_VERSION} ${CLUSTER_CONFIG}

apply: ## Applies terraform
	@terraform apply -auto-approve

destroy: ## Destroys cluster
	@echo "Destroying cluster..."
	@./helper.sh destroy ${CLUSTER_NAME}

start: ## Starts cluster
	@echo "Starting cluster..."
	@./helper.sh start ${CLUSTER_NAME}

stop: ## Stops cluster
	@echo "Stopping cluster..."
	@./helper.sh stop

status: ## Displays status of the cluster
	@./helper.sh status
