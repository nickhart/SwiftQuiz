# SwiftQuiz Coding Standards

## Inclusive Language Rules
- ❌ Never use "master" - use "main", "primary", "expert", "proficient" instead
- ❌ Never use "slave" - use "secondary", "follower", "replica" instead
- ❌ Never use "whitelist/blacklist" - use "allowlist/blocklist" instead

## File Organization (per SwiftLint file_types_order)
1. Import statements
2. Type aliases
3. Enums
4. Structs
5. Classes
6. Extensions
7. Free functions

## SwiftLint Rules to Follow
- Use trailing commas in multiline collections
- Prefer `.isEmpty` over `.count == 0`
- Use `Self` over `type(of: self)`
- Put `get` before `set` in computed properties
- Use `[weak self]` in closures unless lifetime guaranteed
- File names should match primary type
- No redundant type annotations where inference works
- Use `.toggle()` on Bool instead of `= !`

## Code Style
- 4-space indentation
- 120 character line width
- Required `self` in closures for clarity
- Explicit init only when needed for clarity

## Comments
- Only add comments when explicitly requested
- TODOs should include context: `TODO: [Context] Description`