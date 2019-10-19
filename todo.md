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
    * `sudo lsblk`
    * `sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb`
    * `sudo mkdir -p /mnt/disks/sdb`
    * `sudo mount /dev/sdb /mnt/disks/sdb`
    * `cd /mnt/disks/sdb/`
    * `sudo chown -R appuser:appuser .`
    * `mkdir prometheus`
    * `mkdir elasticsearch`
    * `mkdir postgres`
    * `sudo apt update && sudo apt install -y nfs-common`
    * `helm install --name nfs-client-provisioner --set nfs.server=10.128.15.212 --set nfs.path=/mnt/disks/sdb/common stable/nfs-client-provisioner`
    * `cd ./infra/k8s-monitoring/prometheus-chart && helm upgrade prom . -f custom_values.yaml --install`
    * `cd ./mattermost && helm install --name mattermost -f custom.yaml mattermost/mattermost-team-edition`
 
 kubectl apply     -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.11/deploy/manifests/00-crds.yaml
 
 helm repo add jetstack https://charts.jetstack.io
 helm install --name cert-manager --namespace cert-manager jetstack/cert-manager


* разобраться с Persistant Volume на NFS
* terraform
* ~~ansible + vargant/gcp~~


---
## SSL сертификаты
letsencrypt


---
## Планируеме имена доменов
https://kubeplay.website - main

https://gitlab.kubeplay.website

https://mattermost.kubeplay.website

https://prometheus.kubeplay.website

https://grafana.kubeplay.website

https://kibana.kubeplay.website