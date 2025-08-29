# Contributing to Enhanced Bug Bounty Automation

Thank you for your interest in contributing to the Enhanced Bug Bounty Automation project! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug Reports**: Help us identify and fix issues
- **Feature Requests**: Suggest new features or improvements
- **Code Contributions**: Submit bug fixes, new features, or improvements
- **Documentation**: Improve existing documentation or add new guides
- **Module Development**: Create new scanning modules
- **Testing**: Help test the software and report issues

### Getting Started

1. **Fork the Repository**
   ```bash
   git clone https://github.com/Mr-Crazy8/Write_ups.git
   cd Write_ups
   ```

2. **Set Up Development Environment**
   ```bash
   ./install.sh --skip-system-packages  # Install Go tools only
   ./test.sh basic                      # Run basic tests
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Development Guidelines

### Code Style

- **Shell Scripting**: Follow bash best practices
- **Indentation**: Use 4 spaces (no tabs)
- **Comments**: Add comments for complex logic
- **Error Handling**: Always include proper error handling
- **Functions**: Keep functions focused and well-named

### Example Code Style
```bash
# Good: Clear function with error handling
validate_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        log "ERROR" "Domain parameter is required"
        return 1
    fi
    
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$ ]]; then
        log "ERROR" "Invalid domain format: $domain"
        return 1
    fi
    
    return 0
}
```

### Module Development

When creating new modules, follow the module interface:

```bash
#!/bin/bash

# Module metadata
MODULE_NAME="your_module"
MODULE_VERSION="1.0.0"
MODULE_DESCRIPTION="Description of your module"
MODULE_AUTHOR="Your Name"
MODULE_DEPENDENCIES=()
MODULE_REQUIRED_TOOLS=("tool1" "tool2")

# Source the module interface
source "$(dirname "${BASH_SOURCE[0]}")/../module_interface.sh"

# Implement required functions
module_init() { ... }
module_check() { ... }
module_execute() { ... }
module_cleanup() { ... }
module_status() { ... }
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
./test.sh

# Run specific test suites
./test.sh basic
./test.sh config
./test.sh modules
./test.sh performance
```

### Adding Tests

When adding new features, include appropriate tests:

```bash
# Add test function to test.sh
test_your_feature() {
    # Test implementation
    "$MAIN_SCRIPT" -t example.com --your-feature -n >/dev/null 2>&1
}

# Register test in run_all_tests()
run_test "Your feature description" test_your_feature
```

## 📋 Pull Request Process

### Before Submitting

1. **Test Your Changes**
   ```bash
   ./test.sh                    # Run full test suite
   ./bug_bounty_automation.sh -t example.com -n  # Test basic functionality
   ```

2. **Check Code Quality**
   ```bash
   # Check shell script syntax
   shellcheck bug_bounty_automation.sh
   
   # Test module syntax
   bash -n modules/*//*.sh
   ```

3. **Update Documentation**
   - Update README.md if adding new features
   - Add inline code comments
   - Update configuration examples if needed

### Pull Request Template

Please include the following information in your pull request:

```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested my changes locally
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Checklist
- [ ] My code follows the code style of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
```

## 🐛 Bug Reports

### Before Reporting

1. **Search Existing Issues**: Check if the bug has already been reported
2. **Test Latest Version**: Ensure you're using the latest version
3. **Minimal Reproduction**: Create a minimal example that reproduces the issue

### Bug Report Template

```markdown
## Bug Description
A clear and concise description of what the bug is.

## Steps to Reproduce
1. Run command: `./bug_bounty_automation.sh -t example.com ...`
2. Expected behavior
3. Actual behavior

## Environment
- OS: [e.g., Ubuntu 22.04]
- Shell: [e.g., bash 5.1]
- Script Version: [e.g., 3.0.0]
- Go Version: [e.g., 1.19]

## Additional Context
- Error messages
- Log files
- Configuration used
```

## 💡 Feature Requests

### Before Requesting

1. **Check Existing Issues**: Look for similar feature requests
2. **Consider Scope**: Ensure the feature fits the project's goals
3. **Think About Implementation**: Consider how it might be implemented

### Feature Request Template

```markdown
## Feature Description
A clear and concise description of the feature you'd like to see.

## Use Case
Describe the problem this feature would solve or the workflow it would improve.

## Proposed Solution
Describe how you envision this feature working.

## Alternatives Considered
Describe any alternative solutions or features you've considered.

## Implementation Notes
Any technical considerations or suggestions for implementation.
```

## 🔧 Module Development

### Creating New Modules

1. **Create Module Directory**
   ```bash
   mkdir -p modules/your_module
   ```

2. **Implement Module Interface**
   ```bash
   cp examples/custom_module_example.sh modules/your_module/your_module.sh
   ```

3. **Test Module Standalone**
   ```bash
   ./modules/your_module/your_module.sh example.com ./test_output
   ```

4. **Integrate with Main Script**
   - Add module to the main script's module loading logic
   - Update documentation

### Module Guidelines

- **Single Responsibility**: Each module should have a clear, focused purpose
- **Error Handling**: Handle errors gracefully and provide meaningful messages
- **Configuration**: Use the configuration system for customizable options
- **Output Consistency**: Follow established output formats and file naming
- **Dependencies**: Clearly document required tools and dependencies

## 📚 Documentation

### Documentation Standards

- **Clarity**: Write clear, concise documentation
- **Examples**: Include practical examples
- **Completeness**: Cover all features and options
- **Accuracy**: Keep documentation up-to-date with code changes

### Areas Needing Documentation

- Installation guides for different platforms
- Advanced configuration examples
- Troubleshooting guides
- Performance tuning tips
- Security best practices

## 🛡️ Security Considerations

### Responsible Development

- **Input Validation**: Always validate user input
- **Command Injection**: Prevent command injection vulnerabilities
- **Privilege Escalation**: Avoid unnecessary privilege requirements
- **Data Protection**: Handle sensitive data appropriately

### Security Review Process

- All contributions involving security features undergo additional review
- Penetration testing may be required for security-critical changes
- Follow secure coding practices

## 🏷️ Release Process

### Version Numbering

We follow Semantic Versioning (SemVer):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. Update version number in script
2. Update CHANGELOG.md
3. Run full test suite
4. Update documentation
5. Create release notes
6. Tag release

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For general questions and discussion
- **Pull Request Reviews**: For code-related discussions

### Response Times

- **Bug Reports**: We aim to respond within 48 hours
- **Feature Requests**: We aim to respond within 1 week
- **Pull Requests**: We aim to review within 1 week

## 🙏 Recognition

### Contributors

All contributors will be recognized in:
- README.md contributors section
- Release notes
- Git commit history

### Types of Recognition

- **Code Contributors**: Listed in main contributors section
- **Documentation**: Special mention for documentation improvements
- **Testing**: Recognition for significant testing contributions
- **Bug Reports**: Credit for significant bug discoveries

## 📜 Code of Conduct

### Our Standards

- **Respectful**: Be respectful in all interactions
- **Inclusive**: Welcome all contributors regardless of background
- **Constructive**: Provide constructive feedback
- **Professional**: Maintain professional communication

### Unacceptable Behavior

- Harassment or discrimination
- Spam or off-topic content
- Personal attacks
- Disclosure of private information

### Enforcement

Project maintainers have the right to remove comments, commits, code, and other contributions that do not align with this Code of Conduct.

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Enhanced Bug Bounty Automation! 🚀