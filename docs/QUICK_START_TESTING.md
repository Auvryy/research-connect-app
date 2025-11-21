# Quick Start Guide - Testing the Fixed Authentication System

## Prerequisites
1. Python 3.8+ installed
2. Flutter 3.0+ installed
3. Android Emulator or iOS Simulator running
4. Git (to check current state)

## Step 1: Start the Backend Server

### Navigate to backend directory:
```bash
cd "c:/Users/Admin/OneDrive/Documents/5-Web-Development/4-Projects/Research_Connect/backend"
```

### Make sure dependencies are installed:
```bash
pip install -r requirements.txt
```

### Start the Flask server:
```bash
python app.py
```

**Expected Output:**
```
Running on host: http://0.0.0.0:5000
```

**Verify backend is running:**
- Open browser to http://localhost:5000/api/user/debug (if debug endpoint exists)
- Or use: `curl http://localhost:5000/api/user/login` (should get 405 Method Not Allowed for GET)

Keep this terminal open!

## Step 2: Start the Flutter App

### Open a new terminal and navigate to Flutter project:
```bash
cd "c:/Users/Admin/OneDrive/Documents/5-Web-Development/4-Projects/inquira"
```

### Get Flutter dependencies:
```bash
flutter pub get
```

### Check for any issues:
```bash
flutter doctor
```

### Run the app on Android emulator:
```bash
flutter run
```

**Or specify device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

## Step 3: Test the Authentication Flow

### Test Registration:
1. App should open to login page (or redirect there via AuthGuard)
2. Click "Register" link at bottom
3. Enter a username (4-36 characters): `testuser123`
4. Enter a strong password (8+ chars, uppercase, lowercase, digit, special char): `Test@123`
5. Confirm password: `Test@123`
6. Check "I agree to terms" checkbox
7. Click "Register" button
8. **Expected**: Success message, redirect to login page
9. **Backend log should show**: "Registered successfully"

### Test Login:
1. On login page, enter username: `testuser123`
2. Enter password: `Test@123`
3. Click "Login" button
4. **Expected**: 
   - Success message
   - Redirect to home feed
   - User data loaded (check Flutter console for logs)
5. **Backend log should show**: "Login Successful"

### Test Session Persistence:
1. With app running, press `r` in terminal for hot reload
2. **Expected**: User stays logged in
3. Stop app completely (press `q` in terminal)
4. Restart app: `flutter run`
5. **Expected**: App opens directly to home (skips login)
6. **Flutter console should show**: "AuthGuard: User session found"

### Test Survey Creation (to verify user ID is working):
1. From home page, tap the "Add" button (bottom nav)
2. Create a new survey with title, description, etc.
3. Add at least one question
4. Submit the survey
5. Navigate to Profile page (bottom nav)
6. Tap "My Surveys" tab
7. **Expected**: Your new survey appears in the list
8. **Flutter console should show**: Survey created with your user ID

### Test Logout:
1. From home page, tap "Settings" button (bottom nav)
2. Scroll to bottom
3. Tap "Log Out" button
4. Confirm logout in dialog
5. **Expected**:
   - Redirect to login page
   - All user data cleared
6. Try to navigate back (shouldn't be able to)
7. **Backend log should show**: "User has logged out"

### Test Auto Token Refresh (Advanced):
This happens automatically. To verify:
1. Login to app
2. Keep app running for several minutes (or adjust token expiration in backend to 1 minute for testing)
3. Try creating a survey or loading profile
4. **Expected**: Works seamlessly (token refreshed in background)
5. **Flutter console should show**: "Token refreshed successfully" (if token expired)

## Common Issues and Solutions

### Issue 1: "Failed to connect" or "DioError: Connection refused"
**Cause**: Backend not running or wrong URL
**Solution**:
- Make sure backend is running (`python app.py`)
- Check baseUrl in `lib/data/api/dio_client.dart` is correct
- For Android emulator, must use `10.0.2.2:5000` not `localhost:5000`
- For iOS simulator, use `localhost:5000` or `127.0.0.1:5000`

### Issue 2: Registration fails with "Username already exists"
**Cause**: User already registered
**Solution**:
- Use a different username
- Or reset the database (set `RESET = True` in backend/app.py, restart, then set back to False)

### Issue 3: Login succeeds but no user data
**Cause**: `/login_success` endpoint not being called
**Solution**:
- Check Flutter console for errors
- Verify backend `/login_success` endpoint is working
- Check cookies are being saved (should see in DioClient logs)

### Issue 4: User logged out unexpectedly
**Cause**: Token expired or cookies cleared
**Solution**:
- Check backend token expiration settings
- Verify cookies directory has proper permissions
- Check for error logs in Flutter console

### Issue 5: "SharedPreferences initialization failed"
**Cause**: Platform doesn't support SharedPreferences
**Solution**:
- App will use in-memory storage as fallback
- Data won't persist between app restarts
- This is rare, mostly on web platform

## Debugging Tips

### Enable verbose logging:
All key operations are already logged. Watch the Flutter console for:
- `AuthAPI.login: Starting login...`
- `DioClient: Making POST request to...`
- `AuthGuard: User session found...`
- `SurveyService: Saving survey...`

### Check backend logs:
Backend logs authentication events. Watch for:
- "Login Succesful"
- "Registered successfully"
- "User has logged out"
- Any error messages

### Inspect SharedPreferences:
Add temporary code to print stored data:
```dart
final prefs = await SharedPreferences.getInstance();
print('User ID: ${prefs.getInt('user_id')}');
print('Username: ${prefs.getString('username')}');
```

### Check cookies:
Cookies are stored in `<app_documents>/.cookies/`
You can see cookie logs in DioClient output.

## Quick Test Checklist

Run through these tests in order:

- [ ] Backend starts successfully
- [ ] Flutter app starts successfully  
- [ ] Registration with valid credentials works
- [ ] Registration validation catches invalid input
- [ ] Login with registered credentials works
- [ ] Home page displays correctly
- [ ] User data visible in profile
- [ ] Survey creation saves with user ID
- [ ] Survey appears in "My Surveys"
- [ ] App restart preserves login session
- [ ] Logout clears all data
- [ ] After logout, can't access protected pages
- [ ] Can login again after logout

## Network Configuration

### For Android Emulator:
```dart
// lib/data/api/dio_client.dart
baseUrl: 'http://10.0.2.2:5000/api/user'
```

### For iOS Simulator:
```dart
// lib/data/api/dio_client.dart
baseUrl: 'http://localhost:5000/api/user'
// or
baseUrl: 'http://127.0.0.1:5000/api/user'
```

### For Physical Device:
```dart
// lib/data/api/dio_client.dart
baseUrl: 'http://YOUR_COMPUTER_IP:5000/api/user'
// Example: 'http://192.168.1.100:5000/api/user'
```

**To find your IP:**
- Windows: `ipconfig` → look for IPv4 Address
- Mac/Linux: `ifconfig` → look for inet address

## Backend Rate Limiting

The backend has rate limits:
- Registration: 2 per minute, 30 per hour, 200 per day
- Login: 2 per minute, 30 per hour, 200 per day  
- Logout: 2 per minute, 30 per hour, 200 per day

If you hit the limit during testing, wait a minute before retrying.

## Success Indicators

✅ **Registration Success:**
- Flutter console: "Account created successfully!"
- Backend log: "Registered successfully"
- Redirects to login page

✅ **Login Success:**
- Flutter console: "Login successful. Current user: testuser123"
- Backend log: "Login Succesful"
- Navigates to home feed

✅ **Session Persistence:**
- Flutter console: "AuthGuard: User session found"
- App opens to home (not login)

✅ **Logout Success:**
- Flutter console: "AuthAPI.logout: User info cleared"
- Backend log: "User has logged out"
- Redirects to login page

## Next Steps After Testing

Once basic auth is working:
1. Implement profile editing
2. Add OAuth (Google) login
3. Implement password reset
4. Add profile picture upload
5. Connect surveys to backend API (currently local only)
6. Add survey sharing functionality
7. Implement survey responses/analytics

## Support

If you encounter issues:
1. Check AUTHENTICATION_GUIDE.md for detailed documentation
2. Review Flutter console logs
3. Review backend logs
4. Check that all dependencies are installed
5. Verify network configuration matches your setup

Happy testing! 🚀
