#!/bin/bash

echo "Building TxtViewer..."

# Build the application
swift build

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Running TxtViewer..."
    swift run
else
    echo "Build failed!"
    exit 1
fi
