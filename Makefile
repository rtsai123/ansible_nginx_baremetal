SHELL := /bin/bash

VENV := .venv
ACTIVATE := source $(VENV)/bin/activate

.PHONY: deps vagrant-up deploy-local deploy-remote lint clean loki-up loki-down loki-logs

deps:
	 @test -d $(VENV) || python3 -m venv $(VENV)
	@$(ACTIVATE) && pip install --upgrade pip
	@$(ACTIVATE) && pip install "ansible>=9,<10" ansible-lint
	@$(ACTIVATE) && pip install "molecule>=5" "molecule-plugins[docker]"

vagrant-up:
	vagrant up
	vagrant provision

vagrant-down:
	vagrant destroy -f || true
	# Remove cached Vagrant SSH host keys to prevent SSH fingerprint conflicts
	ssh-keygen -R "[127.0.0.1]:2222" 2>/dev/null || true
	ssh-keygen -R "[127.0.0.1]:50022" 2>/dev/null || true

deploy-local:
	$(ACTIVATE) && ansible-playbook -i localhost, -c local site.yml

deploy-remote:
	$(ACTIVATE) && ansible-playbook -i inventory.ini site.yml

lint:
	$(ACTIVATE) && ansible-lint site.yml

molecule-test:
	@for d in roles/*; do \
	  if [ -d "$$d/molecule/default" ]; then \
	    echo "Running molecule for $$d..."; \
	    $(ACTIVATE) cd $$d && molecule test && cd - > /dev/null; \
	  fi \
	done

rerun-ansible:
	ansible-playbook -i inventory.ini site.yml -e target_hosts=vagrant
clean:
	rm -rf .venv
	rm -rf __pycache__
	rm -rf .pytest_cache
	rm -rf .molecule
	vagrant destroy -f || true
	# Remove cached Vagrant SSH host keys to prevent SSH fingerprint conflicts
	ssh-keygen -R "[127.0.0.1]:2222" 2>/dev/null || true
	ssh-keygen -R "[127.0.0.1]:50022" 2>/dev/null || true

loki-up:
	mkdir -p loki_test_node/{wal,loki,index,cache,compactor}
	docker run -d --name loki \
	  -p 3100:3100 \
	  -v "./loki_test_node/loki-config.yml:/etc/loki/local-config.yaml" \
	  -v "./loki_test_node/wal:/wal" \
	  -v "./loki_test_node/loki:/loki" \
	  grafana/loki:2.9.3 \
	  -config.file=/etc/loki/local-config.yaml

loki-down:
	docker rm -f loki

loki-logs:
	docker logs -f loki
