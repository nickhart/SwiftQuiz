# Learning Content Format Specification v1.0

## Overview
This document defines a standardized JSON format for educational content that supports multi-subject learning platforms with granular analytics, adaptive questioning, and learning resource integration.

## Design Goals
- **Subject Agnostic**: Support any learning domain (programming, math, science, languages)
- **Analytics Ready**: Track learning at question/topic/category levels
- **Adaptive Learning**: Enable spaced repetition and prerequisite tracking
- **Resource Integration**: Link questions to tutorials, documentation, videos
- **Version Support**: Handle evolving subjects (Swift 5.10 → 6.2, Python 3.11 → 3.12)
- **Community Friendly**: Publishable format for content creators

## Subject Taxonomy File

Each subject requires a taxonomy definition file: `{subject}_taxonomy.json`

```json
{
  "subject": {
    "id": "swift",
    "name": "Swift Programming",
    "displayName": "Swift",
    "description": "Apple's programming language for iOS, macOS, and server development",
    "iconName": "swift",
    "color": "#FA7343",
    "isActive": true,
    "currentVersion": "6.0"
  },
  "versions": [
    {
      "id": "swift-6.0",
      "version": "6.0",
      "name": "Swift 6.0",
      "releaseDate": "2024-09-16",
      "isLatest": true,
      "isSupported": true,
      "changelog": "Introduced strict concurrency checking and data race safety"
    },
    {
      "id": "swift-5.10",
      "version": "5.10",
      "name": "Swift 5.10",
      "releaseDate": "2024-03-05",
      "isLatest": false,
      "isSupported": true
    }
  ],
  "categories": [
    {
      "id": "language-fundamentals",
      "name": "Language Fundamentals",
      "description": "Core Swift syntax, types, and basic concepts",
      "sortOrder": 1,
      "iconName": "textformat.abc",
      "color": "#007AFF",
      "isCore": true
    },
    {
      "id": "object-oriented-programming",
      "name": "Object-Oriented Programming",
      "description": "Classes, inheritance, protocols, and encapsulation",
      "sortOrder": 2,
      "iconName": "building.columns",
      "isCore": true
    },
    {
      "id": "memory-management",
      "name": "Memory Management",
      "description": "ARC, weak references, and memory safety",
      "sortOrder": 3,
      "isCore": true
    },
    {
      "id": "concurrency",
      "name": "Concurrency",
      "description": "Async/await, actors, and concurrent programming",
      "sortOrder": 4,
      "isCore": false
    }
  ],
  "topics": [
    {
      "id": "optionals",
      "name": "Optionals",
      "description": "Handling nil values safely with optional types",
      "categories": ["language-fundamentals"],
      "difficulty": 2,
      "estimatedTime": 15,
      "isCore": true,
      "prerequisites": ["variables-constants"],
      "sortOrder": 5
    },
    {
      "id": "optional-binding",
      "name": "Optional Binding",
      "description": "Safely unwrapping optionals with if-let and guard-let",
      "categories": ["language-fundamentals"],
      "difficulty": 3,
      "estimatedTime": 20,
      "isCore": true,
      "prerequisites": ["optionals"],
      "sortOrder": 6
    },
    {
      "id": "memory-safety",
      "name": "Memory Safety",
      "description": "Preventing memory leaks and dangling pointers",
      "categories": ["memory-management", "language-fundamentals"],
      "difficulty": 4,
      "estimatedTime": 25,
      "isCore": true,
      "prerequisites": ["optionals", "classes"],
      "sortOrder": 15
    }
  ],
  "learningResources": [
    {
      "id": "swift-book-optionals",
      "title": "The Swift Programming Language - Optionals",
      "description": "Official Swift documentation on optional types",
      "url": "https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html#ID330",
      "type": "documentation",
      "difficulty": 2,
      "estimatedTime": 10,
      "isOfficial": true,
      "language": "en",
      "topics": ["optionals", "optional-binding"]
    }
  ]
}
```

## Question Content File

Questions are stored in: `{subject}_questions.json`

```json
{
  "formatVersion": "1.0",
  "subject": "swift",
  "lastUpdated": "2024-01-15T10:30:00Z",
  "questions": [
    {
      "id": "swift-optionals-001",
      "question": "What keyword is used to declare an optional type in Swift?",
      "answer": "?",
      "explanation": "The question mark (?) is appended to a type to make it optional, allowing it to hold either a value of that type or nil.",
      "type": "short_answer",
      "category": "language-fundamentals",
      "topics": ["optionals"],
      "subjectVersion": "6.0",
      "difficulty": 1,
      "bloomsLevel": 1,
      "estimatedTime": 30,
      "choices": null,
      "tags": ["syntax", "basics"],
      "learningResources": ["swift-book-optionals"],
      "metadata": {
        "codeExample": "var optionalString: String? = \"Hello\"",
        "hasCodeSample": true
      }
    },
    {
      "id": "swift-optionals-002",
      "question": "Which of the following safely unwraps an optional?",
      "answer": "if let value = optionalValue { }",
      "explanation": "Optional binding with 'if let' safely unwraps an optional and assigns the value to a constant if it's not nil.",
      "type": "multiple_choice",
      "category": "language-fundamentals",
      "topics": ["optionals", "optional-binding"],
      "subjectVersion": "6.0",
      "difficulty": 2,
      "bloomsLevel": 2,
      "estimatedTime": 45,
      "choices": [
        "optionalValue!",
        "if let value = optionalValue { }",
        "optionalValue??",
        "unwrap(optionalValue)"
      ],
      "tags": ["unwrapping", "safety"],
      "learningResources": ["swift-book-optionals"],
      "metadata": {
        "codeExample": "if let value = optionalValue {\n    print(value)\n}",
        "hasCodeSample": true,
        "commonMistakes": ["Force unwrapping with !", "Using ?? incorrectly"]
      }
    },
    {
      "id": "swift-memory-001",
      "question": "Explain the difference between strong, weak, and unowned references in Swift ARC.",
      "answer": "Strong references keep objects in memory, weak references don't prevent deallocation and become nil, unowned references don't prevent deallocation but assume the object exists.",
      "explanation": "ARC uses reference counting. Strong references increment the count, weak references don't but can become nil, unowned references don't increment count and assume the referenced object exists.",
      "type": "freeform",
      "category": "memory-management",
      "topics": ["memory-safety", "arc"],
      "subjectVersion": "6.0",
      "difficulty": 4,
      "bloomsLevel": 4,
      "estimatedTime": 120,
      "choices": null,
      "tags": ["memory", "arc", "references"],
      "learningResources": ["arc-documentation"],
      "metadata": {
        "requiresCodeExample": true,
        "keyPoints": ["Reference counting", "Retain cycles", "Memory safety"]
      }
    }
  ]
}
```

## Field Specifications

### Question Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier: `{subject}-{topic}-{number}` |
| `question` | string | Yes | The question text |
| `answer` | string | Yes | Correct answer or sample answer |
| `explanation` | string | Yes | Detailed explanation of the correct answer |
| `type` | enum | Yes | `multiple_choice`, `short_answer`, `freeform`, `code_completion` |
| `category` | string | Yes | Primary category ID from taxonomy |
| `topics` | string[] | Yes | Array of topic IDs (1+ topics) |
| `subjectVersion` | string | No | Version this question applies to |
| `difficulty` | integer | Yes | 1-5 scale (1=beginner, 5=expert) |
| `bloomsLevel` | integer | Yes | 1-6 Bloom's Taxonomy (1=remember, 6=create) |
| `estimatedTime` | integer | Yes | Seconds to answer |
| `choices` | string[] | No | Multiple choice options (required if type=multiple_choice) |
| `tags` | string[] | No | Additional searchable tags |
| `learningResources` | string[] | No | IDs of related learning resources |
| `metadata` | object | No | Subject-specific additional data |

### Question Types

- **`multiple_choice`**: Single correct answer from provided choices
- **`short_answer`**: Brief text response (1-2 words/phrases)
- **`freeform`**: Longer explanatory response (paragraphs)
- **`code_completion`**: Fill in missing code
- **`debugging`**: Find and fix code errors
- **`true_false`**: Boolean response

### Difficulty Scale

1. **Beginner**: Basic recall, simple concepts
2. **Novice**: Understanding with guidance
3. **Intermediate**: Independent application
4. **Advanced**: Complex analysis and synthesis
5. **Expert**: Innovation and teaching others

### Bloom's Taxonomy Levels

1. **Remember**: Recall facts, definitions
2. **Understand**: Explain concepts, summarize
3. **Apply**: Use knowledge in new situations
4. **Analyze**: Break down information, compare
5. **Evaluate**: Judge value, critique
6. **Create**: Design, construct, produce

## Publishing Guidelines

### File Naming Convention
- Taxonomy: `{subject}_taxonomy.json`
- Questions: `{subject}_questions.json`
- Example: `swift_taxonomy.json`, `typescript_questions.json`

### Version Control
- Use semantic versioning for format changes
- Include `formatVersion` field in all files
- Maintain backwards compatibility within major versions

### Quality Standards
- Minimum 3 learning resources per topic
- Questions must include detailed explanations
- Code examples should be tested and accurate
- Difficulty progression should be logical

### Community Contribution
- GitHub repository with standardized structure
- Validation schemas for automated testing
- Contributor guidelines and review process
- Attribution system for content creators

## Example Subjects

### Programming Languages
- **Swift**: iOS/macOS development
- **TypeScript**: Web development with types
- **Python**: General programming and data science
- **Rust**: Systems programming
- **Go**: Backend services

### Computer Science
- **Data Structures**: Arrays, trees, graphs
- **Algorithms**: Sorting, searching, dynamic programming
- **Databases**: SQL, NoSQL, design patterns

### Mathematics
- **Calculus**: Derivatives, integrals, limits
- **Statistics**: Probability, distributions, hypothesis testing
- **Linear Algebra**: Matrices, vectors, transformations

### Science
- **Physics**: Mechanics, thermodynamics, electromagnetism
- **Chemistry**: Atomic structure, reactions, organic chemistry
- **Biology**: Cell biology, genetics, evolution

## Implementation Notes

### Import Process
1. Parse taxonomy file to create Subject/Category/Topic entities
2. Import questions with proper relationships
3. Create UserProgress entities for tracking
4. Validate referential integrity

### Analytics Capabilities
- Question-level mastery tracking
- Topic/category performance aggregation
- Spaced repetition scheduling
- Learning resource recommendations
- Progress visualization

### Extensibility
- Custom metadata per subject
- Subject-specific question types
- Configurable difficulty scales
- Pluggable analytics algorithms

This format enables building comprehensive learning platforms across any domain while maintaining consistency and enabling powerful analytics.