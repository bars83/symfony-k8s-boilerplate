ANSIBLE_CONFIG = ./infra/ansible/ansible.cfg

ansible: ansible-config ansible-requrements ansible-play-docker

ansible-play-docker:
	ansible-playbook -i infra/ansible/inventory infra/ansible/playbooks/docker.yml

ansible-requrements:
	ansible-galaxy install -r infra/ansible/requirements.yml

ansible-config:
	export ANSIBLE_CONFIG=${ANSIBLE_CONFIG}
