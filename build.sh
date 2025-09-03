#!/bin/bash

echo "Building HarryFanReader..."

# Build the application
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running HarryFanReader..."
    swift run
else
    echo "Build failed!"
    exit 1
fi
