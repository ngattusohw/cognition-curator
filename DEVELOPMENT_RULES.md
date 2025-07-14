# Cognition Curator - Development Rules

## Core Principle: Maximum AI Agency, Minimum Human Intervention

The goal is to deliver correct, working code on the first attempt, minimizing the need for human debugging and iteration.

## Pre-Delivery Validation Protocol

### MANDATORY: Always validate before presenting solutions
1. **Manual Code Review** - Check for obvious compilation errors
2. **Test critical user paths** - Verify the specific functionality being implemented
3. **Check for common SwiftUI issues** - Naming conflicts, force unwrapping, etc.
4. **Only present solutions after validation**

### Validation Approach (Updated)
- **Primary**: Manual code review and targeted testing
- **Secondary**: Simple build checks when needed
- **Avoid**: Complex automated scripts that depend on simulators (they hang/crash)

## Swift/SwiftUI Specific Rules

### Critical Issues to Always Check
1. **SwiftUI Naming Conflicts** - Custom views shadowing built-in SwiftUI components
2. **Core Data @FetchRequest** - Use proper fetch requests for automatic UI updates
3. **Navigation Bindings** - Pass required @Binding parameters for tab navigation
4. **Force Unwrapping** - Minimize use of `!` operator
5. **Animation State** - Reset animation states when transitioning between views

### Common Patterns That Work
- **TabView Navigation**: Use `@Binding var selectedTab: Int` and `selectedTab = targetIndex`
- **Core Data Updates**: Use `@FetchRequest` instead of direct relationship access
- **Card Flip Animations**: Use scale/opacity instead of 3D rotation to avoid mirrored text
- **Review Flow**: Reset state variables when moving between cards
- **Button Actions**: Always implement actual functionality, never leave empty `{}`

## Architecture Decisions

### Core Data
- Use `@FetchRequest` for automatic UI updates
- Implement cascade delete rules in the data model
- Save context after each significant operation

### Navigation
- TabView with `@State selectedTab` in ContentView
- Pass `selectedTab` binding to child views that need navigation
- Use `selectedTab = index` for programmatic navigation

### State Management
- Use `@State` for local view state
- Use `@Binding` for parent-child communication
- Reset state when transitioning between views/cards

## Testing Strategy

### Manual Testing Focus
- **New Card Creation** - Verify cards appear immediately
- **Review Flow** - Test card flip animations and difficulty selection
- **Navigation** - Test all button actions and tab switching
- **Empty States** - Verify proper handling of no data scenarios

### Automated Testing (When Stable)
- Unit tests for business logic
- Core Data model tests
- Spaced repetition algorithm tests
- **Avoid UI tests** - They're flaky and cause simulator issues

## Development Process

### Before Implementing Changes
1. **Understand the problem** - Search codebase to understand current implementation
2. **Identify root cause** - Don't just fix symptoms
3. **Plan the solution** - Consider all affected files and components
4. **Implement systematically** - Make all related changes together

### After Implementing Changes
1. **Review the code** - Check for obvious issues
2. **Test the specific functionality** - Verify the fix works
3. **Check for regressions** - Ensure existing functionality still works
4. **Document the solution** - Update rules if new patterns emerge

## Key Lessons Learned

### Issues We've Solved
- ✅ **SwiftUI Naming Conflicts** - Renamed custom `ProgressView` to `ProgressStatsView`
- ✅ **Card Display Updates** - Replaced direct Core Data access with `@FetchRequest`
- ✅ **Review Button Navigation** - Implemented proper TabView navigation
- ✅ **Card Flip Animation** - Fixed mirrored text with better animation approach
- ✅ **Empty Button Actions** - Implemented all button functionality

### Validation Approach That Works
- **Manual code review** - Fast and reliable
- **Targeted testing** - Test the specific feature being implemented
- **Incremental validation** - Check each change as you make it
- **Avoid complex automation** - Simulators are unreliable for automated testing

## Success Metrics

### What Good Looks Like
- Code compiles on first try
- Features work as expected immediately
- No empty action blocks or placeholder code
- Proper state management and navigation
- Minimal force unwrapping and potential crashes

### When to Stop
- Feature works as requested
- No obvious compilation errors
- Navigation flows correctly
- State updates properly
- User experience is smooth

This approach maximizes development speed while minimizing debugging cycles and simulator issues. 