# === Makefile: DevOps Automation for MacOS (VirtualBox & Libvirt) ===
# Supports:
# - Python env setup
# - Ansible + Molecule installs
# - Vagrant with VirtualBox (Intel) or Libvirt (Apple Silicon)
# - Local + remote provisioning with dynamic inventory
# - Molecule testing
# - Loki observability container (optional)

SHELL := /bin/bash
VENV := .venv
PYTHON := python3.10
PIP := $(VENV)/bin/pip
ANSIBLE := $(VENV)/bin/ansible-playbook
LINT := $(VENV)/bin/ansible-lint
MOLECULE := $(VENV)/bin/molecule
ANSIBLE_GALAXY := $(VENV)/bin/ansible-galaxy
ARCH := $(shell uname -m)

# --- Python Virtual Environment Setup ---
.PHONY: deps
deps:
	@echo "🐍 Setting up Python environment..."
	@test -d $(VENV) || $(PYTHON) -m venv $(VENV)
	@$(PIP) install --upgrade pip setuptools wheel
	@$(PIP) install "ansible>=9,<10" ansible-lint
	@$(PIP) install "molecule>=5" "molecule-plugins[docker]"
	@$(ANSIBLE_GALAXY) collection install -r collections/requirements.yml

# --- Tooling Setup ---
.PHONY: setup-mac vagrant-install libvirt-install virtualbox-install
setup-mac: vagrant-install virtualbox-install libvirt-install

vagrant-install:
	@command -v vagrant >/dev/null || brew install --cask vagrant

virtualbox-install:
	@if [ "$(ARCH)" = "x86_64" ]; then \
	  command -v VBoxManage >/dev/null || brew install --cask virtualbox; \
	else \
	  echo "⛔ Skipping VirtualBox: not supported on Apple Silicon"; \
	fi

libvirt-install:
	@if [ "$(ARCH)" = "arm64" ]; then \
	  brew install qemu libvirt; \
	  brew services start libvirt; \
	  vagrant plugin list | grep -q vagrant-libvirt || vagrant plugin install vagrant-libvirt; \
	else \
	  echo "ℹ️  Skipping libvirt install on Intel."; \
	fi

# --- One-Command Workflow for Local Dev ---

.PHONY: dev-up
dev-up: deps vagrant-up inventory provision-local
	@echo "🎉 Dev environment is up and provisioned!"

.PHONY: dev-rebuild
dev-rebuild: vagrant-down clean deps dev-up
	@echo "🔁 Dev environment rebuilt from scratch."

# --- Vagrant VM Control ---
.PHONY: vagrant-up vagrant-down
vagrant-up: vagrant-install
	@echo "📦 Booting Vagrant VM..."
	@if [ "$(ARCH)" = "arm64" ]; then \
	  vagrant up --provider=libvirt; \
	else \
	  vagrant up --provider=virtualbox; \
	fi
	@$(MAKE) inventory

vagrant-down:
	@echo "🧹 Tearing down VM and cleaning SSH entries..."
	@vagrant destroy -f || true
	@ssh-keygen -R "[127.0.0.1]:2222" 2>/dev/null || true
	@ssh-keygen -R "[127.0.0.1]:50022" 2>/dev/null || true

# --- Ansible Provisioning ---
.PHONY: provision-local provision-remote rerun-ansible
provision-local:
	@echo "🚀 Running Ansible against Vagrant VM..."
	. $(VENV)/bin/activate && $(ANSIBLE) -i inventory.ini site.yml -e target_hosts=vagrant -v

provision-remote:
	@echo "🌐 Deploying to remote Ubuntu servers..."
	. $(VENV)/bin/activate && $(ANSIBLE) -i inventory.ini site.yml -e target_hosts=ubuntu_servers -v

rerun-ansible:
	@echo "🔁 Re-running Ansible playbook..."
	. $(VENV)/bin/activate && $(ANSIBLE) -i inventory.ini site.yml -e target_hosts=vagrant -v

# --- Inventory File Generation ---
.PHONY: inventory

inventory:
	@echo "🔧 Regenerating [vagrant] block in inventory.ini..."
	@vagrant ssh-config > ssh-config

	@# Backup existing inventory
	@cp inventory.ini inventory.ini.bak || true

	@# Remove existing [vagrant] block
	@awk 'BEGIN { skip = 0 } \
		/^\[vagrant\]/ { skip = 1; next } \
		/^\[/ { skip = 0 } \
		!skip { print }' inventory.ini.bak > tmp_inventory.ini || true

	@# Add updated [vagrant] block
	@echo "[vagrant]" > inventory.ini
	@echo -n "vagrant1 " >> inventory.ini
	@awk '\
	  $$1 == "HostName" { printf "ansible_host=%s ", $$2 } \
	  $$1 == "User" { printf "ansible_user=%s ", $$2 } \
	  $$1 == "Port" { printf "ansible_port=%s ", $$2 } \
	  $$1 == "IdentityFile" { printf "ansible_ssh_private_key_file='\''%s'\''\n", $$2 }' \
	  ssh-config >> inventory.ini

	@# Append the rest of the inventory
	@cat tmp_inventory.ini >> inventory.ini
	@rm -f tmp_inventory.ini ssh-config

	@echo "✅ inventory.ini updated with Vagrant info, all other groups preserved."


# --- Linting ---
.PHONY: lint
lint:
	@echo "🔍 Running ansible-lint..."
	. $(VENV)/bin/activate && $(LINT) site.yml

# --- Molecule Tests ---
.PHONY: molecule-test
molecule-test:
	@echo "🧪 Running Molecule role tests..."
	@for d in roles/*; do \
	  if [ -d "$$d/molecule/default" ]; then \
	    echo "🔬 Testing $$d..."; \
	    (cd $$d && $(MOLECULE) test); \
	  fi \
	done

# --- Cleanup ---
.PHONY: clean
clean:
	@echo "🧹 Cleaning environment..."
	rm -rf .venv __pycache__ .pytest_cache .molecule
	vagrant destroy -f || true
	ssh-keygen -R "[127.0.0.1]:2222" 2>/dev/null || true
	ssh-keygen -R "[127.0.0.1]:50022" 2>/dev/null || true
	@PORTS="8081 8888"; \
	for port in $$PORTS; do \
	  PID=$$(lsof -ti tcp:$$port); \
	  if [ -n "$$PID" ]; then \
	    echo "⚠️  Port $$port in use — killing PID $$PID"; \
	    kill -9 $$PID; \
	  fi \
	done
