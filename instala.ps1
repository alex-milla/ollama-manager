# Comprobación de permisos de Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "⚠️ Por favor, cierra esta ventana y vuelve a abrir PowerShell como Administrador para que el menú funcione correctamente."
    Start-Sleep -Seconds 4
    exit
}

function Show-Menu {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "       MENÚ: CLAUDE CODE + OLLAMA (RTX 3060 12GB)         " -ForegroundColor White -BackgroundColor Blue
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " 1. Paso 1: Instalar Ollama"
    Write-Host " 2. Paso 2: Descargar modelo recomendado (GLM 4.7 Flash)"
    Write-Host " 3. Paso 3: Instalar Node.js y configurar permisos npm"
    Write-Host " 4. Paso 4: Instalar Claude Code"
    Write-Host " 5. Pasos 5 y 6: Configurar Perfil (API y Contexto a 20000)"
    Write-Host " 6. Paso 7: Lanzar Claude Code"
    Write-Host " 7. Ejecutar instalación completa (Pasos 1 al 5)"
    Write-Host " 0. Salir"
    Write-Host "==========================================================" -ForegroundColor Cyan
}

while ($true) {
    Show-Menu
    $choice = Read-Host "`nElige una opción (0-7)"

    switch ($choice) {
        '1' {
            Write-Host "`n[Paso 1] Instalando Ollama..." -ForegroundColor Yellow
            winget install -e --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
            Write-Host "Iniciando Ollama en segundo plano..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 3
            ollama -v
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '2' {
            Write-Host "`n[Paso 2] Descargando modelo GLM 4.7 Flash (5-6 GB)..." -ForegroundColor Yellow
            ollama pull glm-4.7-flash
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '3' {
            Write-Host "`n[Paso 3] Instalando Node.js (LTS)..." -ForegroundColor Yellow
            winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            
            Write-Host "Configurando políticas de ejecución para evitar errores de scripts..." -ForegroundColor Yellow
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            
            # Actualizamos el PATH temporalmente en esta sesión
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Host "Verificando versiones:" -ForegroundColor Cyan
            node --version
            npm --version
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '4' {
            Write-Host "`n[Paso 4] Instalando Claude Code globalmente..." -ForegroundColor Yellow
            npm install -g @anthropic-ai/claude-code
            Write-Host "Verificando instalación:" -ForegroundColor Cyan
            claude --version
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '5' {
            Write-Host "`n[Pasos 5 y 6] Configurando variables de entorno en el Perfil..." -ForegroundColor Yellow
            $profilePath = $PROFILE
            if (!(Test-Path $profilePath)) {
                New-Item -Path $profilePath -ItemType File -Force | Out-Null
            }

            $configLines = @(
                "",
                "# Configuración Claude Code + Ollama local",
                '$env:ANTHROPIC_BASE_URL = "http://localhost:11434"',
                '$env:ANTHROPIC_AUTH_TOKEN = "ollama"',
                '$env:ANTHROPIC_API_KEY = ""',
                '$env:OLLAMA_CONTEXT_LENGTH = "20000"'
            )

            $currentProfile = Get-Content $profilePath -ErrorAction SilentlyContinue
            if ($currentProfile -notmatch "ANTHROPIC_BASE_URL") {
                Add-Content -Path $profilePath -Value $configLines
                Write-Host "¡Perfil actualizado con éxito!" -ForegroundColor Green
                Write-Host "⚠️ DEBES REINICIAR POWERSHELL para que estos cambios hagan efecto." -ForegroundColor Red
            } else {
                Write-Host "Las variables ya estaban configuradas en tu perfil." -ForegroundColor Cyan
            }
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '6' {
            Write-Host "`n[Paso 7] Lanzando Claude Code con tu modelo local..." -ForegroundColor Yellow
            Write-Host "Recuerda que debes estar en la carpeta de tu proyecto." -ForegroundColor DarkGray
            ollama launch claude --model glm-4.7-flash
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '7' {
            Write-Host "`nEjecutando instalación automatizada (Pasos 1 a 5)..." -ForegroundColor Magenta
            
            winget install -e --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
            Start-Sleep -Seconds 3
            ollama pull glm-4.7-flash
            
            winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            npm install -g @anthropic-ai/claude-code
            
            $profilePath = $PROFILE
            if (!(Test-Path $profilePath)) { New-Item -Path $profilePath -ItemType File -Force | Out-Null }
            $configLines = @(
                "",
                "# Configuración Claude Code + Ollama local",
                '$env:ANTHROPIC_BASE_URL = "http://localhost:11434"',
                '$env:ANTHROPIC_AUTH_TOKEN = "ollama"',
                '$env:ANTHROPIC_API_KEY = ""',
                '$env:OLLAMA_CONTEXT_LENGTH = "20000"'
            )
            $currentProfile = Get-Content $profilePath -ErrorAction SilentlyContinue
            if ($currentProfile -notmatch "ANTHROPIC_BASE_URL") { Add-Content -Path $profilePath -Value $configLines }
            
            Write-Host "`n¡Instalación completa terminada!" -ForegroundColor Green
            Write-Host "⚠️ Cierra PowerShell y ábrelo de nuevo antes de lanzar Claude Code (Opción 6)." -ForegroundColor Red
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        '0' {
            Write-Host "`nSaliendo del asistente... ¡Hasta pronto!" -ForegroundColor Cyan
            break
        }
        default {
            Write-Warning "Opción no válida. Por favor, elige un número del 0 al 7."
            Start-Sleep -Seconds 2
        }
    }
}