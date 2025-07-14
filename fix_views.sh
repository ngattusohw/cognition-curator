#!/bin/bash

echo "🔧 Fixing system color and UIKit import issues..."

# Function to fix a single file
fix_file() {
    local file="$1"
    echo "Fixing $file..."
    
    # Add UIKit import if not present
    if ! grep -q "import UIKit" "$file"; then
        # Add UIKit import after SwiftUI import
        sed -i '' 's/import SwiftUI/import SwiftUI\nimport UIKit/' "$file"
    fi
    
    # Fix system color references
    sed -i '' 's/Color(\.systemGroupedBackground)/Color(uiColor: .systemGroupedBackground)/g' "$file"
    sed -i '' 's/Color(\.systemBackground)/Color(uiColor: .systemBackground)/g' "$file"
    sed -i '' 's/Color(\.systemGray6)/Color(uiColor: .systemGray6)/g' "$file"
    sed -i '' 's/Color(\.systemGray5)/Color(uiColor: .systemGray5)/g' "$file"
    
    # Fix LinearProgressViewStyle
    sed -i '' 's/LinearProgressViewStyle(tint: \.blue)/LinearProgressViewStyle()/g' "$file"
    
    echo "✅ Fixed $file"
}

# Fix all view files
fix_file "cognition.curator/cognition.curator/Views/AddCardView.swift"
fix_file "cognition.curator/cognition.curator/Views/CreateDeckView.swift"
fix_file "cognition.curator/cognition.curator/Views/DeckDetailView.swift"
fix_file "cognition.curator/cognition.curator/Views/DeckRowView.swift"
fix_file "cognition.curator/cognition.curator/Views/DecksView.swift"
fix_file "cognition.curator/cognition.curator/Views/EditDeckView.swift"
fix_file "cognition.curator/cognition.curator/Views/HomeView.swift"
fix_file "cognition.curator/cognition.curator/Views/ProgressView.swift"

echo "🎉 All view files fixed!" 