IMAGE=ghcr.io/staillanibm/msr-account-api
TAG=1.0.0
K8S_NAMESPACE=ipaas
DEPLOYMENT=account-api

SQLSERVER_USERNAME=SA

login-whi:
	@echo ${WHI_CR_PASSWORD} | docker login ${WHI_CR_SERVER} -u ${WHI_CR_USERNAME} --password-stdin

login-gh:
	@echo ${GH_CR_PASSWORD} | docker login ${GH_CR_SERVER} -u ${GH_CR_USERNAME} --password-stdin 	

docker-build:
	@docker build -t ${IMAGE}:${TAG} --platform=linux/amd64 --build-arg WPM_TOKEN=${WPM_TOKEN} .

podman-build:
	@podman build -t ${IMAGE}:${TAG} --platform=linux/amd64 --build-arg WPM_TOKEN=${WPM_TOKEN}  .

docker-run:
	DEPLOYMENT=${DEPLOYMENT} IMAGE=${IMAGE} TAG=${TAG}	docker-compose -f ./resources/compose/docker-compose.yml up -d

podman-run:
	DEPLOYMENT=${DEPLOYMENT} IMAGE=${IMAGE} TAG=${TAG}	podman compose -f ./resources/compose/docker-compose.yml up -d

docker-stop:
	DEPLOYMENT=${DEPLOYMENT} IMAGE=${IMAGE} TAG=${TAG}	docker-compose -f ./resources/compose/docker-compose.yml down

podman-stop:
	DEPLOYMENT=${DEPLOYMENT} IMAGE=${IMAGE} TAG=${TAG}	podman compose -f ./resources/compose/docker-compose.yml down

docker-logs:
	docker logs ${DEPLOYMENT}

docker-logs-f:
	docker logs -f ${DEPLOYMENT}

docker-push:
	docker push ${IMAGE}:${TAG}

podman-logs:
	podman logs ${DEPLOYMENT}

podman-logs-f:
	podman logs -f ${DEPLOYMENT}

podman-push:
	podman push ${IMAGE}:${TAG}


login-ocp:
	@oc login ${OCP_API_URL} -u ${OCP_USERNAME} -p ${OCP_PASSWORD}

kube-deploy:
	kubectl apply -f ./resources/kubernetes -n ${K8S_NAMESPACE}

kube-restart-deploy:
	kubectl rollout restart deployment ${DEPLOYMENT} -n ${K8S_NAMESPACE}

kube-get-deploy:
	kubectl get deployment ${DEPLOYMENT} -n ${K8S_NAMESPACE}

kube-get-pods:
	kubectl get pods -l app.kubernetes.io/instance=${DEPLOYMENT} -n ${K8S_NAMESPACE}

kube-logs-f:
	kubectl logs -l app.kubernetes.io/instance=${DEPLOYMENT} -n ${K8S_NAMESPACE} --all-containers=true -f --prefix

kube-desc-pods:
	@for pod in $$(kubectl get pods -l app.kubernetes.io/instance=${DEPLOYMENT} -n ${K8S_NAMESPACE} -o name); do \
		echo "===== $$pod ====="; \
		kubectl describe $$pod -n ${K8S_NAMESPACE}; \
		echo; \
	done

kube-get-svc:
	kubectl get svc -l app.kubernetes.io/instance=${DEPLOYMENT} -n ${K8S_NAMESPACE}

kube-get-route:
	kubectl get route -l app.kubernetes.io/instance=${DEPLOYMENT} -n ${K8S_NAMESPACE}

kube-port-forward:
	kubectl port-forward svc/${DEPLOYMENT} -n ${K8S_NAMESPACE} 25555:5555

kube-undeploy:
	helm delete ${DEPLOYMENT} webmethods/microservicesruntime -n ${K8S_NAMESPACE}


mssql-select:
	kubectl exec -it mssql-0 -n sqlserver -- \
	  /opt/mssql-tools18/bin/sqlcmd -S localhost -U ${SQLSERVER_USERNAME} \
	  -P $$(kubectl get secret mssql-secret -n sqlserver -o jsonpath='{.data.SA_PASSWORD}' | base64 --decode) \
	  -C -Q "SELECT * from sandbox.dbo.accounts order by id desc;"

