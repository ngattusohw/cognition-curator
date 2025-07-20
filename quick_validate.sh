#!/bin/bash

# Cognition Curator - Quick Validation Script
# Fast validation with real compilation but no unit tests

echo "⚡ Cognition Curator - Quick Validation"
echo "======================================"

# Check if project exists
if [ ! -d "cognition.curator" ]; then
    echo "❌ Project directory not found"
    exit 1
fi

echo "📁 Found project directory"
cd cognition.curator

# Step 1: Quick Build Test (Most Important!)
echo "🔨 Quick build check..."
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

# Step 2: Critical Issue Detection
echo "🔍 Checking for critical issues..."

# Check for actual SwiftUI naming conflicts
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

echo ""
echo "⚡ QUICK VALIDATION COMPLETE!"
echo "✅ Build: PASSED"
echo "✅ Critical Issues: NONE"
echo ""
echo "🚀 Ready for testing! (Run ./validate_app.sh for full validation with tests)"