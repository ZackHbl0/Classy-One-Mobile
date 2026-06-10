# Testing Checklist - Media Handling Fixes

Use this checklist to verify all fixes are working correctly on your STK L21 device.

---

## 📋 Pre-Testing Setup

- [ ] Flutter packages installed: `flutter pub get` completed successfully
- [ ] Laravel backend running at `192.168.100.99:8000`
- [ ] Backend `.env` updated: `APP_URL=http://192.168.100.99:8000`
- [ ] Phone connected to same Wi-Fi network as Laravel server
- [ ] App installed on STK L21 device

---

## 🖼️ Test 1: Image Viewing (React Card)

### Expected Behavior
The React course should contain an image file. Clicking it should open a full-screen image viewer within the app.

### Test Steps
1. [ ] Open app, navigate to "Cours" tab
2. [ ] Locate and tap "react" course card
3. [ ] **VERIFY**: New screen opens with white background
4. [ ] **VERIFY**: Blue AppBar at top with "react" title and back arrow
5. [ ] **VERIFY**: Image loads and displays (not Chrome browser!)
6. [ ] **VERIFY**: URL shown in logs is `192.168.100.99` not `localhost`
7. [ ] **VERIFY**: Loading spinner shows while image downloads
8. [ ] **VERIFY**: Can pinch to zoom in/out on image
9. [ ] **VERIFY**: Can pan around zoomed image with finger
10. [ ] **VERIFY**: Back arrow returns to course list
11. [ ] **VERIFY**: No error toasts appear
12. [ ] **VERIFY**: Chrome browser never opens

### Error Scenarios to Test
- [ ] Turn off Wi-Fi → Should show "Impossible de charger l'image" error
- [ ] Invalid image URL → Should show error with retry option
- [ ] Large image → Should show progress indicator

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 📄 Test 2: PDF Viewing (UML Card)

### Expected Behavior
The UML course should contain a PDF file. Clicking it should download and open the PDF within the app.

### Test Steps
1. [ ] Open app, navigate to "Cours" tab
2. [ ] Locate and tap "UML" course card
3. [ ] **VERIFY**: Loading message shows "Téléchargement du PDF..."
4. [ ] **VERIFY**: New screen opens with white background (not Chrome!)
5. [ ] **VERIFY**: Blue AppBar at top with "UML" title
6. [ ] **VERIFY**: PDF content displays correctly
7. [ ] **VERIFY**: Page counter appears in top-right (e.g., "1/5")
8. [ ] **VERIFY**: Can swipe left to go to next page
9. [ ] **VERIFY**: Can swipe right to go to previous page
10. [ ] **VERIFY**: Page counter updates as you swipe
11. [ ] **VERIFY**: Text in PDF is readable
12. [ ] **VERIFY**: Back arrow returns to course list
13. [ ] **VERIFY**: No "Impossible d'afficher le PDF" toast
14. [ ] **VERIFY**: Chrome browser never opens

### Error Scenarios to Test
- [ ] Turn off Wi-Fi before opening → Should show download error
- [ ] Tap "Réessayer" button → Should retry download
- [ ] Invalid PDF URL → Should show error message

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🎥 Test 3: Video Playing (Algorithm Card)

### Expected Behavior
The Algorithm course should contain a video file. Clicking it should show the NEW clean white launcher screen (not the old dark navy screen), then play the video within the app.

### Test Steps - Part A: Launcher Screen
1. [ ] Open app, navigate to "Cours" tab
2. [ ] Locate and tap "Algorithmique & Structures de Données" card
3. [ ] **VERIFY**: NEW screen opens with **CLEAN WHITE** background (not dark navy!)
4. [ ] **VERIFY**: Blue AppBar at top (not purple gradient)
5. [ ] **VERIFY**: Clean circular play icon with light blue background (not glowing purple)
6. [ ] **VERIFY**: Course title in black text (not white)
7. [ ] **VERIFY**: **NO subtitle text** below title
8. [ ] **VERIFY**: Blue "Ouvrir la vidéo" button (not purple with icon)
9. [ ] **VERIFY**: **NO "Copier le lien" button** (security requirement)
10. [ ] **VERIFY**: Overall design is minimal and clean

### Test Steps - Part B: Video Playback
11. [ ] Tap "Ouvrir la vidéo" button
12. [ ] **VERIFY**: Loading message "Chargement de la vidéo..." appears
13. [ ] **VERIFY**: New screen opens with BLACK background (video player)
14. [ ] **VERIFY**: Blue AppBar at top with video title
15. [ ] **VERIFY**: Video loads and starts playing automatically
16. [ ] **VERIFY**: Video controls visible at bottom (play/pause, seek bar)
17. [ ] **VERIFY**: Can tap play/pause button
18. [ ] **VERIFY**: Can drag seek bar to different position
19. [ ] **VERIFY**: Can tap fullscreen button (if visible)
20. [ ] **VERIFY**: Video plays smoothly without stuttering
21. [ ] **VERIFY**: Back arrow returns to white launcher screen
22. [ ] **VERIFY**: Back arrow again returns to course list
23. [ ] **VERIFY**: No Chrome browser opens at any point
24. [ ] **VERIFY**: No localhost connection error

### Error Scenarios to Test
- [ ] Turn off Wi-Fi → Should show "Impossible de charger la vidéo" error
- [ ] Invalid video URL → Should show error with "Retour" button
- [ ] Unsupported format → Should show appropriate error message

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 📱 Test 4: Bottom Navigation Bar

### Expected Behavior
All 6 navigation items should display correctly without overflow errors on your STK L21 device.

### Test Steps
1. [ ] Open app to home screen
2. [ ] **VERIFY**: Bottom nav bar displays all 6 icons clearly
3. [ ] **VERIFY**: No "BOTTOM OVERFLOWED BY 5.5 PIXELS" error
4. [ ] **VERIFY**: Active tab shows blue glow dot + label
5. [ ] **VERIFY**: Inactive tabs show only icon (no label)
6. [ ] Tap "Accueil" (Home) tab
   - [ ] Icon animates with bounce effect
   - [ ] Blue glow dot appears
   - [ ] Label appears below dot
7. [ ] Tap "Agenda" (Planning) tab
   - [ ] Previous tab's label fades out
   - [ ] New tab's label fades in
   - [ ] Blue glow moves to new tab
8. [ ] Tap "Cours" (Courses) tab
   - [ ] Navigation works smoothly
   - [ ] Label "Cours" displays fully (no truncation)
9. [ ] Tap "Événements" tab
   - [ ] Icon and label display correctly
10. [ ] Tap "Paiements" tab
    - [ ] Icon and label display correctly
11. [ ] Tap "Documents" tab
    - [ ] Icon and label display correctly
12. [ ] **VERIFY**: All labels fit within navigation bar
13. [ ] **VERIFY**: Icons are evenly spaced
14. [ ] **VERIFY**: No visual glitches or overlap

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🌐 Test 5: URL Fixing

### Expected Behavior
All localhost URLs should be automatically converted to use the proper server IP.

### Test Steps
1. [ ] Enable Flutter debug logging
2. [ ] Open any course (image, PDF, or video)
3. [ ] Check Flutter console logs for URL being accessed
4. [ ] **VERIFY**: URL contains `192.168.100.99` 
5. [ ] **VERIFY**: URL does NOT contain `localhost`
6. [ ] **VERIFY**: URL does NOT contain `127.0.0.1`
7. [ ] **VERIFY**: Port is correct (`:8000` if your server uses it)

### To Check Logs
```bash
flutter run
# Then tap courses in the app and watch the console output
```

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🔄 Test 6: Multiple File Types

### Expected Behavior
Different file extensions should route to appropriate viewers.

### Test Steps
1. [ ] Find course with `.jpg` or `.png` → Opens ImageViewerScreen
2. [ ] Find course with `.pdf` → Opens PdfViewerScreen
3. [ ] Find course with `.mp4` → Opens InAppVideoPlayerScreen
4. [ ] Find course with `.gif` → Opens ImageViewerScreen
5. [ ] Find course with `.webp` → Opens ImageViewerScreen
6. [ ] Find course with `.mkv` → Opens InAppVideoPlayerScreen
7. [ ] Find course with unsupported type (`.doc`) → Shows error toast

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🚫 Test 7: No External Browser Launches

### Expected Behavior
Chrome or other browsers should NEVER open when viewing course content.

### Test Steps
1. [ ] Open 5 different courses of different types
2. [ ] **VERIFY**: Chrome never opens
3. [ ] **VERIFY**: No "Open with..." dialog appears
4. [ ] **VERIFY**: All content opens in dedicated in-app screens
5. [ ] **VERIFY**: Android's recent apps list shows only your app (not Chrome)

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## ⚡ Test 8: Performance

### Expected Behavior
Content should load reasonably fast and not cause app crashes.

### Test Steps
1. [ ] Open 3 different images in a row
   - [ ] No memory leaks
   - [ ] Images display quickly (cached after first load)
2. [ ] Open 3 different PDFs in a row
   - [ ] Downloads complete without timeout
   - [ ] PDF rendering is smooth
3. [ ] Open 3 different videos in a row
   - [ ] Videos load within 5-10 seconds
   - [ ] Playback is smooth
4. [ ] Navigate between tabs rapidly
   - [ ] No lag or freezing
5. [ ] Open content, go home, return to app
   - [ ] App state preserved correctly

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🇫🇷 Test 9: French Language

### Expected Behavior
All UI text and error messages should be in French.

### Verify These Strings Appear
- [ ] "Chargement de l'image..."
- [ ] "Impossible de charger l'image"
- [ ] "Téléchargement du PDF..."
- [ ] "Document PDF"
- [ ] "Chargement de la vidéo..."
- [ ] "Lecture vidéo"
- [ ] "Ouvrir la vidéo"
- [ ] "Vérifiez votre connexion internet"
- [ ] "Réessayer"
- [ ] "Contenu vidéo"

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 🎨 Test 10: Corporate Design Consistency

### Expected Behavior
All screens should follow the clean white & blue corporate design.

### Verify These Design Elements
- [ ] All AppBars are solid blue (not gradient)
- [ ] All backgrounds are clean white (not dark navy)
- [ ] No glowing effects or shadows
- [ ] No purple/indigo colors (old design)
- [ ] Text is black/dark gray on white (high contrast)
- [ ] Buttons are solid blue with white text
- [ ] Icons are clean and minimal
- [ ] No "Copier le lien" buttons anywhere

### Result: ✅ PASS / ❌ FAIL
**Notes**: _______________________________________

---

## 📊 Overall Test Results

| Test | Status | Priority | Notes |
|------|--------|----------|-------|
| 1. Image Viewing | ⬜ | HIGH | React card |
| 2. PDF Viewing | ⬜ | HIGH | UML card |
| 3. Video Playing | ⬜ | HIGH | Algorithm card |
| 4. Bottom Nav | ⬜ | HIGH | Overflow fix |
| 5. URL Fixing | ⬜ | MEDIUM | Localhost → IP |
| 6. File Types | ⬜ | MEDIUM | Routing |
| 7. No Browser | ⬜ | HIGH | In-app only |
| 8. Performance | ⬜ | MEDIUM | Speed & stability |
| 9. French Text | ⬜ | LOW | Language |
| 10. Design | ⬜ | MEDIUM | Corporate style |

**Overall Result**: _____ tests passed out of 10

---

## 🐛 Bug Report Template

If you find issues, document them here:

### Bug #1
**Test**: ___________________  
**Expected**: ___________________  
**Actual**: ___________________  
**Screenshot**: ___________________  
**Console Logs**: ___________________  

### Bug #2
**Test**: ___________________  
**Expected**: ___________________  
**Actual**: ___________________  
**Screenshot**: ___________________  
**Console Logs**: ___________________  

---

## ✅ Sign-Off

**Tested By**: ___________________  
**Date**: ___________________  
**Device**: STK L21  
**Android Version**: ___________________  
**App Version**: 1.0.0  
**Backend IP**: 192.168.100.99:8000  

**Ready for Production**: YES / NO

**Additional Notes**:
_________________________________________
_________________________________________
_________________________________________

---

## 📞 If Tests Fail

1. **Check Backend**: Visit `http://192.168.100.99:8000/api/courses` in phone's browser
2. **Check Logs**: Run `flutter run` and watch console output
3. **Verify Network**: Ensure phone and server on same Wi-Fi
4. **Clean Build**: Run `flutter clean && flutter pub get && flutter run`
5. **Review Guides**: See `QUICK_START.md` and `MEDIA_FIX_SUMMARY.md`

---

**Remember**: The goal is that students NEVER leave the app when viewing course content! 🎯
