#!/bin/bash

# Cognition Curator - Comprehensive Validation Script
# This script provides thorough validation with minimal false positives

echo "🧠 Cognition Curator - Comprehensive Validation"
echo "=============================================="

# Check if project exists
if [ ! -d "cognition.curator" ]; then
    echo "❌ Project directory not found"
    exit 1
fi

echo "📁 Found project directory"
cd cognition.curator

# Step 1: Actual Build Test (Most Important!)
echo "🔨 Building project..."
BUILD_OUTPUT=$(xcodebuild -project cognition.curator.xcodeproj -scheme cognition.curator -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1)
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✅ Build - PASSED"
else
    echo "❌ Build - FAILED"
    echo "Build errors:"
    echo "$BUILD_OUTPUT" | grep -E "(error:|warning:)" | head -10
    exit 1
fi

# Step 2: Unit Tests
echo "🧪 Running unit tests..."
TEST_OUTPUT=$(xcodebuild test -project cognition.curator.xcodeproj -scheme cognition.curator -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1)
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Unit Tests - PASSED"
    # Extract test count
    TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -E "Test case.*passed" | wc -l | tr -d ' ')
    echo "   → $TEST_COUNT tests passed"
else
    echo "❌ Unit Tests - FAILED"
    echo "Test failures:"
    echo "$TEST_OUTPUT" | grep -E "(failed|error)" | head -5
    exit 1
fi

# Step 3: Critical Issue Detection
echo "🔍 Checking for critical issues..."

# Check for actual SwiftUI naming conflicts (specific ones)
NAMING_CONFLICTS=0
for conflict in "struct ProgressView" "struct Button" "struct Text" "struct Image" "struct List"; do
    if find . -name "*.swift" -exec grep -l "$conflict" {} \; 2>/dev/null | grep -q .; then
        echo "❌ Found SwiftUI naming conflict: $conflict"
        NAMING_CONFLICTS=$((NAMING_CONFLICTS + 1))
    fi
done

if [ $NAMING_CONFLICTS -eq 0 ]; then
    echo "✅ SwiftUI Naming Conflicts - NONE"
else
    echo "❌ SwiftUI Naming Conflicts - $NAMING_CONFLICTS found"
    exit 1
fi

# Check for deprecated LinearProgressViewStyle usage
DEPRECATED_PROGRESS=$(find . -name "*.swift" -exec grep -l "LinearProgressViewStyle" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$DEPRECATED_PROGRESS" -gt 0 ]; then
    echo "❌ Found deprecated LinearProgressViewStyle usage in $DEPRECATED_PROGRESS files"
    exit 1
else
    echo "✅ ProgressView Style Usage - CORRECT"
fi

# Check for risky force unwrapping patterns (excluding safe contexts)
RISKY_UNWRAPS=$(find . -name "*.swift" -exec grep -E "\[[^]]*\]!" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$RISKY_UNWRAPS" -gt 0 ]; then
    echo "⚠️  Found $RISKY_UNWRAPS potentially risky force unwraps (review recommended)"
else
    echo "✅ Force Unwrapping - SAFE"
fi

# Check for empty action blocks that should be implemented
EMPTY_ACTIONS=$(find . -name "*.swift" -exec grep -l "action: {[\s]*}" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$EMPTY_ACTIONS" -gt 0 ]; then
    echo "⚠️  Found $EMPTY_ACTIONS empty action blocks (implementation needed)"
fi

# Step 4: Code Quality Checks
echo "📊 Code quality checks..."

# Check for TODO/FIXME (informational)
TODO_COUNT=$(find . -name "*.swift" -exec grep -l "TODO\|FIXME" {} \; 2>/dev/null | wc -l | tr -d ' ')
if [ "$TODO_COUNT" -gt 0 ]; then
    echo "📝 TODO/FIXME items: $TODO_COUNT files"
fi

# Check deployment target warnings
if echo "$BUILD_OUTPUT" | grep -q "deployment target.*is set to.*but the range"; then
    echo "⚠️  Deployment target warning detected (review project settings)"
fi

echo ""
echo "🎉 VALIDATION COMPLETE!"
echo "✅ Build: PASSED"
echo "✅ Tests: PASSED ($TEST_COUNT tests)"
echo "✅ Critical Issues: NONE"
echo ""

if [ "$TODO_COUNT" -gt 0 ] || [ "$RISKY_UNWRAPS" -gt 0 ] || [ "$EMPTY_ACTIONS" -gt 0 ]; then
    echo "⚠️  Minor issues found (see above) - review recommended"
else
    echo "🚀 All checks passed - Ready for deployment!"
fi