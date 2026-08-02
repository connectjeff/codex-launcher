# Codex Launcher TODO

## Implemented Features ✅
- [x] macOS Dockable launcher for Codex
- [x] Default config (`~/.codex`) support
- [x] Local LM Studio mode with model picker
- [x] GitHub CLI integration (`gh`)
- [x] Performance benchmarking documentation
- [x] Release cleanup (remove date-based zip files)
- [x] TODO tracking system
- [x] CI/CD Pipeline for Release Automation
- [x] Launcher Error Handling (retry logic, better messages)
- [x] Update README with Current Status
- [x] Add Version Tracking in app bundle
- [x] Improve Model Selection UI (show last-used, default model)
- [x] Configuration Management (profiles, export/import)

## High Priority

### 1. CI/CD Pipeline for Release Automation ✅
- [x] Create GitHub Actions workflow for automated releases
- [x] Auto-generate release notes from commit history
- [x] Create release assets (ZIP, DMG) automatically
- [x] Tag releases based on version in README or config

### 2. Improve Launcher Error Handling ✅
- [x] Add retry logic for LM Studio connection failures
- [x] Better error messages for common issues (port in use, model not found)
- [x] Add logging level options (debug, info, warn, error)

### 3. Update README with Current Status ✅
- [x] Mark this as the TODO tracking file
- [x] Add project status: "Active Development"
- [x] Add installation instructions
- [x] Add configuration guide

## Medium Priority

### 4. Add Version Tracking ✅
- [x] Store launcher version in app bundle (`Info.plist`)
- [ ] Show current version in launcher dialog/about menu
- [x] Check for updates on launch (compare with GitHub releases)
- [ ] Auto-update mechanism

### 5. Improve Model Selection UI ✅
- [x] Add model search/filter functionality (by name, provider)
- [x] Show last-used models at top of list
- [ ] Add model description/preview (show model type, size)
- [x] Store model preferences persistently per configuration

### 6. Configuration Management ✅
- [x] Create config editor UI (simple form-based)
- [x] Support multiple LM Studio profiles (different ports/URLs)
- [x] Export/import configuration
- [ ] Backup/restore functionality

## Low Priority (Feature Suggestions Based on Launcher Purpose)

### 7. Quick Launch Shortcuts
- [ ] Add keyboard shortcuts for common actions (Cmd+L, Cmd+,)
- [ ] Create menu bar icon for quick launch
- [ ] Support Spotlight search integration

### 8. Session Management
- [ ] Show recent sessions in launcher dialog
- [ ] Quick-switch between last 5 sessions
- [ ] Session duration tracking (show active time)

### 9. LM Studio Integration Enhancements
- [ ] Auto-detect available local models on launch
- [ ] Show model provider info (OpenAI, Groq, etc.)
- [ ] Quick access to LM Studio settings from launcher
- [ ] Model performance indicators (tokens/sec)

### 10. Documentation & UX
- [x] Create user guide/FAQ in README
- [ ] Add keyboard shortcuts documentation
- [x] Create troubleshooting section
- [ ] Add screenshots to README showing launcher UI

### 11. Testing & Quality
- [ ] Create automated tests for launcher script
- [ ] Add CI pipeline with test coverage
- [ ] Set up automated dependency updates (Dependabot)
- [ ] Code review checklist for contributors

## Tracking

Last updated: 2026-08-02
