# OpenClaw Backup → Cloudflare R2 (via restic)

Backup **completo, criptografado e off-site** da sua instalação do [OpenClaw](https://openclaw.ai), enviado pro Cloudflare R2 usando [restic](https://restic.net).

Faz backup de **tudo** o que importa — config, credenciais, agentes, workspace e tarefas cron — gerando o `.tar.gz` nativo do OpenClaw (`openclaw backup create --verify`) e mandando pro R2 com deduplicação e criptografia client-side. Se sua máquina pifar, você restaura tudo num PC novo baixando do R2.

## Por que isso existe

Mexer na config do OpenClaw é fácil de quebrar (um `doctor --fix` infeliz pode apagar agentes). Com um backup diário automático no R2, você recupera o estado anterior em minutos em vez de remontar tudo na mão.

## O que vai pro backup

| Item | Incluído |
|------|----------|
| `openclaw.json` (config) | ✅ |
| Credenciais / auth profiles | ✅ |
| Agentes e workspaces | ✅ |
| Tarefas cron | ✅ |
| Cache e logs | ❌ (excluídos pra reduzir tamanho) |

Retenção automática: **7 diários + 4 semanais + 6 mensais**.

## Requisitos

- Windows + PowerShell
- [OpenClaw](https://openclaw.ai) instalado
- [restic](https://restic.net/#installation) (no PATH ou em `.\restic\restic.exe`)
- Um bucket no [Cloudflare R2](https://developers.cloudflare.com/r2/) + token de API S3

## Configuração

1. Copie `.env.example` para `.env` e preencha:
   ```
   RESTIC_REPOSITORY=https://<accountid>.r2.cloudflarestorage.com/<seu-bucket>
   AWS_ACCESS_KEY_ID=...
   AWS_SECRET_ACCESS_KEY=...
   ```
2. Crie o arquivo `.restic-pass` com uma senha forte (criptografa seus backups — **guarde em lugar seguro, sem ela não há restore!**).
3. Inicialize o repositório restic uma vez:
   ```powershell
   restic init
   ```

## Uso

**Backup manual:**
```powershell
.\backup.ps1
```
Ou dê dois cliques em `backup-agora.bat`.

**Testar restore (sem tocar na instalação atual):**
```powershell
.\test-restore.ps1
```

**Restore de verdade (em qualquer PC):**
Copie a pasta `portable\` (com `restic\restic.exe`, `.env` e `.restic-pass`) pro PC novo e rode:
```powershell
.\portable\restore-portable.ps1
```
Ele baixa o backup mais recente do R2, e **preserva** a `.openclaw` atual como `.openclaw.backup-<data>` antes de sobrescrever.

## Backup automático (Tarefa Agendada do Windows)

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\caminho\para\backup.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At 12:00
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName "OpenClaw Backup" -Action $action -Trigger $trigger -Settings $settings -Description "Backup diario do OpenClaw para R2"
```
`-StartWhenAvailable` faz o backup rodar assim que o PC ligar, caso estivesse desligado no horário.

## Segurança

- `.env` e `.restic-pass` **nunca** vão pro git (protegidos no `.gitignore`).
- Os backups são criptografados pelo restic **antes** de subir — o R2 só vê dados cifrados.
- As pastas de teste de restore contêm dados sensíveis e também estão no `.gitignore`.

## Licença

MIT.
