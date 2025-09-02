#!/bin/bash

echo "Building HarryfanReader..."

# Build the application
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running HarryfanReader..."
    swift run
else
    echo "Build failed!"
    exit 1
fi
