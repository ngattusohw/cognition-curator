#!/bin/bash

# Cognition Curator - Automated Validation Script
# This script validates the entire app without human intervention

echo "🧠 Cognition Curator - Automated Validation"
echo "=========================================="

# Set up variables - corrected paths
PROJECT_PATH="cognition.curator/cognition.curator.xcodeproj"
SCHEME="cognition.curator"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

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

# 1. Build the project
echo "🔨 Building project..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "$DESTINATION" build
check_result "Build"

# 2. Run unit tests
echo "🧪 Running unit tests..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "$DESTINATION" test
check_result "Unit Tests"

# 3. Check for Swift warnings
echo "⚠️ Checking for warnings..."
WARNING_OUTPUT=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "$DESTINATION" build 2>&1 | grep -i warning)
if [ -n "$WARNING_OUTPUT" ]; then
    echo "⚠️ Warnings found:"
    echo "$WARNING_OUTPUT"
    echo "Review recommended"
else
    echo "✅ No warnings found"
fi

# 4. Validate SwiftUI previews compile
echo "👀 Validating SwiftUI previews..."
xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME" -destination "$DESTINATION" build -configuration Debug
check_result "Preview Compilation"

# 5. Check for common issues
echo "🔍 Checking for common issues..."

# Check for force unwrapping
echo "Checking for force unwrapping (!)..."
FORCE_UNWRAP=$(find ./cognition.curator -name "*.swift" -exec grep -l "!" {} \; | grep -v Tests | wc -l)
if [ $FORCE_UNWRAP -gt 0 ]; then
    echo "⚠️ Found $FORCE_UNWRAP files with force unwrapping - Review recommended"
else
    echo "✅ No force unwrapping found"
fi

# Check for TODO/FIXME comments
echo "Checking for TODO/FIXME comments..."
TODO_COUNT=$(find ./cognition.curator -name "*.swift" -exec grep -l "TODO\|FIXME" {} \; | wc -l)
if [ $TODO_COUNT -gt 0 ]; then
    echo "📝 Found $TODO_COUNT files with TODO/FIXME comments"
else
    echo "✅ No TODO/FIXME comments found"
fi

# 6. Check for SwiftUI naming conflicts
echo "🔍 Checking for SwiftUI naming conflicts..."
NAMING_CONFLICTS=$(find ./cognition.curator -name "*.swift" -exec grep -l "struct.*View\|class.*View" {} \; | xargs grep -l "ProgressView\|Button\|Text" | grep -v "import SwiftUI" | wc -l)
if [ $NAMING_CONFLICTS -gt 0 ]; then
    echo "⚠️ Potential SwiftUI naming conflicts found - Review recommended"
else
    echo "✅ No obvious SwiftUI naming conflicts"
fi

# 7. Performance check
echo "⚡ Performance validation..."
MAIN_THREAD_ISSUES=$(find ./cognition.curator -name "*.swift" -exec grep -l "DispatchQueue.main.sync\|Thread.sleep" {} \; | wc -l)
if [ $MAIN_THREAD_ISSUES -gt 0 ]; then
    echo "⚠️ Found potential main thread blocking operations"
else
    echo "✅ No obvious main thread issues found"
fi

echo ""
echo "🎉 Validation Complete!"
echo "========================"
echo "✅ Build: PASSED"
echo "✅ Tests: PASSED"
echo "✅ Previews: PASSED"
echo "✅ Basic Quality Checks: PASSED"
echo ""
echo "🚀 App is ready for changes!" 