# Contributing to DRTDI

Thank you for your interest in contributing to DRTDI! We welcome contributions from the community and are grateful for your help in making this project better.

## 🎯 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Performance Benchmarks](#performance-benchmarks)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Feature Requests](#feature-requests)
- [Bug Reports](#bug-reports)
- [Documentation](#documentation)

## 📜 Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- Be respectful and inclusive
- Exercise consideration and respect in your speech and actions
- Attempt collaboration before conflict
- Refrain from demeaning, discriminatory, or harassing behavior
- Be mindful of your surroundings and fellow participants

## 🚀 Getting Started

### Prerequisites

- **Dart SDK**: Version 3.10.2 or higher
- **Flutter**: Version 3.38.3 or higher (for Flutter examples and tests)
- **Git**: For version control

### Setting Up the Development Environment

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/your-username/drtdi.git
   cd drtdi
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/c0dwiz/drtdi.git
   ```

3. **Install dependencies**
   ```bash
   dart pub get
   ```

## 🛠 Development Setup

### Project Structure

```
drtdi/
├── lib/
│   ├── src/
│   │   ├── core/
│   │   │   ├── container/          # DI container implementations
│   │   │   ├── registration/       # Registration system
│   │   │   ├── resolution/         # Dependency resolution
│   │   │   └── validation/         # Container validation
│   │   ├── interfaces/             # Public interfaces
│   │   ├── exceptions/             # Custom exceptions
│   │   └── utils/                  # Utility classes
│   └── drtdi.dart                 # Main library export
├── test/
│   ├── unit/                      # Unit tests
│   ├── integration/               # Integration tests
│   └── test_utils/                # Test utilities
├── example/                       # Usage examples
├── benchmark/                     # Performance benchmarks
└── documentation/                 # Additional documentation
```

### Branch Strategy

- `main` - Stable release branch
- `develop` - Development branch (default for PRs)
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation improvements

## 🧪 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Groups
```bash
# Run only unit tests
flutter test test/unit/

# Run only integration tests
flutter test test/integration/

# Run tests with specific name
flutter test --name "should resolve transient dependency"
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Coverage Requirements
- Minimum 90% test coverage for new code
- All public APIs must have tests
- Edge cases and error conditions must be tested

## ⚡ Performance Benchmarks

### Run Benchmarks
```bash
dart benchmark/performance_benchmark.dart
```

### Adding New Benchmarks
When adding performance benchmarks:

1. Create a new benchmark class in `benchmark/`
2. Follow the existing benchmark structure
3. Include setup and teardown methods
4. Ensure benchmarks are reproducible
5. Document what the benchmark measures

Example benchmark structure:
```dart
class NewFeatureBenchmark extends BenchmarkBase {
  NewFeatureBenchmark() : super('NewFeature');
  
  late DIContainer container;
  
  @override
  void setup() {
    container = DIContainer();
    // Setup dependencies
  }
  
  @override
  void teardown() {
    container.dispose();
  }
  
  @override
  void run() {
    // Code to benchmark
    container.resolve<SomeService>();
  }
}
```

## 📝 Code Style

### Dart Style Guide
We follow the [Effective Dart](https://dart.dev/effective-dart) style guide.

### Key Style Points

**Naming Conventions:**
- Use `UpperCamelCase` for classes, enums, and type parameters
- Use `lowerCamelCase` for variables, constants, and methods
- Use `_leadingUnderscore` for private members

**Code Organization:**
- One class per file (except for small related classes)
- Group related functionality together
- Use meaningful names that reveal intent

**Documentation:**
- Document all public APIs
- Use DartDoc comments (`///`)
- Include examples for complex functionality

### Formatting
```bash
# Format code
dart format .

# Analyze code
dart analyze
```

### Linting
We use the Dart recommended lints. Ensure your code passes:
```bash
dart analyze
```

## 🔄 Pull Request Process

### 1. Create a Feature Branch
```bash
git checkout -b feature/amazing-feature
```

### 2. Make Your Changes
- Write clear, focused commits
- Include tests for new functionality
- Update documentation
- Ensure all tests pass

### 3. Keep Your Branch Updated
```bash
git fetch upstream
git rebase upstream/develop
```

### 4. Submit Pull Request
- Target the `develop` branch
- Fill out the PR template completely
- Reference any related issues
- Include performance impact analysis if applicable

### PR Template
```markdown
## Description
Brief description of the changes

## Related Issues
Fixes #issue_number

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Added unit tests
- [ ] Added integration tests
- [ ] Manually tested

## Performance Impact
- [ ] No impact
- [ ] Minor improvement
- [ ] Major improvement
- [ ] Performance regression (explain)

## Documentation
- [ ] Updated API documentation
- [ ] Added code examples
- [ ] Updated README
```

## 💡 Feature Requests

We welcome feature requests! Please:

1. Check existing issues to avoid duplicates
2. Use the feature request template
3. Explain the use case and benefits
4. Consider if it aligns with project goals

### Feature Request Template
```markdown
## Problem Statement
What problem are you trying to solve?

## Proposed Solution
How should this feature work?

## Alternatives Considered
What other approaches did you consider?

## Additional Context
Any other relevant information?
```

## 🐛 Bug Reports

### Reporting Bugs
When reporting bugs, please include:

1. **Environment**: Dart/Flutter version, OS
2. **Steps to Reproduce**: Clear, step-by-step instructions
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Code Example**: Minimal code to reproduce the issue
6. **Logs/Screenshots**: Any relevant output

### Bug Report Template
```markdown
## Environment
- Dart SDK Version: [e.g., 2.17.0]
- Flutter Version: [e.g., 3.0.0]
- OS: [e.g., Windows, macOS, Linux]

## Description
[Describe the bug]

## Steps to Reproduce
1. [First Step]
2. [Second Step]
3. [Third Step]

## Expected Behavior
[What you expected to happen]

## Actual Behavior
[What actually happened]

## Code Example
```dart
// Minimal code to reproduce
```

## Additional Context
[Any other information that might be helpful]
```

## 📚 Documentation

### Documentation Standards
- All public APIs must be documented
- Use clear, concise language
- Include code examples
- Document edge cases and limitations

### Updating Documentation
When making code changes that affect:

- **Public API**: Update method/class documentation
- **Behavior**: Update relevant documentation sections
- **Examples**: Update or add new examples
- **README**: Update if functionality changes significantly

### Building Documentation
```bash
# Generate API documentation
dart doc
```

## 🏆 Recognition

Contributors will be recognized in:
- Release notes
- Contributor list in README
- Project documentation

## ❓ Questions?

- Create a discussion in GitHub Discussions
- Open an issue for clarification
- Reach out to maintainers

## 📄 License

By contributing, you agree that your contributions will be licensed under the project's MIT License.

---

Thank you for contributing to DRTDI! Your efforts help make this project better for everyone. 🎉