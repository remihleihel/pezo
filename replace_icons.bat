@echo off
echo Replacing app icons with WIS logo...

copy "assets\images\WIS-logo.png" "android\app\src\main\res\mipmap-hdpi\ic_launcher.png" /Y
copy "assets\images\WIS-logo.png" "android\app\src\main\res\mipmap-mdpi\ic_launcher.png" /Y
copy "assets\images\WIS-logo.png" "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" /Y
copy "assets\images\WIS-logo.png" "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" /Y
copy "assets\images\WIS-logo.png" "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" /Y

echo App icons replaced successfully!
pause




