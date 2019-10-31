#  DevOps практики и инструменты - проектная работа

 
## Описание планируемых компонент

 * развёртывание кластера Kubernetes с помощью **kubespray**
 * Kuberetes кластер, состоящий из следующих компонент:
    * Kubernetes Dashboard
    * Cert-manager
    * Nginx ingress controller
    * NFS client provisioner
    * Gitlab
        * GitLab Runner
        * GitLab Registry
        * Minio
    * Мониторинг
        * Prometheus
        * Grafana
    * Логгирование (EFK)
        * Elasticsearch
        * Fluentd
        * Kibana
    * Postgres Operator (zalando)
    * Мессенджер Mattermost
 * микросервисное приложение на стэке PHP (фрэймворк Symfony) и JavaScript (Vue.js)
 

---
* https://gitlab.kubeplay.website
* https://grafana.kubeplay.website
* https://minio.kubeplay.website
* https://dash.kubeplay.website
* https://mm.kubeplay.website
* https://kibana.kubeplay.website
---

## Порядок развёртывания кластера и компонент

### Развёртывание кластера с помощью kubespray
  * Получить инфрастуктурный репозиторий:
    * `git clone git@github.com:bars83/symfony-k8s-boilerplate.git`    
    * `cd symfony-k8s-boilerplate`
  * В файл `./infra/kubespray-cluster-vars/inventory.ini` нужно прописать доступные ноды. В проекте используется 5 ВМ, запущенных в GCP, каждая из ВМ под управлением Ubuntu 18.04 LTS, со статическим внутренним IP адресом. На одной из ВМ так же добавлен статический внешний IP адрес. Между нодами по внутренней сети на фаерволе открыты все порты. В идеале ноды в облаке должны создаваться с помощью Terraform, но это осталось за рамками проектной работы.
  * Настройка кластера (!подразумевается наличие ключей appuser на клиенте, так же эти ключи должны быть прописаниы на виртуальных машинах!):
    * `cd infra/kubespray && ansible-playbook --flush-cache -i ../kubespray-cluster-vars/inventory.ini --become cluster.yml --private-key=~/.ssh/appuser`
  * дождаться завершения (~40 минут для кластера из 5 нод)
  * скопировать конфиг с конекстом для работы с кластером через kubectl
    * `cp infra/kubespray-cluster-vars/artifacts/admin.conf ~/.kube/config`


### Настройка NFS для хранения persistent volume claims кластера

  * В файл `./infra/ansible/inventory` указать адрес ВМ, которая будет использоваться для предоставления сервиса NFS
    * `cd ./infra/ansible && ansible-galaxy install -r requirements.yml && ansible-playbook -i inventory playbooks/nfs.yml`
  * На каждой ВМ кластера установить NFS клиент (лучше это сделать тоже с помощью ansible, но в рамках курсовой работы сделано руками... )
    * `sudo apt update && sudo apt install -y nfs-common`
  * Т.к. helm уже установлен при развёртывании через kubespray, достаточно убедиться в наличии клиента, далее можем использовать его
  * Установка [NFS client provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client)
    * `helm install --name nfs-client-provisioner --namespace kube-system --set nfs.server=10.128.15.212 --set nfs.path=/mnt/disks/sdb/common --set storageClass.defaultClass=true stable/nfs-client-provisioner`

### Установка Nginx ingress controller
  * `helm install --name nginx-ingress --namespace kube-system -f ./infra/k8s-ingress/custom_values.yaml stable/nginx-ingress`
  * Т.к. у нас нет облачного балансировщика, то на ВМ с внешним адресом нужно установить nginx, и для него применить да конфигурационных файла из этого репозитория:
    * `./infra/nginx/nginx.conf` в `/etc/nginx/nginx.conf`
    * `./infra/nginx/conf.d/ingress-proxy.conf` в `/etc/nginx/conf.d/ingress-proxy.conf`

### Установка Cert manager для автоматического получения Letsencrypt сертификатов
  * `kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml` 
  * `helm repo add jetstack https://charts.jetstack.io`
  * `helm install --name cert-manager --namespace cert-manager jetstack/cert-manager`
  * `kubectl apply -f infra/k8s-letsencrypt/letsencrypt.yaml`

### Установка мессенджера Mattermost
  * `helm install --name mattermost -f ./mattermost/custom.yaml mattermost/mattermost-team-edition`


### Установка и настройка сервисов мониторинга и алертинга
  * `kubectl apply -f  ./infra/k8s-metrics/deploy/1.8+`
  * `helm install --namespace monitoring --name prometheus -f ./infra/k8s-monitoring/prom_custom.yaml stable/prometheus`
  * `helm install --namespace monitoring --name grafana -f ./infra/k8s-monitoring/grafana_custom.yaml stable/grafana`
  * `kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo` - пароль для доступа к Grafana
  * `kubectl apply -f infra/dashboard-ingress.yaml` - доступ извне к Grafana
  * `export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}"); kubectl --namespace monitoring port-forward $POD_NAME 9095:9090` - попасть на веб-интерфейс Prometheus'а можно через http://localhost:9095
  * Метрики для кластера
    * `git clone https://github.com/kubernetes-incubator/metrics-server.git ./infra/k8s-metrics`
    * `cp ./infra/k8s-monitoring/metrics-server-deployment.yaml ./infra/k8s-metrics/deploy/1.8+/` - оригинальный манифест немного изменён для того что бы экспортер мог собирать метрики с эндпоинтов с самоподписанными сертификатами
  
### Postgres Operator ([zalando/postgres-operator](https://github.com/zalando/postgres-operator))      
  * `helm install --name zalando --namespace zalando ./infra/zalando/charts/postgres-operator`


### GitLab
  * `helm repo add gitlab https://charts.gitlab.io && helm repo update`
  * `kubectl label nodes node3 gitlab-runner=true`
  * `helm fetch gitlab/gitlab --untar --untardir ./infra/gitlab`
  * `cp ./infra/gitlab/runner-custom-configmap.yaml ./infra/gitlab/gitlab/charts/gitlab-runner/templates/configmap.yaml` - кастомный configmap, позволяющий пробрасывать хостовый ``/var/run/docker.sock`` в под с гитлаб раннером, для доступа к кэшу образов
  * `helm install --namespace gitlab --name gitlab -f ./infra/gitlab/custom_values.yaml ./infra/gitlab/gitlab`
  * `kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo` - пароль для доступа к GitLab
  * `echo 'access_key:';kubectl get secret -n gitlab gitlab-minio-secret -ojsonpath='{.data.accesskey}' | base64 --decode ; echo && echo 'secret_key:'; kubectl get secret -n gitlab gitlab-minio-secret -ojsonpath='{.data.secretkey}' | base64 --decode ; echo`
  * Настройка GitLab для работы с кластером (подробное описание будет позже)
    * `kubectl get secret default-token-5dgbm -o jsonpath="{['data']['ca\.crt']}" | base64 --decode `
    * `kubectl apply -f ./infra/gitlab/gitlab-admin-service-account.yaml`
    * `kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')`
  * Доступ к GitLab по ssh (предварительно нужно загрузить свой ключ в интерфейсе гитлаба) - в `~/.ssh/config` нужно добавить
```Host gitlab.kubeplay.website
User git
Port 50022
Hostname gitlab.kubeplay.website
```


### Логгирование (EFK)
  * `kubectl label nodes node3 elastichost=true`
  * `kubectl create ns logging`
  * `for i in 1 2 3 4 5; do kubectl label nodes node${i} beta.kubernetes.io/fluentd-ds-ready=true; done`
  * `kubectl apply -f ./infra/efk/fluentd -n logging`
  * `helm repo add elastic https://helm.elastic.co`
  * `helm install --namespace logging --name elasticsearch -f ./infra/efk/elastic_custom_values.yaml elastic/elasticsearch`
  * `helm install --namespace logging --name kibana -f ./infra/efk/kibana_custom_values.yaml elastic/kibana`




---
## Приложение

### Получение репозитория с GitHub
  * `git clone git@github.com:bars83/symfony-vuejs.git .`
### Загрузка репозитория в GitLab
  * `git remote rename origin github`
  * в интерфейсе Гитлаба создать группу `demo`, в нём проект `symvue`, далее:
  * `git remote add gitlab git@gitlab.kubeplay.website:demo/symvue`
  * `git checkout -b feature/1 && git push gitlab` - для CI конвеера с review стадией, после чего приложение будет доступно по адресу https://symvue-feature-1.kubeplay.website (login/pass: foo/bar)
  * `git checkout master && git push gitlab` - для CI конвеера со стадиями
    * staging - выполняется автоматически, после чего приложение доступно по адресу https://demo-symvue-staging.kubeplay.website (login/pass: foo/bar)
    * production - выполняется вручную ("по кнопке"), после чего приложение доступно по адресу https://demo-symvue.kubeplay.website (login/pass: foo/bar)
### Метрики приложения
  * У приложения есть эндпоинт с метриками `/metrics`
  * Одна из метрик (`post_count`) возвращает количество постов
### Уведомления в Mattermost
  * Настойка на текущем кластере (kubeplay.website) производилась вручную, а именно были созданы каналы в мессенджере, для каналов были созданы webhook's (практически как в Slack), полученные вебхуки прописаны в Гитлабе и в Alertmanager. Уведомлния приходят:
    * При изменениях в ветках репозитория
    * При успешных и неудачных CI пайплайнах 
    * Если в приложении будет больше 5 постов (метрика `post_count`), то Prometheus Alertmanager отправит уведомление
