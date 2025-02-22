:: Codec por bernarbernuli
:: Version 1.0
:: 10 April 2024


:adb
@echo off
setlocal EnableDelayedExpansion enableextensions

::goto inicio


:: First settings (window title, background colour and text, restart adb)
color 0a
title Play Store Tracker
adb kill-server > NUL 2>&1
adb start-server > NUL 2>&1

:: adb driver detection
adb version
if errorlevel 1 (
	cls
	color D
	echo.
	echo  ADB is not found.
	echo.
	ping google.com -n 1 > NUL
	if errorlevel 1 (
		echo.
		echo  ____________________________________________________________________________________________________________________
		echo.
		echo   No internet connection has been detected so I cannot download the ADB drivers, as a workaround you can download 
		echo   auxiliary files for offline environments beforehand and unzip them in the same folder as Android TV Tools vXX.exe.
		echo  ____________________________________________________________________________________________________________________
		echo.
		pause
	) else (
		echo.
		echo  ____________________________________________________________________________________________________________________
		echo.
		echo   OK, press any key to continue, the process downloads the ADB drivers and saves them in the same folder as 
		echo   Android TV Tools, however I recommend installing the installer version of "ADB & Fastboot++" and keep 
		echo   "Add to System Patch Environment" option enabled in the configuration.
		echo  ____________________________________________________________________________________________________________________
		echo.
		pause
		set "github_address="
		for /f "tokens=1,* delims=:" %%a in ('curl -ks https://api.github.com/repos/K3V1991/ADB-and-FastbootPlusPlus/releases/latest ^| find "tag_name"') do (set github_address=%%b)
		for /f "tokens=1 delims=" %%a in (%github_address%) do (set "ver_adb=%%a")
		if exist ADB-and-Fastboot++_%ver_adb%-Portable.zip del ADB-and-Fastboot++_%ver_adb%-Portable.zip
		if exist ADB-and-Fastboot++_%ver_adb%-Portable del rmdir /Q /S "ADB-and-Fastboot++_%ver_adb%-Portable"
		powershell -Command "Start-bitsTransfer -Source https://github.com/K3V1991/ADB-and-FastbootPlusPlus/releases/download/%ver_adb%/ADB-and-Fastboot++_%ver_adb%-Portable.zip -Destination 'ADB-and-Fastboot++_%ver_adb%-Portable.zip'"
		powershell Expand-Archive "ADB-and-Fastboot++_%ver_adb%-Portable.zip"
		move /Y "ADB-and-Fastboot++_%ver_adb%-Portable\ADB and Fastboot++ %ver_adb% Portable\adb.exe"  > NUL 2>&1
		move /Y "ADB-and-Fastboot++_%ver_adb%-Portable\ADB and Fastboot++ %ver_adb% Portable\AdbWinApi.dll" > NUL 2>&1
		move /Y "ADB-and-Fastboot++_%ver_adb%-Portable\ADB and Fastboot++ %ver_adb% Portable\AdbWinUsbApi.dll" > NUL 2>&1
		del ADB-and-Fastboot++_%ver_adb%-Portable.zip
		rmdir /Q /S "ADB-and-Fastboot++_%ver_adb%-Portable"
		echo.
		echo   -- Done^^! ADB and Fastboot PlusPlus %ver_adb% has been downloaded.
		echo.
		timeout 2 > NUL 2>&1
		goto adb
	)
)

:: Detection obsolete adb version
for /f "Tokens=2 Delims= " %%a in ('adb version ^| find /i "version"') do (set ver_adb=%%a)
if %ver_adb% LSS 33 echo. & echo   -- The version of the ADB drivers is very old, more current drivers will be downloaded below to make the tool work properly. & echo. & pause & goto adb_help

:ip
cls
:: Set text colours
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set ESC=%%b)
set Color_Rojo=%ESC%[0;31m
set Color_Rojo_claro=%ESC%[1;91m
set Color_Morado_claro=%ESC%[0;95m
set Color_Aguamarina=%ESC%[0;36m
set Color_Verde=%ESC%[0;32m
set Color_VerdeClaro=%ESC%[0;92m


set port=5555
echo.
echo.
echo                                        Play Store Tracker 
echo.
echo  __________________________________________________________________________________________________
echo.
echo   Hello %USERNAME%, before you continue, read this:
echo             -- Enable "USB debugging" (for Wi-Fi connection).
echo             -- Make sure that Android TV/Google TV is connected to the Wi-Fi network.
echo  __________________________________________________________________________________________________
timeout 1 > NUL 2>&1
set ip=

:: Ip definida para empezar cuanto antes
set "ip=192.168.1.168"
echo.
set /p ip="^> Indicates IP address of the device running Android TV (is under "Settings ^> System ^> Status"): "
echo.
adb connect "%ip%:5555" | find /i "connected to" > NUL 2>&1
if errorlevel 1 goto ip_error

:ip_conectado
echo.
echo.     
echo         %Color_Aguamarina%Connected to Wi-Fi network^^!^^!^^!%Color_VerdeClaro%
echo.       
echo.
echo.
pause
goto inicio


:ip_error
set ip_error=
for /f "tokens=2" %%G in ('adb devices ^| findstr /r /c:"%ip%:5555*"') do (
    set "resultado=%%G" 
    set deviceFound=1
)
if not defined deviceFound (
    echo  _______________________________________________________________________________________________________
    echo.
    echo  No device with the IP address %ip% found, you may have entered the IP address
	echo  incorrectly or the TV device is not connected to the Wi-Fi network. 
    echo  _______________________________________________________________________________________________________
    set deviceFound=
    echo.
    echo.
    adb disconnect > NUL 2>&1
	pause
    goto ip
)
if "!resultado!"=="unauthorized" (
    echo  ________________________________________________________________________________________________________
    echo.
    echo  It does not connect because the device with the IP %ip%, is marked as %Color_Rojo_claro%unauthorized%Color_VerdeClaro%. Check the 
	echo  screen of your TV device and enable USB debugging when prompted to do so when connecting.
    echo  ________________________________________________________________________________________________________
    set deviceFound=
    echo.
    echo.
    adb disconnect > NUL 2>&1
	pause
    goto ip
)

:inicio
cls
:: Extract brand and model of your Android TV device to include in tracked_apps.csv file.
for /f "delims=" %%a in ('adb -s %ip% shell getprop ro.product.manufacturer') do set "Manufacturer=%%a"
for /f "delims=" %%b in ('adb -s %ip% shell getprop ro.product.model') do set "model=%%b"
:: Counts the total number of apps in the Apps_PlayStore.txt file.
for /f "tokens=*" %%a in ('find /c /v "" ^< "Apps_PlayStore.txt"') do set "lines=%%a"
echo.
echo  ______________________________________________________________________________________________________________________
echo.
echo   This tool allows you to track which apps are compatible with your Android TV device, the task is to access all tabs
echo   of a preloaded list of apps in the play store, currently %Color_Aguamarina%%lines%%Color_VerdeClaro% apps. Each time you enter a tab, it takes a 
echo   screenshot and through an OCR engine detects when the app is not compatible with your device. 
echo.
echo    - The task for each tile takes about 5 seconds, so the tracking of the %Color_Aguamarina%%lines%%Color_VerdeClaro% apps will take several hours, it is 
echo      important that you keep the TV on during the task (disable the scheduled TV shutdown if you have it), prevent 
echo      the screen saver/environment mode from being activated and do not use the TV during the task, as it is necessary 
echo      for it to perform the screenshot correctly.
echo.
echo    - If you use Projectivy Launcher or similar, disable the accessibility services of this type of apps, as it 
echo      prevents this tool from working properly.
echo.
echo    - You can close the tool, and continue later if you wish, as it saves the position where it was.
echo.
echo    - The tool will extract the results in the file %Color_Aguamarina%"tracked_apps (%Manufacturer% %model%).csv"%Color_VerdeClaro%, once the task
echo      is finished it sends the file.
echo.
echo    - This tool does not collect any personal data nor does it send anything to any remote server. 
echo  ______________________________________________________________________________________________________________________
echo.
pause

cls
:: Check that English language is set on Android TV device.
for /f "delims=" %%a in ('adb -s %ip% shell getprop persist.sys.locale') do set "language_original=%%a"
:language
for /f "delims=" %%a in ('adb -s %ip% shell getprop persist.sys.locale') do set "language=%%a"
echo %language% | findstr /C:"en-" >nul
if errorlevel 1 (
	echo.
	echo  -- You currently have the system language set to %Color_Aguamarina%%language%%Color_VerdeClaro%, the tool only works in English. Change the 
	echo     language while running the task, when finished you can switch back to the original language.
	adb -s %ip% shell input keyevent KEYCODE_WAKEUP> NUL 2>&1
	adb -s %ip% shell am start -a android.settings.LOCALE_SETTINGS> NUL 2>&1
	echo.
	pause
	echo.
	echo.
	goto language
)
cls
if exist text_dump.txt del text_dump.txt
if exist screenshot.png del screenshot.png
set lineaInicial=0
set "tiempoTranscurrido=0"
set count_compatible=0
set count_nocompatible=0
set count_down=0
if exist PS_Tracker.log for /f "tokens=1,2,3,4,5 delims=;" %%a in ('type PS_Tracker.log') do set "lineainicial=%%a" & set "tiempoTranscurrido=%%b" & set "count_compatible=%%c" & set "count_nocompatible=%%d" & set "count_down=%%e"
set "start_time=0
set "horaActual=0"
set "minutoActual=0"
set "dayActual=0"
set "monthActual=0"
set "yearActual=0"
set "tiempoPausa=0"
set "tiempoTotal=0"
set DATEFORMAT=dd/mm/yyyy
for /f "tokens=1-2 delims=:." %%a in ('time /T') do set "horaInicio=%%a" & set "minutoInicio=%%b"
for /f "tokens=1-4 delims=/ " %%a in ('echo %date%') do set "dayInicio=%%a" & set "monthInicio=%%b" & set "yearInicio=%%c"
echo.
echo  ===========================================
echo   %ESC%[93mRunning Apps tracking in Play Store...%Color_VerdeClaro%
echo  ===========================================
echo.
set count=0
:: Loop to track compatibility of all apps
for /f "tokens=1,2 delims=;;" %%h in ('type Apps_PlayStore.txt') do (
	set /a count=!count!+1
	if !count! geq !lineaInicial! (
		echo !count!;!tiempoTranscurrido!;!count_compatible!;!count_nocompatible!;!count_down!> PS_Tracker.log
		set "tiempoEspera=1"
		set "package=%%i"
		set "app=%%h"
		if !count! LSS 10 set "espacios=   "
		if !count! GEQ 10 set "espacios=  "
		if !count! GEQ 100 set "espacios="
		set "reintentos=0"
		:retry
		set "content="
		set "compatible="
		:: Simulates button press to prevent the screen saver/ambient mode from activating and ensure that the TV device stays on.
		adb -s %ip% shell input keyevent KEYCODE_WAKEUP > NUL 2>&1
		adb -s %ip% shell input keyevent KEYCODE_HOME > NUL 2>&1
		:: It enters the tab of an app in play store, takes a screenshot after 1 second, sends it to the PC and exports the text from the screenshot to text with the help of the OCR recognition engine Tesseract.
		adb -s %ip% shell am start -a android.intent.action.VIEW -d "https://play.google.com/store/apps/details?id=!package!"> NUL 2>&1
		timeout /t !tiempoEspera! >nul 2>&1
		adb -s %ip% shell screencap /sdcard/screenshot.png> NUL 2>&1
		adb -s %ip% pull /sdcard/screenshot.png> NUL 2>&1
		adb -s %ip% shell rm /sdcard/screenshot.png> NUL 2>&1
		tesseract screenshot.png text_dump -l eng> NUL 2>&1
		for /f "tokens=*" %%a in ('type text_dump.txt ^| findstr /i /c:"Google Play" /c:"Google Piay" /c:"Item not found." /c:"BLUE OCEAN X"') do set "content=%%a"
		if /i "!content!"=="" (
			if !reintentos! GEQ 2 (
				for /f "tokens=1-2 delims=:." %%f in ('time /T') do set "horaActual=%%f" & set "minutoActual=%%g"
				for /f "tokens=1-4 delims=/ " %%f in ('echo %date%') do set "dayActual=%%f" & set "monthActual=%%g" & set "yearActual=%%h"
				set /a "tiempoTranscurrido=!tiempoTranscurrido!+((!monthActual!-!monthInicio!)*43200)+((!dayActual!-!dayInicio!)*1440)+((!horaActual!-!horaInicio!)*60)+(!minutoActual!-!minutoInicio!)"
				set /a "dias=!tiempoTranscurrido!/(24*60)"
				set /a "horas_restantes=!tiempoTranscurrido! %% (24*60)"
				set /a "horas=!horas_restantes!/60"
				set /a "minutos_restantes=!horas_restantes! %% 60"
				if !tiempoTranscurrido! GEQ 1440 (
					set "tiempoTranscurrido_text=!dias! day/s !horas! hour/s !minutos_restantes! minute/s"
				) else (
					if !tiempoTranscurrido! GTR 60 (
						set "tiempoTranscurrido_text=!horas! hour/s !minutos_restantes! minute/s" 
					) else (
						if !tiempoTranscurrido! LEQ 60 set "tiempoTranscurrido_text=!minutos_restantes! minute/s"
					)
				)
				echo.
				echo  -- No data is being obtained, task stopped at !horaActual!:!minutoActual! hours 
				echo     ^!tiempoTranscurrido_text! elapsed since the start of the task^.
				echo     Check that the TV is turned ON with your Android TV device...
				echo.
				set "content="
				pause
				for /f "tokens=1-2 delims=:." %%f in ('time /T') do set "horaActual=%%f" & set "minutoActual=%%g"
				for /f "tokens=1-4 delims=/ " %%f in ('echo %date%') do set "dayActual=%%f" & set "monthActual=%%g" & set "yearActual=%%h"
				set /a "tiempoPausa=!tiempoPausa_Acumulado!+((!monthActual!-!monthInicio!)*43200)+((!dayActual!-!dayInicio!)*1440)+((!horaActual!-!horaInicio!)*60)+(!minutoActual!-!minutoInicio!)"
				Set "tiempoPausa_Acumulado=!tiempoPausa!"
				echo.
				call :retry !app!
			) else (
				set /a reintentos=!reintentos!+1
				set "tiempoEspera=4" 
				set "content=" 
				call :retry !app!
			)
		) else (
			:: Check if the TV device is compatible with the app
			for /f "tokens=*" %%a in ('type text_dump.txt ^| findstr /i /c:"Your device isn't compatible with this version."') do set "compatible=%%a"
			if /i "!compatible!"=="" (
				for /f "tokens=*" %%a in ('type text_dump.txt ^| findstr /i /c:"This app isn't available for your device because it was made for an older version of Android."') do set "compatible2=%%a"
				if /i NOT "!compatible2!"=="" (
					set /a count_nocompatible=!count_nocompatible!+1
					echo  %Color_Rojo_claro%!count!/%lines%   !espacios!Is NOT compatible, older version  !app!%Color_VerdeClaro%
					:: Export compatibility result to the file tracked_apps.csv
					echo !count!;!app!;!package!;NOT COMPATIBLE, OLDER VERSION>> "tracked_apps (%Manufacturer% %model%).csv"
					del screenshot.png
					set "compatible2="
					adb -s %ip% shell input keyevent KEYCODE_HOME > NUL 2>&1
				) else (
					for /f "tokens=*" %%a in ('type text_dump.txt ^| findstr /i /c:"Item not found."') do set "compatible3=%%a"
					if /i NOT "!compatible3!"=="" (
						set /a count_down=!count_down!+1
						echo  %Color_Morado_claro%!count!/%lines%   !espacios!App is Down                       !app!%Color_VerdeClaro%
						:: Export compatibility result to the file tracked_apps.csv
						echo !count!;!app!;!package!;APP DOWN>> "tracked_apps (%Manufacturer% %model%).csv"
						del screenshot.png
						set "compatible3="
						adb -s %ip% shell input keyevent KEYCODE_HOME > NUL 2>&1
					) else (
						set /a count_compatible=!count_compatible!+1
						echo  %Color_Verde%!count!/%lines%   !espacios!Is compatible                     !app!%Color_VerdeClaro%
						:: Export compatibility result to the file tracked_apps.csv
						echo !count!;!app!;!package!;COMPATIBLE>> "tracked_apps (%Manufacturer% %model%).csv"
						del screenshot.png
						del text_dump.txt
						set "compatible="
						adb -s %ip% shell input keyevent KEYCODE_HOME > NUL 2>&1
				))
			) else (
				set /a count_nocompatible=!count_nocompatible!+1
				echo  %Color_Rojo%!count!/%lines%   !espacios!Is NOT compatible                 !app!%Color_VerdeClaro%
				:: Export compatibility result to the file tracked_apps.csv
				echo !count!;!app!;!package!;NOT COMPATIBLE>> "tracked_apps (%Manufacturer% %model%).csv"
				del screenshot.png
				del text_dump.txt
				set "compatible="
				adb -s %ip% shell input keyevent KEYCODE_HOME > NUL 2>&1
		))
	)
)
:: Set the time at which results are generated
for /f "tokens=1-2 delims=:." %%f in ('time /T') do set "horaActual=%%f" & set "minutoActual=%%g"
for /f "tokens=1-4 delims=/ " %%f in ('echo %date%') do set "dayActual=%%f" & set "monthActual=%%g" & set "yearActual=%%h"
set "date_actual=!yearActual!-!monthActual!-!dayActual!_!horaActual!-!minutoActual!"
set /a "tiempoTranscurrido=((!monthActual!-!monthInicio!)*43200)+((!dayActual!-!dayInicio!)*1440)+((!horaActual!-!horaInicio!)*60)+(!minutoActual!-!minutoInicio!)"
set /a "tiempoTotal=!tiempoTotal!+!tiempoTranscurrido!-!tiempoPausa!"
set /a "dias=!tiempoTotal!/(24*60)"
set /a "horas_restantes=!tiempoTotal! %% (24*60)"
set /a "horas=!horas_restantes!/60"
set /a "minutos_restantes=!horas_restantes! %% 60"
if !tiempoTotal! GEQ 1440 (
	set "tiempoTotal_text=!dias! day/s !horas! hour/s !minutos_restantes! minute/s"
) else (
	if !tiempoTotal! GTR 60 (
		set "tiempoTotal_text=!horas! hour/s !minutos_restantes! minute/s" 
	) else (
		if !tiempoTotal! LEQ 60 set "tiempoTotal_text=!minutos_restantes! minute/s"
	)
)
if exist PS_Tracker.log del PS_Tracker.log
if !count!==%lines% (
	rename "tracked_apps (%Manufacturer% %model%).csv" "tracked_apps (%Manufacturer% %model%) - !date_actual!.csv" > NUL 2>&1
	adb -s %ip% shell pm trim-caches 999999999999999999
	adb -s %ip% shell pm trim-caches 999999999999999999
	adb -s %ip% shell pm trim-caches 999999999999999999
	adb -s %ip% shell pm trim-caches 999999999999999999
	adb -s %ip% shell pm trim-caches 999999999999999999
	echo.
	echo.
	echo  ==============================================
	echo      %ESC%[93mTask completed^^! %Color_VerdeClaro%
	echo.
	echo   Execution time: %Color_Aguamarina%!tiempoTotal_text!%Color_VerdeClaro%
	echo.
	echo   Device TV: %Color_Aguamarina%%Manufacturer% %model%%Color_VerdeClaro%
	echo   - Compatible Apps: %Color_Aguamarina%!count_compatible!%Color_VerdeClaro%
	echo   - NOT compatible Apps: %Color_Aguamarina%!count_nocompatible!%Color_VerdeClaro%
	echo   - Down Apps: %Color_Aguamarina%!count_down!%Color_VerdeClaro%
	echo  ========================================                                                                                                                                      ======
	echo.
	echo  Send file %Color_Aguamarina%tracked_apps ^(%Manufacturer% %model%^) - %date_actual%.csv%Color_VerdeClaro% to include results.
	echo.                          
	echo  Thank you for your help.
	echo.
	echo %language_original% | findstr /C:"en-" >nul
	if errorlevel 1 (
		echo.
		echo  -- Your original language was not English, now you can change the language in the settings of your TV device.
		adb shell am start -a android.settings.LOCALE_SETTINGS> NUL 2>&1
		echo.
	)
	pause
)


:: terminar texto y significar que configuren la desconexiones programadas
:: hacer captura con la tele apagada




