param([switch]$Local)

if ($Local) {
    $Target = Join-Path (Get-Location) ".claude\skills"
} else {
    $Target = Join-Path $env:USERPROFILE ".claude\skills"
}

New-Item -ItemType Directory -Force $Target | Out-Null

$tmp = "$env:TEMP\agent-skills-install"
Invoke-WebRequest https://github.com/cytoph/agent-skills/archive/refs/heads/main.zip -OutFile "$tmp.zip"
Expand-Archive "$tmp.zip" $tmp -Force
Copy-Item "$tmp\agent-skills-main\skills\install-git-skills" "$Target\" -Recurse -Force
Copy-Item "$tmp\agent-skills-main\skills\update-git-skills" "$Target\" -Recurse -Force
Remove-Item "$tmp.zip", $tmp -Recurse -Force

Write-Host "install-git-skills and update-git-skills installed to $Target"
Write-Host "Reload skills in your agent."
