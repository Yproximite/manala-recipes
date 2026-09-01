_MANALA_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := help

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_@%-]+:.*## / {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: manala
manala: ## Synchronize the project with the recipe
	manala up
	bash $(_MANALA_DIR)/postsync.sh
