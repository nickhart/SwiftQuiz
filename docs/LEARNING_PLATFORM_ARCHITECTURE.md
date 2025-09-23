# Learning Platform Architecture Plan

## Vision Statement
Transform SwiftQuiz from a Swift-specific quiz app into a general-purpose learning platform that tracks knowledge mastery at the question level, provides adaptive learning recommendations, and supports multiple subjects while maintaining educational effectiveness.

## Core Philosophy: Question-Centric Learning Analytics

### Learning Science Principles
- **Mastery-Based Progression**: Track concept understanding, not quiz completion
- **Spaced Repetition**: Re-surface missed questions at optimal intervals
- **Adaptive Questioning**: Focus on weak areas, maintain strong areas
- **Granular Progress Tracking**: Question-level performance over time

### Data Strategy
- **Atomic Unit**: Individual question performance (existing UserAnswer entities)
- **Aggregation**: Roll up to topic → category → subject mastery
- **Analytics Focus**: Learning gaps, retention, velocity, recommendations

## Data Architecture

### Entity Relationship Design

```
Subject (Swift, Python, Math, History, etc.)
├── SubjectVersion (Swift 5.10, Swift 6.2, Python 3.11, etc.)
├── Category (Language Fundamentals, OOP, Data Structures, etc.)
│   ├── Topic (Optionals, Generics, Recursion, etc.)
│   │   ├── Question (enhanced existing entity)
│   │   ├── LearningResource (tutorials, documentation, videos)
│   │   └── UserProgress (question mastery over time)
│   └── CategoryProgress (aggregate category performance)
└── Achievement (badges, milestones, streaks)
```

### CoreData Entity Specifications

#### Subject
```swift
// Enables multi-subject learning platform
@NSManaged var id: String           // "swift", "python", "math"
@NSManaged var name: String         // "Swift Programming"
@NSManaged var displayName: String  // "Swift"
@NSManaged var description: String  // "iOS and macOS development language"
@NSManaged var iconName: String     // SF Symbol name
@NSManaged var color: String        // Hex color code
@NSManaged var isActive: Bool       // Feature flag for subjects
@NSManaged var sortOrder: Int16     // Display ordering
@NSManaged var metadata: Data?      // JSON for subject-specific config

// Relationships
@NSManaged var versions: NSSet      // → SubjectVersion
@NSManaged var categories: NSSet    // → Category
@NSManaged var questions: NSSet     // → Question
```

#### SubjectVersion
```swift
// Handles versioning (Swift 5.10 vs 6.2, Python 3.11 vs 3.12)
@NSManaged var id: String           // "swift-6.2", "python-3.12"
@NSManaged var version: String      // "6.2", "3.12"
@NSManaged var name: String         // "Swift 6.2"
@NSManaged var releaseDate: Date
@NSManaged var isLatest: Bool       // Current/recommended version
@NSManaged var isSupported: Bool    // Still maintained
@NSManaged var changelog: String?   // What's new

// Relationships
@NSManaged var subject: Subject
@NSManaged var questions: NSSet     // → Question
```

#### Category
```swift
// Broad learning areas (Language Fundamentals, OOP, etc.)
@NSManaged var id: String           // "swift-fundamentals"
@NSManaged var name: String         // "Language Fundamentals"
@NSManaged var description: String  // "Basic Swift syntax and concepts"
@NSManaged var sortOrder: Int16     // Display ordering
@NSManaged var iconName: String?    // SF Symbol
@NSManaged var color: String?       // Category color theme
@NSManaged var isCore: Bool         // Essential vs advanced categories
@NSManaged var parentCategory: Category?  // Hierarchical categories

// Relationships
@NSManaged var subject: Subject
@NSManaged var childCategories: NSSet    // → Category
@NSManaged var topics: NSSet             // → Topic (many-to-many)
@NSManaged var questions: NSSet          // → Question
```

#### Topic
```swift
// Specific learning concepts (Optionals, Generics, etc.)
@NSManaged var id: String           // "swift-optionals"
@NSManaged var name: String         // "Optionals"
@NSManaged var description: String  // "Handling nil values safely"
@NSManaged var difficulty: Int16    // 1-5 difficulty scale
@NSManaged var estimatedTime: Int16 // Minutes to master
@NSManaged var sortOrder: Int16     // Learning sequence
@NSManaged var isCore: Bool         // Essential vs advanced
@NSManaged var metadata: Data?      // JSON for topic-specific data

// Relationships
@NSManaged var categories: NSSet    // → Category (many-to-many, topics can span categories)
@NSManaged var questions: NSSet     // → Question (many-to-many)
@NSManaged var resources: NSSet     // → LearningResource
@NSManaged var prerequisites: NSSet // → Topic (self-referencing many-to-many)
@NSManaged var dependents: NSSet    // → Topic (inverse of prerequisites)
```

#### Enhanced Question Entity
```swift
// Existing entity enhanced for multi-subject support
@NSManaged var id: String           // Existing
@NSManaged var question: String?    // Existing
@NSManaged var answer: String?      // Existing
@NSManaged var explanation: String? // Existing
@NSManaged var type: String?        // Existing (multiple_choice, short_answer, etc.)
@NSManaged var difficulty: Int16    // Existing
@NSManaged var contentHash: String? // Existing
@NSManaged var sourceTitle: String? // Existing
@NSManaged var sourceURL: String?   // Existing

// New multi-subject fields
@NSManaged var subject: Subject     // Link to subject
@NSManaged var version: SubjectVersion? // Link to version
@NSManaged var category: Category   // Primary category (existing enhanced)
@NSManaged var estimatedTime: Int16 // Seconds to answer
@NSManaged var bloomsLevel: Int16   // 1-6 (remember, understand, apply, analyze, evaluate, create)
@NSManaged var metadata: Data?      // Subject-specific question data

// Enhanced relationships
@NSManaged var topics: NSSet        // → Topic (many-to-many, questions can span topics)
@NSManaged var userAnswers: NSSet   // → UserAnswer (existing, enhanced)
@NSManaged var resources: NSSet     // → LearningResource
```

#### LearningResource
```swift
// Links to tutorials, documentation, videos, etc.
@NSManaged var id: String           // UUID
@NSManaged var title: String        // "Optional Binding Tutorial"
@NSManaged var description: String? // Brief description
@NSManaged var url: String          // Link to resource
@NSManaged var type: String         // documentation, tutorial, video, interactive, book
@NSManaged var difficulty: Int16    // 1-5 difficulty level
@NSManaged var estimatedTime: Int16 // Minutes to complete
@NSManaged var isOfficial: Bool     // Apple docs vs community content
@NSManaged var rating: Double       // User rating 0-5
@NSManaged var language: String?    // "en", "es", etc.
@NSManaged var dateAdded: Date
@NSManaged var lastVerified: Date?  // When link was last checked

// Relationships
@NSManaged var topic: Topic         // Primary topic
@NSManaged var questions: NSSet     // → Question (many-to-many)
```

#### UserProgress
```swift
// Granular tracking of question-level mastery over time
@NSManaged var id: String           // UUID
@NSManaged var questionId: String   // Link to question
@NSManaged var userId: String       // Future: multi-user support, for now "default"
@NSManaged var firstAttempt: Date   // When first encountered
@NSManaged var lastAttempt: Date    // Most recent attempt
@NSManaged var totalAttempts: Int16 // Number of times attempted
@NSManaged var correctAttempts: Int16 // Number of correct answers
@NSManaged var currentStreak: Int16 // Consecutive correct answers
@NSManaged var longestStreak: Int16 // Best streak achieved
@NSManaged var masteryLevel: Double // 0-1 confidence in mastery
@NSManaged var lastMasteryUpdate: Date // When mastery was recalculated
@NSManaged var needsReview: Bool    // Flagged for spaced repetition
@NSManaged var nextReviewDate: Date? // When to surface again

// Spaced repetition algorithm state
@NSManaged var repetitionInterval: Int32 // Days until next review
@NSManaged var easinessFactor: Double    // SM-2 algorithm state
@NSManaged var repetitionNumber: Int16   // How many times reviewed

// Relationships
@NSManaged var question: Question
@NSManaged var userAnswers: NSSet   // → UserAnswer (all attempts)
```

#### Enhanced UserAnswer
```swift
// Existing entity with analytics enhancements
@NSManaged var answer: String?      // Existing
@NSManaged var isCorrect: Bool      // Existing
@NSManaged var timestamp: Date      // Existing
@NSManaged var questionID: String?  // Existing
@NSManaged var interactionType: String? // Existing (answered, skipped)

// New analytics fields
@NSManaged var timeSpent: Int16     // Seconds spent on question
@NSManaged var hintsUsed: Int16     // Number of hints requested
@NSManaged var confidence: Int16    // User's confidence level 1-5
@NSManaged var difficulty: Int16    // User's perceived difficulty 1-5
@NSManaged var sessionId: String?   // Link to quiz session
@NSManaged var deviceType: String?  // iOS, macOS for analytics

// Relationships
@NSManaged var question: Question   // Existing
@NSManaged var userProgress: UserProgress // Link to progress tracking
```

#### Achievement
```swift
// Badges, milestones, and gamification
@NSManaged var id: String           // "swift-fundamentals-mastery"
@NSManaged var name: String         // "Swift Fundamentals Expert"
@NSManaged var description: String  // "Mastered all fundamental concepts"
@NSManaged var iconName: String     // SF Symbol name
@NSManaged var type: String         // mastery, streak, milestone, special
@NSManaged var tier: String         // bronze, silver, gold, platinum
@NSManaged var points: Int16        // Point value
@NSManaged var isEarned: Bool       // User has achieved this
@NSManaged var earnedDate: Date?    // When achieved
@NSManaged var progress: Double     // 0-1 progress toward achievement
@NSManaged var isHidden: Bool       // Secret achievements

// Requirements (JSON metadata)
@NSManaged var requirements: Data   // Achievement criteria
@NSManaged var metadata: Data?      // Additional data

// Relationships
@NSManaged var subject: Subject?    // Subject-specific achievements
@NSManaged var category: Category?  // Category-specific achievements
@NSManaged var topic: Topic?        // Topic-specific achievements
```

## Implementation Phases

### Phase 1: Core Data Migration (Week 1)
1. **Design new CoreData model** - Add all new entities
2. **Create migration plan** - Preserve existing UserAnswer data
3. **Import Swift subject data** - Categorize existing questions into new taxonomy
4. **Test data integrity** - Ensure no data loss during migration

### Phase 2: Analytics Foundation (Week 2)
1. **Build UserProgress tracking** - Question-level mastery calculations
2. **Implement spaced repetition** - SM-2 algorithm for review scheduling
3. **Create category aggregation** - Roll up question performance to topics/categories
4. **Design analytics queries** - CoreData fetch requests for insights

### Phase 3: UI Integration (Week 3)
1. **Connect analytics views** - Replace hardcoded data with real calculations
2. **Build mastery dashboard** - Topic strength visualization
3. **Create recommendation engine** - Suggest questions/resources based on gaps
4. **Implement achievement system** - Badge earning and progress tracking

### Phase 4: Learning Features (Week 4)
1. **Adaptive question selection** - Focus on weak areas
2. **Resource recommendation** - Link learning materials to struggling topics
3. **Study streak tracking** - Daily engagement metrics
4. **Progress visualization** - Charts showing learning over time

### Phase 5: Platform Expansion (Future)
1. **Multi-subject support** - Add Python, JavaScript, etc.
2. **Content management** - Tools for importing new question sets
3. **Versioning system** - Handle language/framework updates
4. **Community features** - User-contributed content

## Technical Considerations

### Data Migration Strategy
- **Backwards Compatible** - Existing Swift questions work unchanged
- **Gradual Enhancement** - Add new features without breaking existing functionality
- **Fallback Support** - Handle missing category/topic data gracefully
- **Performance Optimized** - Efficient CoreData relationships and indexes

### Analytics Architecture
- **Real-time Updates** - Progress tracking updates immediately after each answer
- **Efficient Aggregation** - Pre-calculated category/topic scores for fast UI
- **Privacy Focused** - All data stored locally with optional CloudKit sync
- **Extensible Metrics** - Easy to add new analytics without schema changes

### Future Platform Features
- **Question Import System** - JSON format for community-contributed content
- **Version Management** - Handle Swift 6.2 vs 5.10 question variants
- **Achievement Engine** - Flexible badge system for any subject
- **Learning Path Generator** - AI-recommended study sequences
- **Progress Sharing** - Export achievements and mastery reports

## Success Metrics

### Learning Effectiveness
- **Mastery Improvement** - Users show measurable progress in weak topics
- **Retention Rates** - Knowledge maintained over time (spaced repetition success)
- **Engagement Quality** - Time spent learning vs. gaming the system
- **Resource Utilization** - Users access recommended learning materials

### Platform Growth
- **Subject Expansion** - Successfully add non-Swift subjects
- **Content Scaling** - Community-contributed question quality and quantity
- **User Adoption** - Platform grows beyond Swift developer niche
- **Educational Impact** - Measurable learning outcomes across subjects

This architecture positions SwiftQuiz to become a comprehensive learning platform while maintaining its focus on effective, data-driven education.