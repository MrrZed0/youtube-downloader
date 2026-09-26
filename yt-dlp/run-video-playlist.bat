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
    echo [ERROR] playlists.txt not found in this directory!
    echo Please create a text file named "playlists.txt" with one URL per line.
    echo.
    pause
    exit /B
)

echo Reading playlists.txt and starting MAX QUALITY MP4 downloads (Forced 320kbps Audio)...
echo ====================================================================================

:: Loop through each line in playlists.txt
for /f "usebackq delims=" %%A in ("playlists.txt") do (
    set "playlist_url=%%A"
    
    :: Skip empty lines or comment lines starting with #
    if "!playlist_url!" neq "" if "!playlist_url:~0,1!" neq "#" (
        
        echo.
        echo --------------------------------------------------
        echo Processing: !playlist_url!
        echo --------------------------------------------------
        
		set "folder_name="
        for /f "delims=" %%I in ('yt-dlp.exe --flat-playlist --print "%%(playlist_title)s" --playlist-items 1 "!playlist_url!"') do (
            set "folder_name=%%I"
            goto :found_name
        )
        
        :found_name
        if not defined folder_name (
            set "folder_name=Playlist_Downloads"
        )
        
        :: Clean up any invalid characters for folder names if needed, then create
        echo Creating folder: "!folder_name!"
        if not exist "!folder_name!" mkdir "!folder_name!"
        :: Downloads max video/audio, merges to MP4, names folder properly, and transcodes audio to 320k without deleting video
        yt-dlp.exe -P "!folder_name!" -f "bestvideo+bestaudio/best" --output "%%(title)s.%%(ext)s" --merge-output-format mp4 --postprocessor-args "ffmpeg:-c:v copy -c:a aac -b:a 320k" --yes-playlist "!playlist_url!"
        
        echo Finished playlist.
    )
)

echo.
echo ==========================================================
echo All playlists processed successfully!
pause