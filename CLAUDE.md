# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a documentation repository containing a Spanish-language guide for setting up Claude Code with Ollama on Windows. It includes a step-by-step tutorial and an interactive PowerShell menu system.

## File Structure

- `Guia-claude-code-ollama-v2 - Windows - YYYYMMDD.md` — The guide document with setup instructions
- `ollama-manager.ps1` — Interactive PowerShell menu for managing Ollama and Claude Code
- `ollama-manager.bat` — Launcher batch file for the PowerShell menu (double-click to run)

## PowerShell Script Architecture

`ollama-manager.ps1` is structured as follows:

**Configuration Variables (lines 16-17):**
- `$script:ModeloRecomendado` — Default model for Claude Code (`glm-4.7-flash`)
- `$script:ContextLength` — Ollama context length (`20000` tokens)

**Utility Functions (lines 23-99):**
- `Mostrar-Encabezado` — Renders ASCII header and section titles
- `Pausa` — Waits for key press
- `Test-OllamaInstalado` — Checks if `ollama` command exists
- `Test-OllamaCorriendo` — Tests HTTP endpoint at `localhost:11434`
- `Get-ModelosInstalados` — Parses `ollama list` output
- `Get-EstadoGPU` — Checks GPU/CPU usage via `ollama ps`

**Menu Functions (lines 105-337):**
Each menu option has its own function:
- `Mostrar-Estado` — System status display
- `Descargar-Modelo` — Model download with predefined options
- `Configurar-Entorno` — Writes environment variables to `$PROFILE`
- `Iniciar-Ollama` — Attempts to start Ollama service
- `Lanzar-ClaudeCode` — Launches `claude --model <selected>`
- `Ver-Documentacion` — Opens guide in Notepad

**Environment Variables Written to `$PROFILE`:**
```powershell
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY = ""
$env:OLLAMA_CONTEXT_LENGTH = "20000"
```

## Editing Guidelines

- Maintain the numbered step format (PASO 1, PASO 2, etc.)
- Keep code examples in PowerShell syntax
- Preserve the Spanish language throughout
- Use `YYYYMMDD` date format in filenames when creating new versions

## Batch File Launcher

`ollama-manager.bat` is a simple wrapper that:
1. Sets UTF-8 encoding (`chcp 65001`)
2. Verifies PowerShell availability
3. Executes the `.ps1` script with `-ExecutionPolicy Bypass`

## Common Model References

When updating recommendations, these are the predefined models in the menu:
- `glm-4.7-flash` — Recommended (5-6 GB, balanced)
- `qwen2.5-coder:7b` — Lightweight alternative for code (~4 GB)
- `llama3.1:8b` — General purpose (~4.7 GB)
