: << 'CMDBLOCK'
@echo off
REM rookie-work cross-platform hook wrapper.
REM Polyglot pattern adapted from the superpowers project
REM (https://github.com/obra/superpowers), MIT License.
REM On Windows: cmd runs this batch block, finds Git Bash, calls the hook script.
REM On Unix: bash treats this block as a heredoc to ':' (discarded), runs the tail.
REM Usage: run-hook.cmd <script-name> [args...]
if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)
set "HOOK_DIR=%~dp0"
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
where bash >nul 2>nul
if %ERRORLEVEL% equ 0 (
    bash "%HOOK_DIR%%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)
REM No bash found - exit cleanly so the session still starts (just without injection).
exit /b 0
CMDBLOCK

# Unix path. (Wrapper pattern adapted from superpowers, MIT.)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
