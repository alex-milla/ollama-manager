# Ollama Manager (`ollama-manager.ps1`)

Script de **PowerShell 5.1+** para Windows que ofrece un **menú interactivo por consola** para instalar y configurar el entorno **Claude Code** con **Ollama** en local (modelos en tu PC, sin API de Anthropic en la nube).

Está pensado para seguir la misma numeración de pasos que una guía típica (“PASO 1… PASO 7…”), de modo que puedas ejecutar **cada fase por separado** o repetir solo lo que necesites.

---

## Requisitos

- Windows 10 u 11  
- [PowerShell](https://learn.microsoft.com/powershell/) 5.1 o superior (incluido en Windows)  
- Permisos según la acción: algunas opciones funcionan mejor con PowerShell **como administrador** (p. ej. `winget`)

---

## Cómo ejecutarlo

Desde la carpeta donde esté el script:

```powershell
powershell -ExecutionPolicy Bypass -File .\ollama-manager.ps1
```

Si la política de ejecución lo bloquea, puedes usar antes (como usuario actual):

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Configuración interna del script

Al inicio del archivo se definen variables que puedes editar si quieres otro modelo o contexto:

| Variable | Valor por defecto | Uso |
|----------|-------------------|-----|
| `$script:ModeloRecomendado` | `glm-4.7-flash` | Modelo marcado como recomendado en listados y menús |
| `$script:ContextLength` | `20000` | Tokens de contexto que se escriben en el perfil para `OLLAMA_CONTEXT_LENGTH` |
| `$script:UrlOllamaWindows` | página de descarga de Ollama para Windows | Se abre en el navegador en el PASO 1 |

---

## Qué hace el menú principal

Al iniciar, el script muestra un **resumen rápido** (si Ollama responde y cuántos modelos hay instalados) y un menú numerado. Cada opción llama a una función concreta.

### Opción `[1]` — Estado del sistema

Comprueba y muestra en pantalla:

- Si **Ollama** está instalado (`ollama` en PATH) y su versión  
- Si el servicio responde (vía `ollama ps` y, si hace falta, `http://localhost:11434`)  
- **Modelos** instalados según `ollama list` (destaca el modelo recomendado)  
- Indicación aproximada de uso **GPU vs CPU** según la salida de `ollama ps`  
- **Node.js** y **npm** (`node --version`, `npm --version`)  
- **Claude Code** (`claude --version`)  
- Variables de la **sesión actual**: `OLLAMA_CONTEXT_LENGTH` y `ANTHROPIC_BASE_URL`

Sirve para diagnosticar qué falta antes de lanzar Claude Code.

### Opción `[2]` — PASO 1: Ollama

Submenú:

1. **Abrir en el navegador** la URL de descarga del instalador de Ollama para Windows.  
2. **Comprobar instalación** ejecutando `ollama -v` y mostrando si el comando existe.

Ollama no se instala por línea de comandos desde este script; se guía al instalador oficial.

### Opción `[3]` — PASO 2: Descargar modelo (`ollama pull`)

Ejecuta `ollama pull` con el modelo elegido:

- **GLM 4.7 Flash** (recomendado por defecto en el script)  
- **Qwen 2.5 Coder 7B**  
- **Llama 3.1 8B**  
- **Otro nombre** que escribas a mano  

Requiere que Ollama esté instalado y, para descargar, que el daemon esté operativo según tu entorno.

### Opción `[4]` — PASO 3: Instalar Node.js LTS (`winget`)

Si `winget` está disponible, ejecuta la instalación del paquete **OpenJS.NodeJS.LTS** (Node LTS), alineado con el flujo habitual de “instalar Node en Windows sin ir a la web”.

Puede pedir confirmación o **elevación**; el script avisa de que a veces hace falta PowerShell como administrador.

### Opción `[5]` — PASO 4: Instalar Claude Code (`npm`)

Ejecuta:

```text
npm install -g @anthropic-ai/claude-code
```

Comprueba al final si el comando `claude` queda disponible. Si falla por políticas de ejecución, remite a la opción `[9]`.

### Opción `[6]` — PASO 5 y 6: Perfil de PowerShell (API + contexto)

**Escribe en tu archivo de perfil de PowerShell** (`$PROFILE`) un bloque que define:

- `$env:ANTHROPIC_BASE_URL = "http://localhost:11434"` — apunta Claude Code a tu Ollama local  
- `$env:ANTHROPIC_AUTH_TOKEN = "ollama"`  
- `$env:ANTHROPIC_API_KEY = ""`  
- `$env:OLLAMA_CONTEXT_LENGTH = "<valor de $script:ContextLength>"` — p. ej. `20000`

Si ya existía un bloque similar, puede **sustituirlo** tras confirmación (incluye lógica para limpiar bloques antiguos mal nombrados tipo `ANT_HROPIC_*`).

Después de guardar, debes **cerrar y abrir** PowerShell para que las variables se carguen en sesiones nuevas.

### Opción `[7]` — Iniciar Ollama

Si Ollama no responde, intenta localizar `ollama.exe` en rutas habituales y arrancarlo (incluye intento con `serve` si hace falta). Si no consigue dejarlo escuchando, indica abrir Ollama desde el menú Inicio de Windows.

### Opción `[8]` — PASO 7: Lanzar Claude Code

1. Comprueba Ollama y que haya **al menos un modelo** en `ollama list`.  
2. Te deja **elegir un modelo** de la lista.  
3. Te pregunta el **modo de lanzamiento**:  
   - **A** — `ollama launch claude --model <modelo>` (integración vía Ollama)  
   - **B** — `claude --model <modelo>` (CLI estándar; requiere `claude` en PATH)

### Opción `[9]` — Reparar ExecutionPolicy (error con `npm.ps1`)

Aplica para el usuario actual:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Útil cuando npm no puede ejecutar scripts y aparecen errores del tipo “running scripts is disabled”.

### Opción `[10]` — Abrir guía en Markdown

Busca en la carpeta del script un archivo cuyo nombre coincida con `Guia-claude-code-ollama*.md` y lo abre con el **Bloc de notas**. Si no hay ningún `.md`, muestra un mensaje de error.

### Opción `[0]` — Salir

Termina el script con código `0`.

---

## Comportamiento visual y utilidades internas

- **Encabezado ASCII** y títulos por sección (`Mostrar-Encabezado`).  
- **Pausa** con “presiona una tecla” para leer la salida antes de volver al menú (`Pausa`).  
- Comprobaciones auxiliares: `Test-OllamaInstalado`, `Test-OllamaCorriendo`, `Get-ModelosInstalados`, `Get-EstadoGPU`, `Test-ComandoExiste`, `Test-WingetDisponible`.

---

## Limitaciones y buenas prácticas

- No sustituye la documentación de [Ollama](https://ollama.com), [Node.js](https://nodejs.org) ni [Claude Code](https://www.anthropic.com/claude-code); automatiza y agrupa comandos habituales en Windows.  
- Tras instalar Node o cambiar el perfil, **reinicia la terminal** para PATH y variables.  
- El uso de GPU/CPU depende de drivers, modelo y máquina; el script solo **muestra** lo que devuelve `ollama ps`.

---

## Licencia

Define la licencia del repositorio según tu criterio (este documento no impone ninguna).
