DEBUG ?=

SHELL = /bin/bash -o pipefail

DIR = $(shell pwd)

CONFIG_HOME = $(or ${XDG_CONFIG_HOME},${XDG_CONFIG_HOME},${HOME}/.config)

INSPEC_EXEC=PATH=${HOME}/.gem/ruby/2.7.0/bin/:${PATH} inspec exec

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m
INFO_COLOR=\033[36m
WHITE_COLOR=\033[1m

MAKE_COLOR=\033[33;01m%-20s\033[0m

.DEFAULT_GOAL := help

OK=[✅]
KO=[❌]
WARN=[🟡]


.PHONY: help
help:
	@echo -e "$(OK_COLOR)                  $(BANNER)$(NO_COLOR)"
	@echo "------------------------------------------------------------------"
	@echo ""
	@echo -e "${ERROR_COLOR}Usage${NO_COLOR}: make ${INFO_COLOR}<target>${NO_COLOR}"
	@awk 'BEGIN {FS = ":.*##"; } /^[a-zA-Z_-]+:.*?##/ { printf "  ${INFO_COLOR}%-25s${NO_COLOR} %s\n", $$1, $$2 } /^##@/ { printf "\n${WHITE_COLOR}%s${NO_COLOR}\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo -e "$(ERROR_COLOR)Environment variable $* not set$(NO_COLOR)"; \
		exit 1; \
	fi

check-%:
	@if $$(hash $* 2> /dev/null); then \
		echo -e "$(OK_COLOR)$(OK)$(NO_COLOR) $*"; \
	else \
		echo -e "$(ERROR_COLOR)$(KO)$(NO_COLOR) $*"; \
	fi

print-%:
	@if [ "${$*}" == "" ]; then \
		echo -e "$(ERROR_COLOR)[KO]$(NO_COLOR) $* = ${$*}"; \
	else \
		echo -e "$(OK_COLOR)[OK]$(NO_COLOR) $* = ${$*}"; \
	fi


# ====================================
# S O F T W A R E   V E R S I O N S
# ====================================


KUBE_VERSION = 1.21.9
KUBECTL_VERSION = 1.23.4
KUSTOMIZE_VERSION = 3.4.0
CONFTEST_VERSION = v0.30.0
KUBEVAL_VERSION = 0.16.1
POPEYE_VERSION = 0.9.8
ANSIBLE_VERSION = 5.7.1
MOLECULE_VERSION = 3.6.1

ANSIBLE_VENV = $(DIR)/venv
ANSIBLE_ROLES = $(DIR)/roles/
ANSIBLE_COLLECTIONS_PATH = $(DIR)/roles/ansible_collections:~/.ansible/collections:/usr/share/ansible/collections
ANSIBLE_ROLES_PATH = $(DIR)/roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles


# ====================================
# D E V
# ====================================

.PHONY: check ## Check requirements
check: check-ansible



# ====================================
# A N S I B L E
# ====================================

##@ Ansible

.PHONY: ansible-init
ansible-init: ## Install requirements
	@echo -e "$(OK_COLOR) Install requirements$(NO_COLOR)"
	@test -d $(ANSIBLE_VENV) || python3 -m venv $(ANSIBLE_VENV)
	@. $(ANSIBLE_VENV)/bin/activate \
		&& pip3 install pip --upgrade \
		&& pip3 install ansible==$(ANSIBLE_VERSION) molecule==$(MOLECULE_VERSION)


.PHONY: ansible-deps
ansible-deps: ## Install dependencies
	@echo -e "$(OK_COLOR) Install dependencies$(NO_COLOR)"
	@. $(ANSIBLE_VENV)/bin/activate \
		&& ANSIBLE_CONFIG=ansible/ansible.cfg \
		ansible-galaxy install -r roles/requirements.yml -p $(ANSIBLE_ROLES) --force && \
		ansible-galaxy collection install -r collections/requirements.yml --force


.PHONY: ansible-ping
ansible-ping: ## Check Ansible installation
	@echo -e "$(OK_COLOR) Check Ansible$(NO_COLOR)"
	@. $(ANSIBLE_VENV)/bin/activate \
		&& ANSIBLE_CONFIG=ansible.cfg \
		ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATH) \
		ANSIBLE_ROLES_PATH=roles/:$(ANSIBLE_ROLES_PATH) \
		ansible -c local -m ping all -i inventories/bootstrap.ini

.PHONY: ansible-debug
ansible-debug: ## Retrieve informations from hosts
	@echo -e "$(OK_COLOR) Check Ansible$(NO_COLOR)"
	@. $(ANSIBLE_VENV)/bin/activate \
		&& ANSIBLE_CONFIG=ansible.cfg \
		ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATH) \
		ANSIBLE_ROLES_PATH=roles/:$(ANSIBLE_ROLES_PATH) \
		ansible -m setup all -i inventories/bootstrap.ini


.PHONY: ansible-run
ansible-run: guard-PLAYBOOK ## Execute Ansible playbook (PLAYBOOK=xxx)
	@if [ -n "$(DEPS)" ];then \
		echo -e "I will pull deps for you, next time you can use DEPS=false "; \
		. $(ANSIBLE_VENV)/bin/activate \
			&& make ansible-deps SERVICE=$(PLAYBOOK); \
	fi
	@echo -e "$(OK_COLOR) Execute Ansible playbook$(NO_COLOR)"
	@. $(ANSIBLE_VENV)/bin/activate \
		&& ANSIBLE_CONFIG=ansible.cfg \
		ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATH) \
		ANSIBLE_ROLES_PATH=roles/:$(ANSIBLE_ROLES_PATH) \
		ansible-playbook $(DEBUG) -i inventories/bootstrap.ini $(PLAYBOOK).yml $(OPTIONS)

.PHONY: ansible-dryrun
ansible-dryrun: guard-PLAYBOOK ## Execute Ansible playbook (PLAYBOOK=xxx)
	@echo -e "$(OK_COLOR) Execute Ansible playbook$(NO_COLOR)"
	@. $(ANSIBLE_VENV)/bin/activate \
		&& ANSIBLE_CONFIG=ansible.cfg \
		ANSIBLE_COLLECTIONS_PATH=$(ANSIBLE_COLLECTIONS_PATH) \
		ANSIBLE_ROLES_PATH=roles/:$(ANSIBLE_ROLES_PATH) \
		ansible-playbook $(DEBUG) -i inventories/bootstrap.ini $(PLAYBOOK).yml --check $(OPTIONS)
