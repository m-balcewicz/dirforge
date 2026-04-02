# DirForge Makefile
# Usage: make <target> [ARGS="..."]

SCRIPTS_DIR=./scripts
TESTS_DIR=./tests

# Default: show help
.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "\n\033[1mDirForge Project - Make Targets\033[0m\n"
	@printf "  \033[36m%-28s\033[0m %s\n" "install [ARGS=...]" "Install DirForge (default: --local)"
	@printf "  \033[36m%-28s\033[0m %s\n" "update [ARGS=...]" "Update DirForge or workspace"
	@printf "  \033[36m%-28s\033[0m %s\n" "uninstall [ARGS=...]" "Uninstall DirForge"
	@printf "  \033[36m%-28s\033[0m %s\n" "lint" "Lint all shell scripts"
	@printf "  \033[36m%-28s\033[0m %s\n" "test" "Run all tests"
	@printf "  \033[36m%-28s\033[0m %s\n" "bootstrap" "Check/install dev tools (yq, shellcheck, etc.)"
	@printf "  \033[36m%-28s\033[0m %s\n" "validate-help" "Validate help content"
	@printf "  \033[36m%-28s\033[0m %s\n" "update-test-syntax" "Update test files to new syntax"
	@printf "  \033[36m%-28s\033[0m %s\n" "comprehensive-test-update" "Update all test files with deprecated syntax"
	@echo "\n\033[1mUsage Examples:\033[0m"
	@echo "  make install ARGS=\"--local\""
	@echo "  make update ARGS=\"--dry-run\""
	@echo "  make uninstall ARGS=\"--all\""
	@echo "  make test"
	@echo "\nFor more, see each script's --help.\n"

.PHONY: install
install:
	@bash $(SCRIPTS_DIR)/install_dirforge.sh $(ARGS)

.PHONY: update
update:
	@bash $(SCRIPTS_DIR)/update_dirforge.sh $(ARGS)

.PHONY: uninstall
uninstall:
	@bash $(SCRIPTS_DIR)/uninstall_dirforge.sh $(ARGS)

.PHONY: lint
lint:
	@bash $(SCRIPTS_DIR)/lint_shell.sh

.PHONY: test
# Run the main test suite
# Usage: make test
# Optionally: ARGS="..." to pass to run_tests.sh
# Example: make test ARGS="--filter mytest"
test:
	@bash $(TESTS_DIR)/run_tests.sh $(ARGS)

.PHONY: bootstrap
bootstrap:
	@bash $(SCRIPTS_DIR)/bootstrap-dev.sh

.PHONY: validate-help
validate-help:
	@bash $(SCRIPTS_DIR)/validate_help_content.sh

.PHONY: update-test-syntax
update-test-syntax:
	@bash $(SCRIPTS_DIR)/update_test_syntax.sh

.PHONY: comprehensive-test-update
comprehensive-test-update:
	@bash $(SCRIPTS_DIR)/comprehensive_test_update.sh
