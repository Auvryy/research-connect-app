# Inquira Documentation

This folder contains all the documentation for the Inquira survey platform.

## 📚 Table of Contents

### Getting Started
- **[QUICK_START_TESTING.md](QUICK_START_TESTING.md)** - Quick guide to get started with testing the app

### Authentication & OAuth
- **[AUTHENTICATION_GUIDE.md](AUTHENTICATION_GUIDE.md)** - Complete authentication flow documentation
- **[GOOGLE_OAUTH_SETUP.md](GOOGLE_OAUTH_SETUP.md)** - Step-by-step Google OAuth 2.0 configuration

### Survey System
- **[FLUTTER_SURVEY_JSON_FORMAT.md](FLUTTER_SURVEY_JSON_FORMAT.md)** - Complete JSON format guide for survey creation and responses
- **[SURVEY_POST_JSON_STRUCTURE.md](SURVEY_POST_JSON_STRUCTURE.md)** - Survey post JSON structure specification
- **[SURVEY_DATABASE_STRUCTURE.md](SURVEY_DATABASE_STRUCTURE.md)** - Database schema for surveys
- **[SURVEY_SUBMISSION_GUIDE.md](SURVEY_SUBMISSION_GUIDE.md)** - How users submit survey responses
- **[SURVEY_SUBMISSION_EXAMPLE.md](SURVEY_SUBMISSION_EXAMPLE.md)** - Example survey submission data

### Development
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Summary of implemented features
- **[LOCAL_STORAGE_GUIDE.md](LOCAL_STORAGE_GUIDE.md)** - Local storage implementation and usage

## 🎯 Key Features

### Question Types Supported
The platform supports 8 question types:
1. **Short Text** - Single line text input
2. **Long Text** - Multi-line text area
3. **Email** - Email input with validation
4. **Date** - Date picker
5. **Rating** - 1-5 star rating system
6. **Radio Button** - Single choice selection
7. **Checkbox** - Multiple choice selection (with min/max limits)
8. **Dropdown** - Select from dropdown menu

### Rating System
- **Fixed 1-5 Stars**: All rating questions use a consistent 1-5 star scale
- **Integer Response**: Backend receives integer values from 1 to 5
- **Visual Feedback**: Selected stars are highlighted in the UI

### Survey Structure
- **Sections**: Surveys are organized into logical sections
- **Ordering**: Questions and sections have explicit order values
- **Validation**: Required fields, min/max choice for checkboxes
- **Rich Media**: Support for images and videos in questions

## 🔧 For Developers

### Important Files
- Start with **FLUTTER_SURVEY_JSON_FORMAT.md** for API integration
- Review **AUTHENTICATION_GUIDE.md** for auth implementation
- Check **SURVEY_DATABASE_STRUCTURE.md** for database schema

### API Endpoints
- **Survey Creation**: `POST /api/survey/post/send/questionnaire/mobile`
- **Survey Response**: `POST /api/survey/answer/questionnaire/<survey_id>`

### ID Format
- Section IDs: `section-{timestamp}`
- Question IDs: `question-{timestamp}`
- Generated using `DateTime.now().millisecondsSinceEpoch`

## 📝 Notes

- All documentation is kept up-to-date with the current implementation
- JSON examples match actual backend expectations
- Field names and types are consistent across frontend and backend
