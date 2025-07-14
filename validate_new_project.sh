#!/bin/bash

echo "🔍 Validating New Cognition.curator iOS Project..."
echo "=================================================="

# Check if new Xcode project exists
if [ -d "cognition.curator" ]; then
    echo "✅ New Xcode project directory exists"
else
    echo "❌ New Xcode project directory missing"
    exit 1
fi

# Check if project.pbxproj exists
if [ -f "cognition.curator/cognition.curator.xcodeproj/project.pbxproj" ]; then
    echo "✅ project.pbxproj exists"
else
    echo "❌ project.pbxproj missing"
    exit 1
fi

# Count Swift files in new project
SWIFT_COUNT=$(find "cognition.curator/cognition.curator" -name "*.swift" | wc -l)
echo "✅ Found $SWIFT_COUNT Swift files"

# Check for required files
REQUIRED_FILES=(
    "cognition.curator/cognition.curator/cognition_curatorApp.swift"
    "cognition.curator/cognition.curator/ContentView.swift"
    "cognition.curator/cognition.curator/PersistenceController.swift"
    "cognition.curator/cognition.curator/Views/HomeView.swift"
    "cognition.curator/cognition.curator/Views/DecksView.swift"
    "cognition.curator/cognition.curator/Views/ReviewView.swift"
    "cognition.curator/cognition.curator/Views/ProgressView.swift"
    "cognition.curator/cognition.curator/Services/FlashcardAPIService.swift"
    "cognition.curator/cognition.curator/Services/SpacedRepetitionService.swift"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check Core Data model
if [ -d "cognition.curator/cognition.curator/CognitionCurator.xcdatamodeld" ]; then
    echo "✅ Core Data model exists"
else
    echo "❌ Core Data model missing"
    exit 1
fi

# Check Assets
if [ -d "cognition.curator/cognition.curator/Assets.xcassets" ]; then
    echo "✅ Assets catalog exists"
else
    echo "❌ Assets catalog missing"
    exit 1
fi

echo ""
echo "🎉 New project validation completed successfully!"
echo "📱 You can now open cognition.curator.xcodeproj in Xcode"
echo ""
echo "Next steps:"
echo "1. Open cognition.curator/cognition.curator.xcodeproj in Xcode"
echo "2. Add all Swift files to the project (if not already added)"
echo "3. Select a simulator or device"
echo "4. Press Cmd+R to build and run"
echo ""
echo "Note: You may need to add the Swift files to the Xcode project manually"
echo "if they don't appear in the project navigator."
echo "" 