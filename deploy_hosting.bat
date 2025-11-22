@echo off
echo ====================================
echo RedPing Firebase Hosting Deployment
echo ====================================
echo.
echo This will deploy the web hosting configuration including:
echo - Digital emergency card at /sos/{sessionId}
echo - URL rewrite rules for SOS links
echo.
pause

echo.
echo Deploying to Firebase Hosting...
firebase deploy --only hosting

echo.
echo ====================================
echo Deployment Complete!
echo ====================================
echo.
echo Test your digital card links at:
echo https://redping.app/sos/test_session_123
echo.
pause
