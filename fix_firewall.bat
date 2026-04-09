@echo off
echo Opening port 8080 in Windows Firewall for XAMPP Apache...
netsh advfirewall firewall delete rule name="XAMPP Apache 8080" >nul 2>&1
netsh advfirewall firewall add rule name="XAMPP Apache 8080" dir=in action=allow protocol=TCP localport=8080
if %errorlevel%==0 (
    echo SUCCESS! Port 8080 is now open.
    echo Your Flutter app can now reach: http://192.168.1.13:8080/osbt-api/public/api
) else (
    echo FAILED. Please make sure you right-clicked and chose "Run as administrator".
)
pause
