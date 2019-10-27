## Документация

 * readme
 * CHANGELOG


---
## Приложение

* ldap аутентификатор
* angular/react + symfony
    * https://github.com/kgatjens/Task-Manager-with-Symfony-Angular4
    * https://github.com/thecodingmachine/symfony-vuejs
* unit tests
* prometheus endpoints


---
## Statefull часть - БД + кэш

* postgres HA или master+slave
* redis HA or master+slave

---
## Кластер
k8s
~~rancher~~


---
## Вспомогательные инструменты
* gitlab
* mattermost


---
## Мониторинг и логгирование
* prometheus
* grafana
* elastic (cluster?) + fluentd + kibana


---
## Провижининг ВМ для кластера, инфраструктура

* 4-6 виртуалок под ноды
* 1 виртуалка как NFS сервер
    * `cd infra/kubespray && ansible-playbook --flush-cache -i ../kubespray-cluster-vars/inventory.ini --become cluster.yml --private-key=~/.ssh/appuser`
    * `kubectl label nodes node1 external=true`
    * `sudo lsblk`
    * `sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb`
    * `sudo mkdir -p /mnt/disks/sdb`
    * `sudo mount /dev/sdb /mnt/disks/sdb`
    * `cd /mnt/disks/sdb/`
    * `sudo chown -R appuser:appuser .`
    * `mkdir comon`
    * `sudo apt update && sudo apt install -y nfs-common`
    * `helm install --name nfs-client-provisioner --namespace kube-system --set nfs.server=10.128.15.212 --set nfs.path=/mnt/disks/sdb/common --set storageClass.defaultClass=true stable/nfs-client-provisioner`
    * `helm install --name nginx-ingress --namespace kube-system -f ./infra/k8s-ingress/custom_values.yaml stable/nginx-ingress`
    * `cd ./infra/k8s-monitoring/prometheus-chart && helm upgrade prom . -f custom_values.yaml --install`
    * `helm install --name mattermost -f ./mattermost/custom.yaml mattermost/mattermost-team-edition`
    * `kubectl apply -f  ./infra/k8s-metrics/deploy/1.8+`
    * `helm install --namespace monitoring --name prometheus -f ./infra/k8s-monitoring/prom_custom.yaml stable/prometheus`
    * `helm install --namespace monitoring --name grafana -f ./infra/k8s-monitoring/grafana_custom.yaml stable/grafana`
    * `kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`
    * `kubectl apply -f infra/dashboard-ingress.yaml`
    * `helm install --name zalando --namespace zalando ./infra/zalando/charts/postgres-operator`
    * `kubectl create -f infra/zalando/manifests/minimal-postgres-manifest.yaml`
    * `kubectl label nodes node3 largemem=true`
    * `helm repo add gitlab https://charts.gitlab.io && helm repo update`
    * `helm install --namespace gitlab --name gitlab -f ./infra/gitlab/custom_values.yaml gitlab/gitlab`
    * `kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo`
    * `echo 'access_key:';kubectl get secret -n gitlab gitlab-minio-secret -ojsonpath='{.data.accesskey}' | base64 --decode ; echo && echo 'secret_key:'; kubectl get secret -n gitlab gitlab-minio-secret -ojsonpath='{.data.secretkey}' | base64 --decode ; echo`
    * `kubectl label nodes node3 elastichost=true`

    * `kubectl create ns logging`
    * `kubectl label nodes node1 beta.kubernetes.io/fluentd-ds-ready=true`
    * `kubectl label nodes node2 beta.kubernetes.io/fluentd-ds-ready=true`
    * `kubectl label nodes node3 beta.kubernetes.io/fluentd-ds-ready=true`
    * `kubectl label nodes node4 beta.kubernetes.io/fluentd-ds-ready=true`
    * `kubectl apply -f ./infra/efk/fluentd -n logging`
    * `helm repo add elastic https://helm.elastic.co`
    * `helm install --namespace logging --name elasticsearch -f ./infra/efk/elastic_custom_values.yaml elastic/elasticsearch`
    * `helm install --namespace logging --name kibana -f ./infra/efk/kibana_custom_values.yaml elastic/kibana`
    * `kubectl create secret generic basic-auth --from-file=auth -n mailhog`
    * `helm install --name mailhog --namespace mailhog -f ./infra/mailhog/custom_values.yaml stable/mailhog`

    * `ansible-playbook -i ./infra/kubespray-cluster-vars/inventory.ini --become ./infra/kubespray/scale.yml --private-key=~/.ssh/appuser`

    ###* `htpasswd -c auth kibana`
    ###* `kubectl create secret generic basic-auth --from-file=auth -n logging && rm auth`
    * kubep!ay


mai!h0g


Host gitlab.kubeplay.website
User git
Port 50022
Hostname gitlab.kubeplay.website



https://github.com/docker-library/docker/issues/103 - gitlab-runner and MTU


curl -v -XPOST http://10.233.92.15:3000/api/dashboards/import --cookie grafana_session=2ff0d4258dadb4a4a475768574dc917c -d @grafana_import_payload.json



export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9095:9090

 kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml
 
 helm repo add jetstack https://charts.jetstack.io
 helm install --name cert-manager --namespace cert-manager jetstack/cert-manager
 kubectl apply -f infra/k8s-letsencrypt/letsencrypt.yaml

    * `cd ./infra/k8s-ingress/nginx-ingress && helm install . -f custom_values.yaml --namespace kube-system --name nginx-ingress`
    * `helm install --name nginx-ingress --namespace kube-system -f ./infra/k8s-ingress/custom_values.yaml stable/nginx-ingress`

    * `kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml`
    * `helm repo add jetstack https://charts.jetstack.io`
    * `helm install --name cert-manager --namespace cert-manager jetstack/cert-manager`
    * `kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"`
    *


    * `helm install stable/cert-manager \
    --namespace kube-system \
    --set ingressShim.defaultIssuerName=letsencrypt-prod \
    --set ingressShim.defaultIssuerKind=ClusterIssuer \
    --version v0.5.2`
    * ``
    * ``
    
    
    
    
    * `helm install mattermost/mattermost-team-edition --set mysql.mysqlUser=********** --set mysql.mysqlPassword==**********`

 kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces



## https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html 
# Install the CustomResourceDefinition resources separately
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.11.0 \
  jetstack/cert-manager


https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/


* разобраться с Persistant Volume на NFS
* terraform
* ~~ansible + vargant/gcp~~


---
## SSL сертификаты
letsencrypt


---
## Планируемое имена доменов
https://kubeplay.website - main

https://gitlab.kubeplay.website

https://mattermost.kubeplay.website

https://prometheus.kubeplay.website

https://grafana.kubeplay.website

https://kibana.kubeplay.website


kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml


containers:
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
        command:
        - /metrics-server
        - --kubelet-insecure-tls
        imagePullPolicy: Always
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp


kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

helm upgrade mattermost -f ./mattermost/custom.yaml mattermost/mattermost-team-edition
helm install --name prometheus stable/prometheus
