@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

title Склейка видео и аудио через FFmpeg

echo.
echo ==========================================
echo  Склейка видео и аудио дорожек через FFmpeg
echo ==========================================
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

REM === Поиск аудио файлов ===
set /a audio_count=0

for %%F in (*.mp3 *.wav *.m4a *.aac *.flac *.ogg *.opus *.wma) do (
    if exist "%%~fF" (
        set /a audio_count+=1
        set "audio_!audio_count!=%%~fF"
    )
)

if %audio_count% EQU 0 (
    echo В папке не найдено аудиофайлов.
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

REM === Выбор аудио ===
echo Найденные аудиофайлы:
echo.

for /L %%I in (1,1,%audio_count%) do (
    for %%A in ("!audio_%%I!") do echo %%I. %%~nxA
)

echo.
set /p audio_choice=Выбери номер аудио: 

if not defined audio_%audio_choice% (
    echo Ошибка: неверный номер аудио.
    pause
    exit /b 1
)

set "AUDIO_FILE=!audio_%audio_choice%!"

echo.
echo Выбрано аудио:
echo %AUDIO_FILE%
echo.

REM === Имя итогового файла ===
for %%V in ("%VIDEO_FILE%") do set "VIDEO_NAME=%%~nV"
for %%A in ("%AUDIO_FILE%") do set "AUDIO_NAME=%%~nA"

set "OUTPUT_FILE=%VIDEO_NAME%__plus__%AUDIO_NAME%.mp4"

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
echo Склеиваю видео и аудио...
echo.

REM === Основная попытка: видео без перекодирования, аудио в AAC ===
ffmpeg -y -i "%VIDEO_FILE%" -i "%AUDIO_FILE%" -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest "%OUTPUT_FILE%"

if errorlevel 1 (
    echo.
    echo Первая попытка не удалась.
    echo Пробую безопасный вариант с перекодированием видео и аудио...
    echo.

    ffmpeg -y -i "%VIDEO_FILE%" -i "%AUDIO_FILE%" -map 0:v:0 -map 1:a:0 -c:v libx264 -preset veryfast -crf 20 -c:a aac -b:a 192k -shortest "%OUTPUT_FILE%"

    if errorlevel 1 (
        echo.
        echo Ошибка: склейка не выполнена.
        pause
        exit /b 1
    )
)

echo.
echo Готово!
echo Итоговый файл создан:
echo %OUTPUT_FILE%
echo.

pause
exit /b 0