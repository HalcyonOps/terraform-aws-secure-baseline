# Makefile — terraform-aws-secure-baseline
# Primary local interface. Mirrors the checks CI runs.
#
#   make fmt        # rewrite all files to canonical format
#   make validate   # terraform validate every module
#   make test       # native terraform test for every module
#   make lint       # tflint every module
#   make docs       # regenerate every module README
#   make check      # fmt-check + validate + test + lint + docs-check (CI parity)

SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

# Every directory under modules/ that contains a main.tf.
MODULES := $(notdir $(wildcard modules/*))

.PHONY: help fmt fmt-check validate test lint docs docs-check check clean

help:
	@echo "Targets: fmt validate test lint docs check clean"
	@echo "Modules: $(MODULES)"

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive -diff

validate:
	@for m in $(MODULES); do \
		echo "==> validate $$m"; \
		terraform -chdir=modules/$$m init -backend=false -input=false >/dev/null; \
		terraform -chdir=modules/$$m validate; \
	done

test:
	@for m in $(MODULES); do \
		echo "==> test $$m"; \
		terraform -chdir=modules/$$m init -backend=false -input=false >/dev/null; \
		terraform -chdir=modules/$$m test; \
	done

lint:
	@for m in $(MODULES); do \
		echo "==> tflint $$m"; \
		tflint --chdir=modules/$$m --config=$(CURDIR)/.tflint.hcl; \
	done

docs:
	@for m in $(MODULES); do \
		echo "==> docs $$m"; \
		terraform-docs -c .terraform-docs.yml modules/$$m; \
	done

docs-check:
	@for m in $(MODULES); do \
		echo "==> docs-check $$m"; \
		terraform-docs -c .terraform-docs.yml --output-check modules/$$m; \
	done

check: fmt-check validate test lint docs-check
	@echo "All checks passed."

clean:
	find . -type d -name '.terraform' -prune -exec rm -rf {} +
	find . -type f -name '.terraform.lock.hcl' -delete
