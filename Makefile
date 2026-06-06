.DEFAULT_GOAL := help
.PHONY: help gen team test

-include .env
export

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; section=""} \
		/^## / { section=substr($$0,4); next } \
		/^[a-zA-Z_-]+:.*##/ { \
			if (section != prev) { printf "\033[36m%s\033[0m\n", section; prev=section } \
			printf "  \033[33m%-18s\033[0m %s\n", $$1, $$2 \
		}' $(MAKEFILE_LIST)

gen: ## Generate Xcode project
	@xcodegen generate

team: ## Set DEVELOPMENT_TEAM from Xcode build settings
	@xcodebuild -showBuildSettings -project ColorWheel.xcodeproj -scheme ColorWheel 2>/dev/null \
		| grep '^[[:space:]]*DEVELOPMENT_TEAM = [^[:space:]]' | head -1 | tr -d ' ' > .env
	@cat .env

test: ## Run tests on iPhone 17 simulator
	@xcodebuild test -project ColorWheel.xcodeproj -scheme ColorWheel \
		-destination 'platform=iOS Simulator,name=iPhone 17'
