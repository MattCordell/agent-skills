<#
.SYNOPSIS
    Links every skill in this repository into the Claude Code skills folder.

.DESCRIPTION
    For each top-level folder in the repo that contains a SKILL.md, makes sure
    ~/.claude/skills/<name> is a junction pointing at it.

    - Missing link: creates the junction.
    - Junction to this repo: left alone.
    - Plain folder (an old copy): moved to ~/.claude/skills-backup/<name>-<timestamp>,
      then replaced with a junction. The backup lives outside the skills folder so
      Claude Code does not load it as a second skill.
    - Junction to somewhere else: reported and skipped, unless -Force is given.
    - Broken junction into this repo (the skill was deleted or renamed): removed.

    Nothing outside ~/.claude/skills and ~/.claude/skills-backup is changed.
    Junctions are removed with a non-recursive delete, so their targets are never
    touched.

    Run it after adding a skill. The post-merge git hook runs it after every pull.

.PARAMETER Force
    Also replace junctions that point outside this repo.

.PARAMETER InstallHook
    Point this repo's git hooks at scripts/hooks, so link-skills runs after every
    pull. Needed once per clone.

.PARAMETER Quiet
    Only print changes and warnings, not skills that are already linked.

.EXAMPLE
    .\scripts\link-skills.ps1 -WhatIf
    Shows what would change without changing anything.

.EXAMPLE
    .\scripts\link-skills.ps1 -InstallHook
    Links all skills and installs the post-merge hook.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force,
    [switch]$InstallHook,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$repoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path.TrimEnd('\')
$skillsDir = Join-Path $env:USERPROFILE '.claude\skills'
$backupDir = Join-Path $env:USERPROFILE '.claude\skills-backup'
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'

function Get-LinkTarget([System.IO.DirectoryInfo]$item) {
    # In PowerShell 5.1, Target is a string array.
    $t = @($item.Target) | Select-Object -First 1
    if ($t) { return $t.TrimEnd('\') }
    return $null
}

function Remove-Junction([string]$path) {
    # Non-recursive delete removes only the link, never the target's files.
    [System.IO.Directory]::Delete($path, $false)
}

function Write-Status([string]$name, [string]$message, [string]$color = 'Gray') {
    Write-Host ('  {0,-32} {1}' -f $name, $message) -ForegroundColor $color
}

if (-not (Test-Path $skillsDir)) {
    if ($PSCmdlet.ShouldProcess($skillsDir, 'Create skills folder')) {
        New-Item -ItemType Directory -Path $skillsDir | Out-Null
    }
}

Write-Host "Linking skills from $repoRoot"
Write-Host "                  into $skillsDir"

$counts = @{ linked = 0; ok = 0; replaced = 0; skipped = 0; removed = 0 }

$skills = Get-ChildItem -Path $repoRoot -Directory |
    Where-Object { -not $_.Name.StartsWith('.') -and (Test-Path (Join-Path $_.FullName 'SKILL.md')) }

foreach ($skill in $skills) {
    $name   = $skill.Name
    $target = $skill.FullName.TrimEnd('\')
    $link   = Join-Path $skillsDir $name

    if (-not (Test-Path -LiteralPath $link)) {
        if ($PSCmdlet.ShouldProcess($link, "Create junction to $target")) {
            New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        }
        Write-Status $name 'linked (new)' 'Green'
        $counts.linked++
        continue
    }

    $item = Get-Item -LiteralPath $link -Force

    if ($item.LinkType -eq 'Junction' -or $item.LinkType -eq 'SymbolicLink') {
        $current = Get-LinkTarget $item
        if ($current -and ($current -ieq $target)) {
            if (-not $Quiet) { Write-Status $name 'ok' }
            $counts.ok++
            continue
        }
        if (-not $Force) {
            Write-Status $name "skipped: links to $current (use -Force to replace)" 'Yellow'
            $counts.skipped++
            continue
        }
        if ($PSCmdlet.ShouldProcess($link, "Replace link to $current with junction to $target")) {
            Remove-Junction $link
            New-Item -ItemType Junction -Path $link -Target $target | Out-Null
        }
        Write-Status $name "relinked (was $current)" 'Green'
        $counts.replaced++
        continue
    }

    # A plain folder: an old copy of the skill. Back it up, then link.
    $backup = Join-Path $backupDir ('{0}-{1}' -f $name, $stamp)
    if ($PSCmdlet.ShouldProcess($link, "Move copy to $backup and create junction to $target")) {
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        Move-Item -LiteralPath $link -Destination $backup
        New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    }
    Write-Status $name "replaced copy (backup: $backup)" 'Green'
    $counts.replaced++
}

# Remove broken junctions that point into this repo.
Get-ChildItem -Path $skillsDir -Directory -Force | ForEach-Object {
    if ($_.LinkType -ne 'Junction' -and $_.LinkType -ne 'SymbolicLink') { return }
    $current = Get-LinkTarget $_
    if (-not $current) { return }
    $inRepo = $current.StartsWith($repoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
    if ($inRepo -and -not (Test-Path -LiteralPath $current)) {
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove broken junction')) {
            Remove-Junction $_.FullName
        }
        Write-Status $_.Name "removed broken link to $current" 'Yellow'
        $counts.removed++
    }
}

if ($InstallHook) {
    if ($PSCmdlet.ShouldProcess($repoRoot, 'Set git core.hooksPath to scripts/hooks')) {
        git -C $repoRoot config core.hooksPath scripts/hooks
    }
    Write-Host 'Installed git hooks: link-skills now runs after every pull.' -ForegroundColor Green
}

Write-Host ('Done: {0} new, {1} replaced, {2} already linked, {3} skipped, {4} removed.' -f `
    $counts.linked, $counts.replaced, $counts.ok, $counts.skipped, $counts.removed)
if ($counts.linked -gt 0 -or $counts.replaced -gt 0) {
    Write-Host 'Claude Code picks up newly linked skills automatically. Restart it if one does not appear.'
}
