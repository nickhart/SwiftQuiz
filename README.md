# SwiftQuiz
A daily quiz on Swift programming topics

# SwiftQuiz

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Xcode Version](https://img.shields.io/badge/Xcode-15.4-blue)](https://developer.apple.com/xcode/)
[![iOS Minimum](https://img.shields.io/badge/iOS-16.0%2B-lightgrey)](https://developer.apple.com/ios/)

A daily quiz app to help you stay sharp on Swift programming concepts and language fundamentals. Built with SwiftUI, CoreData, and XcodeGen.

---

## 🚀 Requirements

- macOS 13.0+
- Xcode 15.4
- Swift 5.9
- Homebrew

---

## 🧪 Quickstart

### ✅ One-liner setup

```sh
./scripts/setup.sh
```

Installs dependencies, generates the project, installs pre-commit hooks, and verifies setup.

### 🛠 Manual steps

```sh
brew bundle
xcodegen
open SwiftQuiz.xcodeproj
```

---

## 🧰 Scripts in `./scripts/`

| Script | Description |
|--------|-------------|
| `lint.sh` | Runs SwiftLint |
| `format.sh` | Checks format (add `--fix` to auto-fix) |
| `test.sh` | Runs unit tests by default, add `--ui` for UI tests or `--all` |
| `build.sh` | Builds the app |
| `setup.sh` | Installs all dev tools, hooks, and generates the project |
| `pre-commit.sh` | Script invoked by pre-commit hook |
| `ci.sh` | Uses GitHub CLI to monitor/check CI runs |
| `preflight.sh` | Runs a full local CI-style check |
| `simulator.sh` | Lists and configures iOS simulators for testing |

---

## 🤝 Contributing

We welcome contributions! To get started:

1. Fork the repo
2. Make your changes
3. Submit a pull request or open an issue for discussion

---

## ✅ TODO

See [TODO.md](TODO.md) for project progress and future ideas.

---

## 📄 License

Copyright © 2025 Nick Hart
Licensed under the MIT License.