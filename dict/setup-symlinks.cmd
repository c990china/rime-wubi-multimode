@echo off
chcp 65001 >nul
setlocal

rem ============================================================
rem Rime Weasel / wubi86_jidian - create symlinks
rem ------------------------------------------------------------
rem Run as Administrator (right-click -> Run as administrator).
rem Purpose: map the dict source, the candidate-blocker blacklist and
rem          the english passthrough translator from the git package
rem          into the Rime user directory.
rem Note:    idempotent - removes old links, then recreates them.
rem Repo:    <本仓库根目录>（脚本据自身位置推导 GIT，无需硬编码）
rem
rem Comments below are ASCII-only ON PURPOSE. Non-ASCII bytes in a
rem .cmd file can make cmd.exe mis-parse "::" comment lines and print
rem a bogus "not recognized as an internal or external command".
rem Chinese text is fine inside echo statements (shown to the user).
rem ============================================================

set "RIME=%AppData%\Rime"
rem derive repo root from this script's own location (script sits in <repo>\dict\)
for %%I in ("%~dp0..") do set "GIT=%%~fI"

echo.
echo === 建立软链接 ===
echo Rime 目录 : %RIME%
echo git 包目录: %GIT%
echo.

rem ---------- 1. user dict symlink ----------
if not exist "%RIME%" mkdir "%RIME%"
if exist "%RIME%\wubi86_jidian_user.dict.yaml" del "%RIME%\wubi86_jidian_user.dict.yaml"
mklink "%RIME%\wubi86_jidian_user.dict.yaml" "%GIT%\dict\wubi86_jidian_user.dict.yaml"

rem ---------- 2. lua candidate-blocker symlink ----------
if not exist "%RIME%\lua" mkdir "%RIME%\lua"
if exist "%RIME%\lua\cand_blocker.lua" del "%RIME%\lua\cand_blocker.lua"
mklink "%RIME%\lua\cand_blocker.lua" "%GIT%\lua\cand_blocker.lua"

rem ---------- 3. english passthrough translator ----------
if exist "%RIME%\lua\english.lua" del "%RIME%\lua\english.lua"
mklink "%RIME%\lua\english.lua" "%GIT%\lua\english.lua"

echo.
echo === 结果核对 ===
dir /AL "%RIME%\wubi86_jidian_user.dict.yaml" 2>nul | findstr /i "wubi86_jidian_user"
dir /AL "%RIME%\lua\cand_blocker.lua" 2>nul | findstr /i "cand_blocker"
dir /AL "%RIME%\lua\english.lua" 2>nul | findstr /i "english"

echo.
echo ============================================================
echo  完成。下一步：右键任务栏右下角小狼毫托盘图标 -^> 重新部署
echo ============================================================
echo.
pause
