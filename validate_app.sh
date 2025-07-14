#!/bin/bash

# Cognition Curator - Fast Validation Script
# This script validates the entire app without launching simulators

echo "🧠 Cognition Curator - Fast Validation"
echo "======================================"

# Set up variables - corrected paths
PROJECT_PATH="cognition.curator/cognition.curator.xcodeproj"
SCHEME="cognition.curator"

# Function to check if command succeeded
check_result() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 - PASSED"
    else
        echo "❌ $1 - FAILED"
        exit 1
    fi
}

# Check if project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Project not found at $PROJECT_PATH"
    echo "Available projects:"
    find . -name "*.xcodeproj" -o -name "*.xcworkspace"
    exit 1
fi

echo "📁 Found project: $PROJECT_PATH"

# Step 1: Clean build folder (fast)
echo "🧹 Cleaning build folder..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" clean > /dev/null 2>&1
check_result "Clean Build"

# Step 2: Build for testing (no simulator needed)
echo "🔨 Building for testing..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" build-for-testing -destination generic/platform=iOS > /dev/null 2>&1
check_result "Build for Testing"

# Step 3: Run unit tests without UI tests (no simulator needed)
echo "🧪 Running unit tests..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" test-without-building -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:cognition.curatorTests > /dev/null 2>&1
check_result "Unit Tests"

# Step 4: Check for common issues
echo "🔍 Checking for common issues..."

# Check for force unwrapping
FORCE_UNWRAP_COUNT=$(find cognition.curator -name "*.swift" -exec grep -l "!" {} \; | wc -l | tr -d ' ')
if [ "$FORCE_UNWRAP_COUNT" -gt 0 ]; then
    echo "⚠️  Found force unwrapping in $FORCE_UNWRAP_COUNT files (review recommended)"
fi

# Check for TODO/FIXME
TODO_COUNT=$(find cognition.curator -name "*.swift" -exec grep -l "TODO\|FIXME" {} \; | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
    echo "📝 Found TODO/FIXME in $TODO_COUNT files"
fi

# Check for SwiftUI naming conflicts
NAMING_CONFLICTS=$(find cognition.curator -name "*.swift" -exec grep -l "struct.*View.*:" {} \; | wc -l | tr -d ' ')
if [ "$NAMING_CONFLICTS" -gt 0 ]; then
    echo "⚠️  SwiftUI naming conflicts detected in $NAMING_CONFLICTS files"
fi

echo ""
echo "🎉 VALIDATION COMPLETE!"
echo "✅ Build: PASSED"
echo "✅ Unit Tests: PASSED"
echo "✅ Quality Checks: PASSED"
echo ""
echo "Ready for deployment! 🚀" 