SHELL := /bin/bash

TERRAFORM := terraform
ENVS_DIR := envs

.PHONY: help init validate plan-dev apply-dev destroy-dev plan-prod apply-prod destroy-prod

help:
	@printf "Makefile targets:\n"
	@printf "  init               Initialize terraform in envs (runs for both envs)\n"
	@printf "  validate           Run terraform validate from envs/dev and envs/prod\n"
	@printf "  plan-dev           Create plan for dev -> $(ENVS_DIR)/dev/dev.plan\n"
	@printf "  apply-dev          Apply plan file $(ENVS_DIR)/dev/dev.plan and append apply log\n"
	@printf "  destroy-dev        Destroy resources for dev (uses dev.tfvars)\n"
	@printf "  plan-prod          Create plan for prod -> $(ENVS_DIR)/prod/prod.plan\n"
	@printf "  apply-prod         Apply plan file $(ENVS_DIR)/prod/prod.plan and append apply log\n"
	@printf "  destroy-prod       Destroy resources for prod (uses prod.tfvars)\n"

init:
	@echo "Initializing terraform in $(ENVS_DIR)/dev and $(ENVS_DIR)/prod"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/dev init
	$(TERRAFORM) -chdir=$(ENVS_DIR)/prod init

validate:
	@echo "Validating dev and prod"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/dev validate || true
	$(TERRAFORM) -chdir=$(ENVS_DIR)/prod validate || true

plan-dev:
	@mkdir -p $(ENVS_DIR)/dev
	@echo "Planning dev -> $(ENVS_DIR)/dev/dev.plan"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/dev plan -var-file=terraform/dev.tfvars -out=$(ENVS_DIR)/dev/dev.plan

apply-dev:
	@if [ ! -f "$(ENVS_DIR)/dev/dev.plan" ]; then echo "Plan file $(ENVS_DIR)/dev/dev.plan not found; run make plan-dev"; exit 1; fi
	@echo "Applying $(ENVS_DIR)/dev/dev.plan"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/dev apply -auto-approve "$(ENVS_DIR)/dev/dev.plan" 2>&1 | tee -a $(ENVS_DIR)/dev/apply.log

destroy-dev:
	@echo "Destroying dev using dev.tfvars"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/dev destroy -var-file=terraform/dev.tfvars -auto-approve 2>&1 | tee -a $(ENVS_DIR)/dev/destroy.log || true

plan-prod:
	@mkdir -p $(ENVS_DIR)/prod
	@echo "Planning prod -> $(ENVS_DIR)/prod/prod.plan"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/prod plan -var-file=terraform/prod.tfvars -out=$(ENVS_DIR)/prod/prod.plan

apply-prod:
	@if [ ! -f "$(ENVS_DIR)/prod/prod.plan" ]; then echo "Plan file $(ENVS_DIR)/prod/prod.plan not found; run make plan-prod"; exit 1; fi
	@echo "Applying $(ENVS_DIR)/prod/prod.plan"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/prod apply -auto-approve "$(ENVS_DIR)/prod/prod.plan" 2>&1 | tee -a $(ENVS_DIR)/prod/apply.log

destroy-prod:
	@echo "Destroying prod using prod.tfvars"
	$(TERRAFORM) -chdir=$(ENVS_DIR)/prod destroy -var-file=terraform/prod.tfvars -auto-approve 2>&1 | tee -a $(ENVS_DIR)/prod/destroy.log || true
