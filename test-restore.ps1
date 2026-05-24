$ErrorActionPreference = 'Stop'

# ============================================================
# Testa o restore SEM tocar na sua instalacao do OpenClaw.
# Baixa o backup mais recente do R2, extrai e valida com
# "openclaw backup verify". A pasta restaurada fica intacta
# pra voce inspecionar.
# ============================================================

$BaseDir = $PSScriptRoot

$ResticExe = (Get-Command restic -ErrorAction SilentlyContinue).Source
if (-not $ResticExe) { $ResticExe = Join-Path $BaseDir 'restic\restic.exe' }
if (-not (Test-Path $ResticExe)) { throw "restic nao encontrado." }

$OpenClaw = (Get-Command openclaw -ErrorAction SilentlyContinue).Source
if (-not $OpenClaw) { $OpenClaw = Join-Path $env:APPDATA 'npm\openclaw.cmd' }

# carrega credenciais R2
Get-Content (Join-Path $BaseDir '.env') | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
  $name, $value = $line.split('=', 2)
  if ($name) { Set-Item -Path "env:$($name.Trim())" -Value $value.Trim() }
}
Set-Item -Path 'env:RESTIC_PASSWORD_FILE' -Value (Join-Path $BaseDir '.restic-pass')
if ($env:RESTIC_REPOSITORY -and -not ($env:RESTIC_REPOSITORY -match '^s3:')) {
  if ($env:RESTIC_REPOSITORY -match '^https?://') {
    $env:RESTIC_REPOSITORY = 's3:' + $env:RESTIC_REPOSITORY.TrimEnd('/')
  }
}

$RestoreDir = Join-Path $BaseDir ('restore-test-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $RestoreDir -Force | Out-Null

Write-Host "`n=== 1) restic check ===" -ForegroundColor Cyan
& $ResticExe check

Write-Host "`n=== 2) snapshots (preview) ===" -ForegroundColor Cyan
& $ResticExe snapshots

Write-Host "`n=== 3) restore latest ===" -ForegroundColor Cyan
& $ResticExe restore latest --target $RestoreDir

$restoredTar = Get-ChildItem $RestoreDir -Recurse -Filter '*-openclaw-backup.tar.gz' | Select-Object -First 1
if (-not $restoredTar) { Write-Host 'Nao encontrei tar.gz restaurado!' -ForegroundColor Red; exit 1 }
Write-Host "Tar restaurado: $($restoredTar.FullName)" -ForegroundColor Green

Write-Host "`n=== 4) openclaw backup verify (PROVA REAL) ===" -ForegroundColor Cyan
& $OpenClaw backup verify $restoredTar.FullName

if ($LASTEXITCODE -eq 0) {
  Write-Host "`n[OK] RESTORE TESTADO E VALIDADO pelo OPENCLAW" -ForegroundColor Green
  Write-Host "Pasta de teste (inspecione e apague quando quiser): $RestoreDir" -ForegroundColor Yellow
} else {
  Write-Host "`n[FALHA] verify retornou erro - investigar!" -ForegroundColor Red
  exit 1
}
