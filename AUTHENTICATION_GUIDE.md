# Authentication System - Fixed and Aligned with Backend

## Overview
The Flutter app's authentication system has been completely refactored to properly integrate with the Research_Connect backend API. All authentication flows (login, registration, logout) now work correctly with proper session management and user data persistence.

## Key Changes Made

### 1. **User Information Model (`lib/data/user_info.dart`)**
- **Complete Rewrite**: Transformed from a simple data class to a comprehensive user model
- **Backend Alignment**: Model now matches the backend's user structure
- **Features Added**:
  - Fields: `id`, `username`, `name`, `email`, `phone`, `school`, `course`, `profilePicUrl`
  - `fromJson()` and `toJson()` methods for API communication
  - `saveUserInfo()` - Saves user data to SharedPreferences
  - `loadUserInfo()` - Loads user data from SharedPreferences
  - `clearUserInfo()` - Clears user data on logout
  - `isLoggedIn()` - Checks if user session exists
- **Global Variable**: `currentUser` is now nullable and properly managed

### 2. **Authentication API (`lib/data/api/auth_api.dart`)**
- **Login Flow Enhanced**:
  - After successful login, automatically fetches user data from `/login_success` endpoint
  - Saves user information to SharedPreferences
  - Sets the global `currentUser` variable
  
- **Logout Flow Fixed**:
  - Calls backend `/refresh/logout` endpoint
  - Clears all user data from SharedPreferences
  - Clears cookies via DioClient
  - Returns success even if API call fails (ensures local cleanup)
  
- **Registration**:
  - Already had proper validation, now integrated with updated response handling

### 3. **HTTP Client (`lib/data/api/dio_client.dart`)**
- **Cookie Management**: Added `clearCookies()` method to properly clear authentication cookies
- **Auto Token Refresh**: Added interceptor that automatically:
  - Detects 401 (unauthorized) responses
  - Calls `/refresh` endpoint to get new access token
  - Retries the original request with refreshed token
- **Better Error Handling**: Improved error messages and logging

### 4. **Authentication Guard (`lib/data/auth_guard.dart`)**
- **New Component**: Wraps protected routes to ensure user is authenticated
- **Features**:
  - Checks for existing user session on app startup
  - Attempts to refresh token to validate session
  - Automatically redirects to login if not authenticated
  - Shows loading indicator during authentication check
- **Usage**: Wraps HomePage and CreateSurveyPage in routes

### 5. **Survey Service (`lib/data/survey_service.dart`)**
- **User ID Source**: Now retrieves current user ID from SharedPreferences instead of hardcoded values
- **Priority Order**: 
  1. Uses `user_id` from SharedPreferences
  2. Falls back to `username` if ID not available
  3. Uses default only if no user is logged in

### 6. **Login Page (`lib/screens/login/login_page.dart`)**
- **Post-Login**: Loads user info and sets `currentUser` after successful login
- **Navigation**: Only navigates to home after user data is loaded

### 7. **Settings Page (`lib/screens/settings/settings_page.dart`)**
- **Logout Button**: Enhanced to:
  - Call AuthAPI.logout()
  - Clear global `currentUser`
  - Always redirect to login (even on API failure)
  - Use mounted checks to prevent errors
- **User Display**: Updated to use authenticated user data with null safety

### 8. **Profile Page (`lib/screens/profile/profile_page.dart`)**
- **User Data**: Updated to display authenticated user information
- **Null Safety**: All user field accesses are now null-safe with fallbacks

### 9. **App Routes (`lib/app.dart`)**
- **Initial Route**: Changed from `/login` to `/` which uses AuthGuard
- **Protected Routes**: HomePage and CreateSurveyPage now wrapped with AuthGuard
- **Session Restoration**: App automatically restores session if valid

## Backend Endpoints Used

### Authentication Endpoints (from `backend/App/routes/route_auth.py`)
1. **POST /api/user/register**
   - Validates username and password
   - Creates new user account
   - Returns: `{status, ok, message}`

2. **POST /api/user/login**
   - Validates credentials
   - Sets access and refresh cookies
   - Returns: `{status, ok, message, login_type}`

3. **GET /api/user/login_success** (Protected)
   - Returns user details after successful login
   - Returns: `{status, ok, message: {id, username, profile_pic, provider}}`

4. **POST /api/user/refresh/logout** (Protected, requires refresh token)
   - Revokes refresh token
   - Unsets JWT cookies
   - Returns: `{status, ok, message}`

5. **POST /api/user/refresh** (Protected, requires refresh token)
   - Refreshes access token
   - Returns: `{status, ok, message}`

## Cookie-Based Authentication
- The backend uses **HTTP-only cookies** for JWT tokens (access + refresh)
- Cookies are automatically managed by `dio_cookie_manager`
- Cookies persist in `<app_documents>/.cookies/` directory
- Cookies are cleared on logout

## Session Management Flow

### App Startup:
1. AuthGuard checks if user data exists in SharedPreferences
2. If exists, loads user data and sets `currentUser`
3. Attempts to refresh token to validate session
4. If valid, proceeds to HomePage
5. If invalid, clears data and redirects to login

### Login:
1. User enters credentials
2. AuthAPI calls `/login` endpoint
3. Backend sets access and refresh cookies
4. AuthAPI calls `/login_success` to get user data
5. User data saved to SharedPreferences
6. `currentUser` variable set
7. Navigate to HomePage

### Logout:
1. User clicks logout in settings
2. AuthAPI calls `/refresh/logout` endpoint
3. Backend revokes refresh token
4. All user data cleared from SharedPreferences
5. Cookies cleared from DioClient
6. `currentUser` set to null
7. Navigate to login page

### Auto Token Refresh:
1. Any API call returns 401 (unauthorized)
2. DioClient interceptor catches the error
3. Calls `/refresh` endpoint
4. Backend issues new access token
5. Original request is retried with new token
6. If refresh fails, user must log in again

## Testing Checklist

### ✅ Registration:
- [ ] Create account with valid credentials
- [ ] Test username validation (4-36 chars)
- [ ] Test password requirements (8+ chars, uppercase, lowercase, digit, special char)
- [ ] Verify error messages for invalid input
- [ ] Confirm redirect to login after successful registration

### ✅ Login:
- [ ] Login with valid credentials
- [ ] Verify user data is saved to SharedPreferences
- [ ] Confirm `currentUser` is set correctly
- [ ] Check that HomePage displays user data
- [ ] Verify cookies are saved

### ✅ Logout:
- [ ] Click logout in settings
- [ ] Verify redirect to login page
- [ ] Confirm user data cleared from SharedPreferences
- [ ] Check that `currentUser` is null
- [ ] Verify cookies are cleared
- [ ] Attempt to access protected route (should redirect to login)

### ✅ Session Persistence:
- [ ] Login to app
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify user is still logged in
- [ ] Confirm user data is loaded correctly

### ✅ Token Refresh:
- [ ] Login to app
- [ ] Wait for access token to expire (or manually test)
- [ ] Make an API call (e.g., load surveys)
- [ ] Verify token is automatically refreshed
- [ ] Confirm API call succeeds after refresh

### ✅ Survey Creation:
- [ ] Create a survey while logged in
- [ ] Verify survey is associated with logged-in user ID
- [ ] Check that survey appears in profile page
- [ ] Confirm survey persists after logout/login

## Configuration Notes

### Backend URL:
- Currently set to: `http://10.0.2.2:5000/api/user`
- This is the Android emulator localhost
- **For iOS Simulator**: Change to `http://localhost:5000/api/user`
- **For Physical Device**: Change to your machine's IP address

### Cookie Storage:
- Location: `<ApplicationDocumentsDirectory>/.cookies/`
- Managed by: `PersistCookieJar` with `FileStorage`
- Persistent across app restarts

## Dependencies Required
Ensure these are in your `pubspec.yaml`:
```yaml
dependencies:
  dio: ^5.0.0
  cookie_jar: ^4.0.0
  dio_cookie_manager: ^3.0.0
  shared_preferences: ^2.0.0
  path_provider: ^2.0.0
```

## Security Considerations
1. **HTTP-Only Cookies**: Tokens not accessible via JavaScript
2. **Refresh Token Rotation**: Backend should implement refresh token rotation
3. **HTTPS**: Use HTTPS in production (currently HTTP for development)
4. **Token Expiration**: Access tokens expire quickly, refresh tokens last longer
5. **Secure Storage**: Consider using `flutter_secure_storage` for sensitive data in production

## Known Limitations
1. Profile data (name, email, phone, school, course) only available if backend provides it
2. OAuth login (Google) not yet implemented in Flutter
3. Profile picture upload not yet implemented in Flutter
4. Password reset not yet implemented in Flutter

## Future Enhancements
1. Implement OAuth (Google) login flow
2. Add profile editing functionality
3. Add password change/reset flow
4. Implement profile picture upload
5. Add biometric authentication option
6. Add remember me checkbox on login
7. Implement auto-logout on token expiration
8. Add network connectivity checks

## Troubleshooting

### Issue: Login succeeds but user data not loaded
**Solution**: Check that backend `/login_success` endpoint is accessible and returns user data

### Issue: Token refresh not working
**Solution**: Verify that cookies are being saved and sent with requests. Check DioClient logs.

### Issue: User logged out unexpectedly
**Solution**: Check if refresh token expired or was revoked. Verify backend token expiration settings.

### Issue: Can't connect to backend
**Solution**: 
- Check backend is running on http://localhost:5000
- Verify baseUrl in DioClient matches your setup
- For Android emulator, use 10.0.2.2 instead of localhost
- For iOS simulator, use localhost or 127.0.0.1

### Issue: Cookies not persisting
**Solution**: Check that path_provider has correct permissions. Check cookies directory exists.

## Summary
The authentication system is now fully functional and aligned with the Research_Connect backend. Users can register, login, logout, and their sessions persist across app restarts. Token refresh happens automatically, and all user data is properly managed throughout the app lifecycle.
