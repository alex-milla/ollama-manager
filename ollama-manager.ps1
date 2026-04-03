#Requires -Version 5.1
<#
.SYNOPSIS
    Ollama Manager — Menú interactivo alineado con la guía Claude Code + Ollama (Windows)
.DESCRIPTION
    Permite ejecutar cada paso de instalación y configuración de forma independiente.
#>

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# ============================================
# CONFIGURACIÓN
# ============================================
$script:ModeloRecomendado = "glm-4.7-flash"
$script:ContextLength = "20000"
$script:UrlOllamaWindows = "https://ollama.com/download/windows"

# ============================================
# FUNCIONES DE UTILIDAD
# ============================================

function Mostrar-Encabezado {
    param([string]$Titulo)
    Clear-Host
    Write-Host ""
    Write-Host "    ██████  ██       █████   ██████  █████  ███    ███" -ForegroundColor Cyan
    Write-Host "   ██    ██ ██      ██   ██ ██      ██   ██ ████  ████" -ForegroundColor Cyan
    Write-Host "   ██    ██ ██      ███████ ██      ███████ ██ ████ ██" -ForegroundColor Cyan
    Write-Host "   ██    ██ ██      ██   ██ ██      ██   ██ ██  ██  ██" -ForegroundColor Cyan
    Write-Host "    ██████  ███████ ██   ██  ██████ ██   ██ ██      ██" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "              Manager — Claude Code + Ollama (Windows)" -ForegroundColor Gray
    Write-Host ""
    Write-Host ("-" * 60) -ForegroundColor DarkGray
    if ($Titulo) {
        Write-Host "  $Titulo" -ForegroundColor Yellow
        Write-Host ("-" * 60) -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Pausa {
    Write-Host ""
    Write-Host "  Presiona cualquier tecla para continuar..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Test-OllamaInstalado {
    try {
        $null = Get-Command ollama -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-OllamaCorriendo {
    try {
        $null = ollama ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {}

    try {
        $null = Invoke-WebRequest -Uri "http://localhost:11434" -Method GET -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Get-ModelosInstalados {
    try {
        $output = ollama list 2>$null
        if ($output -match "NAME") {
            $lineas = $output -split "`n" | Select-Object -Skip 1
            $modelos = @()
            foreach ($linea in $lineas) {
                if ($linea.Trim()) {
                    $partes = $linea -split "\s+"
                    $modelos += $partes[0]
                }
            }
            return $modelos
        }
        return @()
    } catch {
        return @()
    }
}

function Get-EstadoGPU {
    try {
        $output = ollama ps 2>$null
        if ($output -match "100% GPU") {
            return "GPU"
        } elseif ($output -match "100% CPU") {
            return "CPU"
        }
        return "Desconocido"
    } catch {
        return "Error"
    }
}

function Test-ComandoExiste {
    param([string]$Nombre)
    try {
        $null = Get-Command $Nombre -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-WingetDisponible {
    return Test-ComandoExiste "winget"
}

# ============================================
# PASOS DE LA GUÍA
# ============================================

function Mostrar-Estado {
    Mostrar-Encabezado -Titulo "Estado del sistema"

    Write-Host "  Ollama" -ForegroundColor Cyan
    Write-Host "    Instalado: " -NoNewline
    if (Test-OllamaInstalado) {
        $version = ollama -v 2>$null
        Write-Host "✓ $version" -ForegroundColor Green
    } else {
        Write-Host "✗ No instalado" -ForegroundColor Red
    }
    Write-Host "    Corriendo: " -NoNewline
    if (Test-OllamaCorriendo) {
        Write-Host "✓ http://localhost:11434" -ForegroundColor Green
        Write-Host "    GPU/CPU (ollama ps): $(Get-EstadoGPU)" -ForegroundColor Gray
    } else {
        Write-Host "✗ No responde" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Modelos Ollama" -ForegroundColor Cyan
    $modelos = Get-ModelosInstalados
    if ($modelos.Count -gt 0) {
        foreach ($modelo in $modelos) {
            $indicador = if ($modelo -eq $script:ModeloRecomendado) { " ← recomendado (guía)" } else { "" }
            Write-Host "    • $modelo" -ForegroundColor White -NoNewline
            Write-Host $indicador -ForegroundColor Yellow
        }
    } else {
        Write-Host "    (ninguno)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Node.js / npm" -ForegroundColor Cyan
    if (Test-ComandoExiste "node") {
        Write-Host "    node:  $(node --version 2>$null)" -ForegroundColor Green
    } else {
        Write-Host "    node:  no instalado (PASO 3 de la guía)" -ForegroundColor Red
    }
    if (Test-ComandoExiste "npm") {
        Write-Host "    npm:   $(npm --version 2>$null)" -ForegroundColor Green
    } else {
        Write-Host "    npm:   no disponible" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Claude Code" -ForegroundColor Cyan
    if (Test-ComandoExiste "claude") {
        Write-Host "    claude: $(claude --version 2>$null)" -ForegroundColor Green
    } else {
        Write-Host "    claude: no instalado (PASO 4 de la guía)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  Variables de entorno (sesión actual)" -ForegroundColor Cyan
    Write-Host "    OLLAMA_CONTEXT_LENGTH: " -NoNewline
    if ($env:OLLAMA_CONTEXT_LENGTH) {
        Write-Host "$env:OLLAMA_CONTEXT_LENGTH" -ForegroundColor Green
    } else {
        Write-Host "(vacío; guía recomienda $script:ContextLength)" -ForegroundColor Yellow
    }
    Write-Host "    ANTHROPIC_BASE_URL: " -NoNewline
    if ($env:ANTHROPIC_BASE_URL -eq "http://localhost:11434") {
        Write-Host "Ollama local ✓" -ForegroundColor Green
    } else {
        Write-Host "$(if ($env:ANTHROPIC_BASE_URL) { $env:ANTHROPIC_BASE_URL } else { '(no configurado)' })" -ForegroundColor Yellow
    }

    Pausa
}

function Paso1-Ollama {
    Mostrar-Encabezado -Titulo "PASO 1 — Instalar Ollama"

    Write-Host "  La instalación oficial es desde la web (instalador .exe)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [1] Abrir la página de descarga para Windows en el navegador" -ForegroundColor White
    Write-Host "  [2] Comprobar si Ollama ya está instalado (ollama -v)" -ForegroundColor White
    Write-Host "  [0] Volver" -ForegroundColor DarkGray
    Write-Host ""

    $op = Read-Host "  Elige (0-2)"
    switch ($op) {
        "1" {
            Start-Process $script:UrlOllamaWindows
            Write-Host ""
            Write-Host "  Cuando termines de instalar, usa la opción [2] o el menú Estado." -ForegroundColor Cyan
            Pausa
        }
        "2" {
            Write-Host ""
            if (Test-OllamaInstalado) {
                ollama -v
                Write-Host ""
                Write-Host "  ✓ Ollama responde." -ForegroundColor Green
            } else {
                Write-Host "  ✗ El comando 'ollama' no está en el PATH." -ForegroundColor Red
                Write-Host "  Instala desde la opción [1] y reinicia PowerShell si hace falta." -ForegroundColor Yellow
            }
            Pausa
        }
        default { return }
    }
}

function Descargar-Modelo {
    Mostrar-Encabezado -Titulo "PASO 2 — Descargar modelo (ollama pull)"

    if (-not (Test-OllamaInstalado)) {
        Write-Host "  ✗ Primero instala Ollama (PASO 1)." -ForegroundColor Red
        Pausa
        return
    }

    Write-Host "  Selecciona un modelo:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] GLM 4.7 Flash — recomendado en la guía (~5-6 GB)" -ForegroundColor White
    Write-Host "  [2] Qwen 2.5 Coder 7B — código (~4 GB)" -ForegroundColor White
    Write-Host "  [3] Llama 3.1 8B — general (~4.7 GB)" -ForegroundColor White
    Write-Host "  [4] Otro (nombre manual)" -ForegroundColor White
    Write-Host "  [0] Volver" -ForegroundColor DarkGray
    Write-Host ""

    $opcion = Read-Host "  Elige (0-4)"
    $nombreModelo = switch ($opcion) {
        "1" { "glm-4.7-flash" }
        "2" { "qwen2.5-coder:7b" }
        "3" { "llama3.1:8b" }
        "4" { Read-Host "  Nombre del modelo (ej. mistral:7b)" }
        "0" { return }
        default { return }
    }

    if ($nombreModelo) {
        Write-Host ""
        Write-Host "  Descargando $nombreModelo..." -ForegroundColor Cyan
        Write-Host ""
        ollama pull $nombreModelo
        Write-Host ""
        Write-Host "  Listo." -ForegroundColor Green
        Pausa
    }
}

function Instalar-NodeJS {
    Mostrar-Encabezado -Titulo "PASO 3 — Instalar Node.js LTS (winget)"

    if (-not (Test-WingetDisponible)) {
        Write-Host "  ✗ 'winget' no está disponible en este sistema." -ForegroundColor Red
        Write-Host "  Instala Node desde https://nodejs.org o actualiza el App Installer." -ForegroundColor Yellow
        Pausa
        return
    }

    Write-Host "  Se instalará: OpenJS.NodeJS.LTS (recomendado en la guía)." -ForegroundColor Cyan
    Write-Host "  winget puede pedir confirmación o permisos de administrador." -ForegroundColor Gray
    Write-Host ""
    $c = Read-Host "  ¿Continuar? (s/n)"
    if ($c -ne "s" -and $c -ne "S") { return }

    Write-Host ""
    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    Write-Host ""
    Write-Host "  Cierra y vuelve a abrir PowerShell; luego comprueba: node --version y npm --version" -ForegroundColor Yellow
    Pausa
}

function Instalar-ClaudeCode {
    Mostrar-Encabezado -Titulo "PASO 4 — Instalar Claude Code (npm)"

    if (-not (Test-ComandoExiste "npm")) {
        Write-Host "  ✗ npm no encontrado. Completa el PASO 3 primero." -ForegroundColor Red
        Pausa
        return
    }

    Write-Host "  Comando: npm install -g @anthropic-ai/claude-code" -ForegroundColor Gray
    Write-Host ""
    $c = Read-Host "  ¿Ejecutar instalación global ahora? (s/n)"
    if ($c -ne "s" -and $c -ne "S") { return }

    Write-Host ""
    npm install -g @anthropic-ai/claude-code
    Write-Host ""
    if (Test-ComandoExiste "claude") {
        claude --version
        Write-Host ""
        Write-Host "  ✓ Claude Code disponible." -ForegroundColor Green
    } else {
        Write-Host "  Si falló, prueba la opción [9] (ExecutionPolicy) y vuelve a abrir PowerShell." -ForegroundColor Yellow
    }
    Pausa
}

function Remover-BloqueConfigPerfil {
    param([string]$ContenidoRaw)
    $c = $ContenidoRaw
    # Bloque correcto (guía)
    $c = $c -replace '(?ms)^# Configuración Claude Code \+ Ollama local\r?\n(?:\$env:[^\r\n]+\r?\n)+', ''
    # Bloque antiguo con typo (compatibilidad)
    $c = $c -replace '(?ms)^# Configuración Claude Code \+ Ollama local\r?\n(?:\$env:ANT_HROPIC[^\r\n]+\r?\n)+', ''
    return $c.TrimEnd()
}

function Configurar-Entorno {
    Mostrar-Encabezado -Titulo "PASO 5 y 6 — Perfil de PowerShell (API + contexto)"

    Write-Host "  Se añadirá a tu `$PROFILE:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host '    $env:ANTHROPIC_BASE_URL = "http://localhost:11434"'
    Write-Host '    $env:ANTHROPIC_AUTH_TOKEN = "ollama"'
    Write-Host '    $env:ANTHROPIC_API_KEY = ""'
    Write-Host ('    $env:OLLAMA_CONTEXT_LENGTH = "' + $script:ContextLength + '"')
    Write-Host ""
    Write-Host "  Tras guardar, cierra y abre PowerShell de nuevo." -ForegroundColor Yellow
    Write-Host ""

    $confirmar = Read-Host "  ¿Aplicar ahora? (s/n)"
    if ($confirmar -ne "s" -and $confirmar -ne "S") { return }

    $perfilPath = $PROFILE
    if (-not (Test-Path $perfilPath)) {
        $dir = Split-Path $perfilPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        New-Item -ItemType File -Path $perfilPath -Force | Out-Null
        Write-Host "  Perfil creado: $perfilPath" -ForegroundColor Green
    }

    $tieneConfig = $false
    if (Test-Path $perfilPath) {
        $raw = Get-Content $perfilPath -Raw -ErrorAction SilentlyContinue
        if ($raw -match 'ANTHROPIC_BASE_URL|ANT_HROPIC_BASE_URL') {
            $tieneConfig = $true
        }
    }

    if ($tieneConfig) {
        Write-Host ""
        Write-Host "  Ya hay bloque de configuración (ANTHROPIC) en el perfil." -ForegroundColor Yellow
        $sobre = Read-Host "  ¿Reemplazarlo por el bloque actual de la guía? (s/n)"
        if ($sobre -ne "s" -and $sobre -ne "S") { Pausa; return }

        $contenido = Get-Content $perfilPath -Raw
        $contenido = Remover-BloqueConfigPerfil -ContenidoRaw $contenido
        Set-Content -Path $perfilPath -Value $contenido -NoNewline
        Add-Content -Path $perfilPath -Value "`r`n"
    }

    $configuracion = @"

# Configuración Claude Code + Ollama local
`$env:ANTHROPIC_BASE_URL = `"http://localhost:11434`"
`$env:ANTHROPIC_AUTH_TOKEN = `"ollama`"
`$env:ANTHROPIC_API_KEY = `"`"
`$env:OLLAMA_CONTEXT_LENGTH = `"$($script:ContextLength)`"
"@

    Add-Content -Path $perfilPath -Value $configuracion

    Write-Host ""
    Write-Host "  ✓ Guardado en: $perfilPath" -ForegroundColor Green
    Write-Host "  Reinicia PowerShell para cargar las variables." -ForegroundColor Yellow
    Pausa
}

function Reparar-ExecutionPolicy {
    Mostrar-Encabezado -Titulo "Reparar — ExecutionPolicy (npm / scripts)"

    Write-Host "  Si npm muestra error con npm.ps1 y scripts deshabilitados, ejecuta:" -ForegroundColor Gray
    Write-Host '    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser' -ForegroundColor White
    Write-Host ""
    $c = Read-Host "  ¿Aplicar RemoteSigned para el usuario actual? (s/n)"
    if ($c -ne "s" -and $c -ne "S") { return }

    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host ""
        Write-Host "  ✓ Hecho. Cierra y vuelve a abrir PowerShell." -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "  ✗ $_" -ForegroundColor Red
        Write-Host "  Prueba abriendo PowerShell como Administrador." -ForegroundColor Yellow
    }
    Pausa
}

function Iniciar-Ollama {
    Mostrar-Encabezado -Titulo "Iniciar Ollama"

    if (Test-OllamaCorriendo) {
        Write-Host "  Ollama ya está en ejecución." -ForegroundColor Green
        Pausa
        return
    }

    Write-Host "  Buscando Ollama..." -ForegroundColor Cyan
    $ollamaPath = $null
    $ubicaciones = @(
        (Get-Command ollama -ErrorAction SilentlyContinue).Source,
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "$env:ProgramFiles\Ollama\ollama.exe",
        "${env:ProgramFiles(x86)}\Ollama\ollama.exe"
    )

    foreach ($ubicacion in $ubicaciones) {
        if ($ubicacion -and (Test-Path $ubicacion)) {
            $ollamaPath = $ubicacion
            break
        }
    }

    if (-not $ollamaPath) {
        Write-Host "  ✗ No se encontró ollama.exe." -ForegroundColor Red
        Write-Host "  Descarga: $script:UrlOllamaWindows" -ForegroundColor Yellow
        Pausa
        return
    }

    Write-Host "  Ruta: $ollamaPath" -ForegroundColor Green
    Write-Host "  Iniciando..." -ForegroundColor Cyan

    try {
        $proceso = Start-Process -FilePath $ollamaPath -WindowStyle Hidden -PassThru
        $max = 20
        for ($i = 0; $i -lt $max; $i++) {
            Start-Sleep -Seconds 1
            if (Test-OllamaCorriendo) {
                Write-Host ""
                Write-Host "  ✓ Ollama responde (PID $($proceso.Id))." -ForegroundColor Green
                Pausa
                return
            }
        }

        if (-not $proceso.HasExited) {
            Stop-Process -Id $proceso.Id -Force -ErrorAction SilentlyContinue
        }
        $proceso = Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden -PassThru
        for ($i = 0; $i -lt $max; $i++) {
            Start-Sleep -Seconds 1
            if (Test-OllamaCorriendo) {
                Write-Host ""
                Write-Host "  ✓ Ollama responde (ollama serve)." -ForegroundColor Green
                Pausa
                return
            }
        }
        if (-not $proceso.HasExited) {
            Stop-Process -Id $proceso.Id -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "  ✗ $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  No se pudo confirmar el arranque. Abre Ollama desde el menú Inicio." -ForegroundColor Yellow
    Pausa
}

function Lanzar-ClaudeCode {
    Mostrar-Encabezado -Titulo "PASO 7 — Lanzar Claude Code"

    if (-not (Test-OllamaInstalado)) {
        Write-Host "  ✗ Ollama no instalado (PASO 1)." -ForegroundColor Red
        Pausa
        return
    }
    if (-not (Test-OllamaCorriendo)) {
        Write-Host "  ⚠ Ollama no responde. Usa [8] Iniciar Ollama o el menú Inicio." -ForegroundColor Yellow
        Pausa
        return
    }

    $modelos = Get-ModelosInstalados
    if ($modelos.Count -eq 0) {
        Write-Host "  ✗ No hay modelos. Descarga uno en PASO 2." -ForegroundColor Red
        Pausa
        return
    }

    Write-Host "  Modelo:" -ForegroundColor Cyan
    $i = 1
    foreach ($modelo in $modelos) {
        $star = if ($modelo -eq $script:ModeloRecomendado) { " ★" } else { "" }
        Write-Host "  [$i] $modelo" -NoNewline -ForegroundColor White
        Write-Host $star -ForegroundColor Yellow
        $i++
    }
    Write-Host "  [0] Volver" -ForegroundColor DarkGray
    Write-Host ""
    $sel = Read-Host "  Número de modelo (0-$($modelos.Count))"
    if ($sel -eq "0" -or $sel -eq "") { return }

    $index = 0
    try {
        $index = [int]$sel - 1
    } catch {
        return
    }
    if ($index -lt 0 -or $index -ge $modelos.Count) { return }

    $modeloElegido = $modelos[$index]

    Write-Host ""
    Write-Host "  Forma de lanzar (guía PASO 7):" -ForegroundColor Cyan
    Write-Host "  [A] ollama launch claude --model <modelo>  (integración Ollama)" -ForegroundColor White
    Write-Host "  [B] claude --model <modelo>                 (CLI estándar)" -ForegroundColor White
    Write-Host ""

    $modo = Read-Host "  Elige A o B (por defecto B)"
    if ($modo -eq "A" -or $modo -eq "a") {
        Write-Host ""
        Write-Host "  Ejecutando: ollama launch claude --model $modeloElegido" -ForegroundColor Cyan
        Write-Host ""
        ollama launch claude --model $modeloElegido
        Pausa
        return
    }

    if (-not (Test-ComandoExiste "claude")) {
        Write-Host "  ✗ 'claude' no está en el PATH. Instala con PASO 4." -ForegroundColor Red
        Pausa
        return
    }

    Write-Host ""
    Write-Host "  Ejecutando: claude --model $modeloElegido  (/bye para salir)" -ForegroundColor Cyan
    Write-Host ""
    claude --model $modeloElegido
    Pausa
}

function Ver-Documentacion {
    Mostrar-Encabezado -Titulo "Guía (Markdown)"

    $archivoGuia = Get-ChildItem -Path $PSScriptRoot -Filter "Guia-claude-code-ollama*.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $archivoGuia) {
        $archivoGuia = Get-ChildItem -Filter "Guia-claude-code-ollama*.md" -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    if ($archivoGuia) {
        Write-Host "  Abriendo: $($archivoGuia.Name)" -ForegroundColor Green
        Start-Process notepad.exe -ArgumentList $archivoGuia.FullName
    } else {
        Write-Host "  No se encontró Guia-claude-code-ollama*.md junto al script." -ForegroundColor Red
    }
    Pausa
}

# ============================================
# MENÚ PRINCIPAL
# ============================================

function Mostrar-MenuPrincipal {
    while ($true) {
        Mostrar-Encabezado

        $okOllama = Test-OllamaCorriendo
        $nModelos = (Get-ModelosInstalados).Count
        $estadoLinea = if ($okOllama) { "Ollama: OK" } else { "Ollama: no responde" }

        Write-Host "  $estadoLinea  |  Modelos: $nModelos" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  ╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║     Instalación y uso (misma numeración que la guía)        ║" -ForegroundColor Cyan
        Write-Host "  ╠════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
        Write-Host "  ║  [1]  Estado completo (Ollama, Node, Claude, variables)     ║" -ForegroundColor White
        Write-Host "  ║  [2]  PASO 1 — Ollama (descarga / comprobar)                ║" -ForegroundColor White
        Write-Host "  ║  [3]  PASO 2 — Descargar modelo (ollama pull)                ║" -ForegroundColor White
        Write-Host "  ║  [4]  PASO 3 — Instalar Node.js LTS (winget)                ║" -ForegroundColor White
        Write-Host "  ║  [5]  PASO 4 — Instalar Claude Code (npm)                   ║" -ForegroundColor White
        Write-Host "  ║  [6]  PASO 5 y 6 — Variables en `$PROFILE + contexto         ║" -ForegroundColor White
        Write-Host "  ║  [7]  Iniciar Ollama (si no está activo)                    ║" -ForegroundColor White
        Write-Host "  ║  [8]  PASO 7 — Lanzar Claude Code (elegir modelo y modo)    ║" -ForegroundColor Green
        Write-Host "  ║  [9]  Reparar ExecutionPolicy (error npm.ps1)               ║" -ForegroundColor White
        Write-Host "  ║  [10] Abrir guía .md en Bloc de notas                       ║" -ForegroundColor White
        Write-Host "  ║  [0]  Salir                                                 ║" -ForegroundColor DarkGray
        Write-Host "  ╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Pasos 8-9 de la guía (proyecto, git): revisa el .md con [10]." -ForegroundColor DarkGray
        Write-Host ""

        $opcion = Read-Host "  Opción (0-10)"

        switch ($opcion) {
            "1"  { Mostrar-Estado }
            "2"  { Paso1-Ollama }
            "3"  { Descargar-Modelo }
            "4"  { Instalar-NodeJS }
            "5"  { Instalar-ClaudeCode }
            "6"  { Configurar-Entorno }
            "7"  { Iniciar-Ollama }
            "8"  { Lanzar-ClaudeCode }
            "9"  { Reparar-ExecutionPolicy }
            "10" { Ver-Documentacion }
            "0"  {
                Clear-Host
                Write-Host ""
                Write-Host "  ¡Hasta pronto!" -ForegroundColor Cyan
                Write-Host ""
                exit 0
            }
            default {
                Write-Host ""
                Write-Host "  Opción no válida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

$esAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $esAdmin) {
    Write-Host ""
    Write-Host "  Nota: winget (PASO 3) puede requerir ventana elevada." -ForegroundColor DarkGray
    Write-Host ""
}

Mostrar-MenuPrincipal
