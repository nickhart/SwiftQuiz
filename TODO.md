

# ✅ SwiftQuiz Project TODOs

## ✅ Core Data
- [x] Define `Question` and `UserAnswer` models
- [x] Add `Tag` entity for better filtering (optional, future)
- [x] Set up `PersistenceController` with `inMemory` support for previews

## ✅ Question Import
- [x] Create `CodableQuestion` model
- [x] Implement `QuestionImportService`
- [x] Add synchronous import method for use in previews
- [x] Generate sample question JSON

## ✅ Question Views
- [x] Create `QuestionCardView`
- [x] Implement `BoolQuestionView`
- [x] Implement `MultipleChoiceQuestionView`
- [x] Implement `ShortAnswerQuestionView`
- [x] Implement `FreeformQuestionView`

## ✅ UI + Navigation
- [x] Hook up `QuestionCardView` in `ContentView`
- [x] Add Next / Dismiss / Snooze buttons
- [x] Add question cycling logic with `@FetchRequest`

## ⏳ Quiz Features
- [ ] Quiz scorecard
- [ ] User statistics + visualizations
- [ ] Recommendations (eg: areas to focus/improve upon)
- [ ] Badges / achievements
- [ ] Filtering questions by tag or difficulty
- [ ] OpenAI integration for evaluating freeform answers

## ⏳ Build + Dev Experience
- [x] Add `project.yml` for XcodeGen
- [ ] Add `Makefile` or shell script for build/test
- [ ] Add SwiftLint / formatting hooks
- [ ] Add GitHub Actions or CI config