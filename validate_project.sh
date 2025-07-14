#!/bin/bash

echo "🔍 Validating CognitionCurator iOS Project..."
echo "=============================================="

# Check if Xcode project exists
if [ -d "CognitionCurator.xcodeproj" ]; then
    echo "✅ Xcode project directory exists"
else
    echo "❌ Xcode project directory missing"
    exit 1
fi

# Check if project.pbxproj exists
if [ -f "CognitionCurator.xcodeproj/project.pbxproj" ]; then
    echo "✅ project.pbxproj exists"
else
    echo "❌ project.pbxproj missing"
    exit 1
fi

# Check if workspace exists
if [ -f "CognitionCurator.xcodeproj/project.xcworkspace/contents.xcworkspacedata" ]; then
    echo "✅ Xcode workspace exists"
else
    echo "❌ Xcode workspace missing"
    exit 1
fi

# Count Swift files
SWIFT_COUNT=$(find CognitionCurator -name "*.swift" | wc -l)
echo "✅ Found $SWIFT_COUNT Swift files"

# Check for required files
REQUIRED_FILES=(
    "CognitionCurator/CognitionCuratorApp.swift"
    "CognitionCurator/ContentView.swift"
    "CognitionCurator/PersistenceController.swift"
    "CognitionCurator/Info.plist"
    "CognitionCurator/Views/HomeView.swift"
    "CognitionCurator/Views/DecksView.swift"
    "CognitionCurator/Views/ReviewView.swift"
    "CognitionCurator/Views/ProgressView.swift"
    "CognitionCurator/Services/FlashcardAPIService.swift"
    "CognitionCurator/Services/SpacedRepetitionService.swift"
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
if [ -f "CognitionCurator/CognitionCurator.xcdatamodeld/CognitionCurator.xcdatamodel/contents" ]; then
    echo "✅ Core Data model exists"
else
    echo "❌ Core Data model missing"
    exit 1
fi

# Check Assets
if [ -d "CognitionCurator/Assets.xcassets" ]; then
    echo "✅ Assets catalog exists"
else
    echo "❌ Assets catalog missing"
    exit 1
fi

echo ""
echo "🎉 Project validation completed successfully!"
echo "📱 You can now open CognitionCurator.xcodeproj in Xcode"
echo ""
echo "Next steps:"
echo "1. Open CognitionCurator.xcodeproj in Xcode 16.3+"
echo "2. Select a simulator or device"
echo "3. Press Cmd+R to build and run"
echo "" 