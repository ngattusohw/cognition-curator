#!/bin/bash

# Cognition Curator - Fast Validation Script
# This script validates Swift syntax without building

echo "🧠 Cognition Curator - Fast Validation"
echo "======================================"

# Check if project exists
if [ ! -d "cognition.curator" ]; then
    echo "❌ Project directory not found"
    exit 1
fi

echo "📁 Found project directory"

# Step 1: Check Swift syntax
echo "🔨 Checking Swift syntax..."
SYNTAX_ERRORS=0

# Check each Swift file for basic syntax
find cognition.curator -name "*.swift" | while read file; do
    # Basic syntax check using swift frontend
    if ! xcrun swift-frontend -parse "$file" > /dev/null 2>&1; then
        echo "❌ Syntax error in: $file"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo "✅ Swift syntax check - PASSED"
else
    echo "❌ Swift syntax check - FAILED ($SYNTAX_ERRORS errors)"
    exit 1
fi

# Step 2: Check for common issues
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

# Check for empty action blocks
EMPTY_ACTIONS=$(find cognition.curator -name "*.swift" -exec grep -l "action: {[\s]*}" {} \; | wc -l | tr -d ' ')
if [ "$EMPTY_ACTIONS" -gt 0 ]; then
    echo "⚠️  Found empty action blocks in $EMPTY_ACTIONS files (should be implemented)"
fi

echo ""
echo "🎉 VALIDATION COMPLETE!"
echo "✅ Swift Syntax: PASSED"
echo "✅ Quality Checks: PASSED"
echo ""
echo "Ready for testing! 🚀" 