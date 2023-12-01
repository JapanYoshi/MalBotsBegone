rem Upload HTML version to Itch.
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\index.zip       haitouch/malbots:html
rem Upload Android app to Itch.
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\Malbots.apk     haitouch/malbots:android
rem Upload Windows versions to Itch.
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\malbots-x32.exe haitouch/malbots:windows32
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\malbots-x64.exe haitouch/malbots:windows64
rem Upload Linux versions to Itch.
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\malbots.x86     haitouch/malbots:linux32
"C:\Users\Haley\Downloads\Itch Butler\butler" push .\malbots.x86_64  haitouch/malbots:linux64
pause