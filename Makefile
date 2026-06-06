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
