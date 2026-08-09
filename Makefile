# Makefile for WakeWake iOS Application
# Useful development, build, test, and code coverage commands

SIMULATOR_NAME ?= iPhone 17
SCHEME ?= WakeWake
DERIVED_DATA_PATH ?= ./build

.PHONY: help build test coverage clean list-destinations install-hooks

help: ## Display available Makefile commands
	@echo "========================================================================"
	@echo "                   WAKEWAKE IOS MAKEFILE COMMANDS                       "
	@echo "========================================================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the WakeWake app target for iOS Simulator
	@echo "🔨 Building WakeWake for $(SIMULATOR_NAME)..."
	xcodebuild build \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR_NAME)' \
		-derivedDataPath $(DERIVED_DATA_PATH)

test: ## Run unit and integration test suite
	@echo "🧪 Running unit & integration tests..."
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR_NAME)' \
		-parallel-testing-enabled NO \
		-derivedDataPath $(DERIVED_DATA_PATH)

coverage: ## Run test suite with code coverage enabled
	@echo "📊 Running tests with Code Coverage enabled..."
	xcodebuild test \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR_NAME)' \
		-parallel-testing-enabled NO \
		-enableCodeCoverage YES \
		-derivedDataPath $(DERIVED_DATA_PATH)
	@echo "✅ Code coverage results stored in $(DERIVED_DATA_PATH)/Logs/Test/"

install-hooks: ## Install Git pre-push hook to build and run test suite before push
	@echo "⚓️ Installing Git pre-push hook in .git/hooks/pre-push..."
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/pre-push
	@echo '# WakeWake Git Pre-Push Hook' >> .git/hooks/pre-push
	@echo 'echo "🚀 Running git pre-push check (build & test suite)..."' >> .git/hooks/pre-push
	@echo 'make build' >> .git/hooks/pre-push
	@echo 'if [ $$? -ne 0 ]; then echo "❌ Git push aborted: make build failed!"; exit 1; fi' >> .git/hooks/pre-push
	@echo 'make test' >> .git/hooks/pre-push
	@echo 'if [ $$? -ne 0 ]; then echo "❌ Git push aborted: make test failed!"; exit 1; fi' >> .git/hooks/pre-push
	@echo 'echo "✅ Pre-push verification passed! Proceeding with git push..."' >> .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "✅ Git pre-push hook installed successfully in .git/hooks/pre-push!"

clean: ## Clean build artifacts and derived data
	@echo "🧹 Cleaning build artifacts..."
	xcodebuild clean -scheme $(SCHEME)
	rm -rf $(DERIVED_DATA_PATH)

list-destinations: ## List available iOS Simulator destinations
	@echo "📱 Available Xcode destinations:"
	xcodebuild -showdestinations -scheme $(SCHEME)
