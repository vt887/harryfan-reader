# Makefile for Swift project building, linting, and running tasks

SWIFT_FLAGS=-Xswiftc -sdk -Xswiftc $(shell xcrun --sdk macosx --show-sdk-path) -Xswiftc -no-verify-emitted-module-interface

.PHONY: lint style build run test pre-commit

lint:
	swiftformat . --swift-version 5.9 -verbose

style:
	swiftlint --fix --format
	
build:
	swift build --build-tests $(SWIFT_FLAGS)

run:
	swift build --build-tests $(SWIFT_FLAGS) && \
	swift run

test:
	swift test $(SWIFT_FLAGS)

stat:
	wc -l Sources/HarryFanReader/*.swift

pre-commit:
	@echo "Installing pre-commit hook..."
	@cp scripts/pre-commit.sh .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed successfully!"
