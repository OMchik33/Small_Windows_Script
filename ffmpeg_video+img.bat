@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

title Добавление обложки в начало видео через FFmpeg

echo.
echo ==============================================
echo  Добавление обложки в начало видео через FFmpeg
echo ==============================================
echo.

REM === Папка для анализа ===
if "%~1"=="" (
    set "WORKDIR=%cd%"
) else (
    set "WORKDIR=%~1"
)

if not exist "%WORKDIR%" (
    echo Ошибка: папка не найдена:
    echo %WORKDIR%
    pause
    exit /b 1
)

cd /d "%WORKDIR%"

REM === Проверка FFmpeg ===
where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo FFmpeg не найден в системе.
    echo Сейчас будет попытка установить FFmpeg через winget.
    echo.

    where winget >nul 2>nul
    if errorlevel 1 (
        echo Ошибка: winget не найден.
        echo Установи FFmpeg вручную или установи App Installer из Microsoft Store.
        pause
        exit /b 1
    )

    winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements

    echo.
    echo Проверяю FFmpeg после установки...
    where ffmpeg >nul 2>nul
    if errorlevel 1 (
        echo.
        echo FFmpeg установлен, но пока не найден в PATH.
        echo Закрой это окно, открой новое окно CMD или перезагрузи Windows,
        echo затем запусти BAT-файл снова.
        pause
        exit /b 1
    )
)

echo FFmpeg найден.
echo.

REM === Поиск видео файлов ===
set /a video_count=0

for %%F in (*.mp4 *.mkv *.mov *.avi *.webm *.m4v *.mpg *.mpeg *.ts) do (
    if exist "%%~fF" (
        set /a video_count+=1
        set "video_!video_count!=%%~fF"
    )
)

if %video_count% EQU 0 (
    echo В папке не найдено видеофайлов.
    echo Папка:
    echo %WORKDIR%
    pause
    exit /b 1
)

REM === Поиск изображений ===
set /a image_count=0

for %%F in (*.jpg *.jpeg *.png *.webp *.bmp) do (
    if exist "%%~fF" (
        set /a image_count+=1
        set "image_!image_count!=%%~fF"
    )
)

if %image_count% EQU 0 (
    echo В папке не найдено изображений для обложки.
    echo Поддерживаются:
    echo JPG, JPEG, PNG, WEBP, BMP
    echo.
    echo Папка:
    echo %WORKDIR%
    pause
    exit /b 1
)

REM === Выбор видео ===
echo Найденные видеофайлы:
echo.

for /L %%I in (1,1,%video_count%) do (
    for %%A in ("!video_%%I!") do echo %%I. %%~nxA
)

echo.
set /p video_choice=Выбери номер видео: 

if not defined video_%video_choice% (
    echo Ошибка: неверный номер видео.
    pause
    exit /b 1
)

set "VIDEO_FILE=!video_%video_choice%!"

echo.
echo Выбрано видео:
echo %VIDEO_FILE%
echo.

REM === Выбор изображения ===
echo Найденные изображения:
echo.

for /L %%I in (1,1,%image_count%) do (
    for %%A in ("!image_%%I!") do echo %%I. %%~nxA
)

echo.
set /p image_choice=Выбери номер изображения для обложки: 

if not defined image_%image_choice% (
    echo Ошибка: неверный номер изображения.
    pause
    exit /b 1
)

set "COVER_FILE=!image_%image_choice%!"

echo.
echo Выбрана обложка:
echo %COVER_FILE%
echo.

REM === Имя итогового файла ===
for %%V in ("%VIDEO_FILE%") do set "VIDEO_NAME=%%~nV"

set "OUTPUT_FILE=merge__%VIDEO_NAME%.mp4"

echo Итоговый файл:
echo %OUTPUT_FILE%
echo.

if exist "%OUTPUT_FILE%" (
    echo Файл уже существует.
    set /p overwrite=Перезаписать? Введи Y для перезаписи: 
    if /I not "%overwrite%"=="Y" (
        echo Отменено.
        pause
        exit /b 0
    )
)

echo.
echo Добавляю обложку в начало видео...
echo.

ffmpeg -y -i "%COVER_FILE%" -i "%VIDEO_FILE%" -filter_complex "[0:v]scale2ref=iw:ih[cov][vid]; [cov]setsar=1,trim=duration=0.01[v0]; [vid]setsar=1[v1]; [v0][v1]concat=n=2:v=1:a=0[v]" -map "[v]" -map 1:a? -c:v libx264 -pix_fmt yuv420p -c:a aac -movflags +faststart "%OUTPUT_FILE%"

if errorlevel 1 (
    echo.
    echo Ошибка: обработка видео не выполнена.
    pause
    exit /b 1
)

echo.
echo Готово!
echo Итоговый файл создан:
echo %OUTPUT_FILE%
echo.

pause
exit /b 0