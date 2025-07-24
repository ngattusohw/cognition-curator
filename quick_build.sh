#!/bin/bash

# Cognition Curator - Quick Build Check
# Super fast compilation check without simulators or tests

echo "⚡ Quick Build Check"
echo "==================="

PROJECT_PATH="cognition.curator/cognition.curator.xcodeproj"
SCHEME="cognition.curator"

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Project not found at $PROJECT_PATH"
    exit 1
fi

# Quick build check (no simulator, no tests)
echo "🔨 Building..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination generic/platform=iOS build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ BUILD SUCCESSFUL"
    echo "🚀 Code compiles correctly!"
else
    echo "❌ BUILD FAILED"
    echo "🔍 Running detailed build to show errors..."
    xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination generic/platform=iOS build
    exit 1
fi
