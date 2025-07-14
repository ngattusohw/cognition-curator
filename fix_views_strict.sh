#!/bin/bash

echo "🔧 Strictly fixing UIKit color and import issues in all view files..."

fix_file() {
    local file="$1"
    echo "Fixing $file..."
    # Add UIKit import if not present
    if ! grep -q "import UIKit" "$file"; then
        sed -i '' 's/import SwiftUI/import SwiftUI\nimport UIKit/' "$file"
    fi
    # Use UIColor explicitly
    sed -i '' 's/Color(uiColor: \.systemGroupedBackground)/Color(uiColor: UIColor.systemGroupedBackground)/g' "$file"
    sed -i '' 's/Color(uiColor: \.systemBackground)/Color(uiColor: UIColor.systemBackground)/g' "$file"
    sed -i '' 's/Color(uiColor: \.systemGray6)/Color(uiColor: UIColor.systemGray6)/g' "$file"
    sed -i '' 's/Color(uiColor: \.systemGray5)/Color(uiColor: UIColor.systemGray5)/g' "$file"
}

for file in cognition.curator/cognition.curator/Views/*.swift; do
    fix_file "$file"
done

echo "🎉 All view files strictly fixed!" 