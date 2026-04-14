@echo off
setlocal

set TARGET=%USERPROFILE%\.claude\skills

:parse
if "%~1"=="--local" set TARGET=%CD%\.claude\skills
shift
if not "%~1"=="" goto parse

if not exist "%TARGET%" mkdir "%TARGET%"

curl -sL https://github.com/cytoph/agent-skills/archive/refs/heads/main.zip -o "%TEMP%\agent-skills.zip"
tar -xf "%TEMP%\agent-skills.zip" -C "%TEMP%" agent-skills-main/skills/install-git-skills agent-skills-main/skills/update-git-skills
xcopy /E /I /Y "%TEMP%\agent-skills-main\skills\install-git-skills" "%TARGET%\install-git-skills\"
xcopy /E /I /Y "%TEMP%\agent-skills-main\skills\update-git-skills" "%TARGET%\update-git-skills\"
rd /S /Q "%TEMP%\agent-skills-main"
del "%TEMP%\agent-skills.zip"

echo install-git-skills and update-git-skills installed to %TARGET%
echo Run /reload-plugins in Claude Code to pick up the skills.

endlocal
