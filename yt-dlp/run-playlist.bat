@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
cd /d "%~dp0"
setlocal enabledelayedexpansion

:: Check if playlists.txt exists
if not exist "playlists.txt" (
    echo Error: playlists.txt not found in this directory!
    echo Please create a playlists.txt file with one URL per line.
    pause
    exit /B
)

echo Reading playlists.txt and starting downloads...
echo ==============================================

:: Loop through each non-empty line in playlists.txt
for /f "usebackq delims=" %%A in ("playlists.txt") do (
    set "playlist_url=%%A"
    
    :: Skip empty lines or comment lines starting with #
    if "!playlist_url!" neq "" if "!playlist_url:~0,1!" neq "#" (
        
        echo.
        echo Processing: !playlist_url!
        echo Fetching playlist name...
        
        set "folder_name="
        for /f "delims=" %%I in ('yt-dlp.exe --flat-playlist --print "%%(playlist_title)s" --playlist-items 1 "!playlist_url!"') do (
            set "folder_name=%%I"
        )
        
        if not defined folder_name (
            set "folder_name=Playlist_Downloads"
        )
        
        :: Clean up any invalid characters for folder names if needed, then create
        echo Creating folder: "!folder_name!"
        if not exist "!folder_name!" mkdir "!folder_name!"

        echo Starting download with Realtime priority...
        start /realtime /wait yt-dlp.exe -P "!folder_name!" --output "%%(title)s.%%(ext)s" -x --audio-format mp3 --audio-quality 320k --yes-playlist "!playlist_url!"
        
        echo Finished downloading: !folder_name!
        echo ----------------------------------------------
    )
)

echo.
echo All playlists processed successfully!
pause
