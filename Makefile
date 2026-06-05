.DEFAULT_GOAL := gen
.PHONY: gen team test

-include .env
export

gen:
	@xcodegen generate

team:
	@xcodebuild -showBuildSettings -project ColorWheel.xcodeproj -scheme ColorWheel 2>/dev/null \
		| grep '^[[:space:]]*DEVELOPMENT_TEAM = [^[:space:]]' | head -1 | tr -d ' ' > .env
	@cat .env

test:
	@xcodebuild test -project ColorWheel.xcodeproj -scheme ColorWheel \
		-destination 'platform=iOS Simulator,name=iPhone 17'

resume-local:
	ANTHROPIC_BASE_URL=http://192.168.1.251:1234 ANTHROPIC_AUTH_TOKEN=sk-anything claude --resume color-wheel

resume-claude:
	ANTHROPIC_BASE_URL= ANTHROPIC_AUTH_TOKEN= claude --resume color-wheel
