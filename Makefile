# Makefile for Swift project building, linting, and running tasks
#!/bin/bash -xe

.PHONY: lint build run pre-commit

lint:
	swiftformat . --swift-version 6.2 -verbose

build:
	swift build

run:
	swift build && \
	swift run

pre-commit:
	@echo "Installing pre-commit hook..."
	@cp scripts/pre-commit.sh .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed successfully!"
