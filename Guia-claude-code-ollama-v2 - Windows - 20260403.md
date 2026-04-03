# Guía: Claude Code + Ollama en Windows (para novatos)

## ¿Qué vas a conseguir?

Al terminar esta guía tendrás **Claude Code funcionando en tu PC con tu RTX 3060**, usando modelos locales de Ollama. Podrás pedirle en lenguaje natural que edite tu código, revise tu proyecto y haga commits en git, **sin pagar nada y sin límites de uso**.

---

## Lo que necesitas antes de empezar

- Windows 10 o Windows 11
- RTX 3060 con 12 GB (ya la tienes ✅)
- Conexión a internet para las descargas iniciales
- Unos **15-20 GB libres** en el disco duro
- Tiempo: unos **20-30 minutos**

---

## PASO 1 — Instalar Ollama

1. Ve a [https://ollama.com](https://ollama.com) y descarga el instalador para Windows.
2. Ejecuta el instalador y sigue los pasos (siguiente, siguiente, instalar).
3. Cuando termine, Ollama se queda corriendo en segundo plano (verás un icono en la barra de tareas).

**Verificar que funciona:**
Abre PowerShell (botón derecho en el menú Inicio → "Windows PowerShell") y escribe:

```powershell
ollama -v
```

Deberías ver algo como `ollama version is 0.15.x`. Si lo ves, **Ollama está listo**.

---

## PASO 2 — Descargar el modelo recomendado

Para tu RTX 3060 de 12 GB, el modelo más equilibrado para Claude Code es **GLM 4.7 Flash**. Es rápido, entiende órdenes complejas y cabe bien en tu VRAM.

En la misma ventana de PowerShell escribe:

```powershell
ollama pull glm-4.7-flash
```

Esto descargará el modelo (unos **5-6 GB**). Espera a que termine. Verás una barra de progreso.

> 💡 **Alternativa:** Si prefieres un modelo más orientado a código puro, puedes usar `qwen2.5-coder:7b` en su lugar. El comando sería `ollama pull qwen2.5-coder:7b`.

---

## PASO 3 — Instalar Node.js (necesario para Claude Code)

Claude Code requiere Node.js para funcionar. La forma más cómoda en Windows es usando **winget**, el gestor de paquetes oficial de Microsoft que ya viene instalado en Windows 10/11. Sin descargar nada del navegador, todo desde la terminal.

**Abre PowerShell como Administrador** (botón derecho en el menú Inicio → "Windows PowerShell (Admin)") y ejecuta:

```powershell
winget install -e --id OpenJS.NodeJS.LTS
```

> 💡 Esto instala la versión **LTS** (Long Term Support), la más estable y recomendada. Winget añade Node.js al PATH automáticamente.

Si quieres ver primero qué versiones hay disponibles:

```powershell
winget search OpenJS.NodeJS
```

Verás una lista como esta:

```
Name              Id                    Version
-----------------------------------------------
Node.js           OpenJS.NodeJS         25.x.x
Node.js (LTS)     OpenJS.NodeJS.LTS     22.x.x   ← usa esta
Node.js 20        OpenJS.NodeJS.20      20.x.x
```

**Después de instalar, cierra y vuelve a abrir PowerShell** para que reconozca los nuevos comandos. Luego verifica:

```powershell
node --version
npm --version
```

Deberías ver los números de versión de ambos. Si los ves, **Node.js está listo**.

### ❌ Si npm da error de "scripts deshabilitados"

Si ves el mensaje `npm.ps1 cannot be loaded because running scripts is disabled`, ejecuta esto en PowerShell como Administrador:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Cierra y vuelve a abrir PowerShell. Problema resuelto.

---

## PASO 4 — Instalar Claude Code

Con Node.js ya instalado, en PowerShell escribe:

```powershell
npm install -g @anthropic-ai/claude-code
```

Esto instala Claude Code globalmente en tu PC. Tarda unos minutos.

Verifica que funciona:

```powershell
claude --version
```

---

## PASO 5 — Configurar la API para usar Ollama local

Antes de lanzar Claude Code, hay que decirle que **no use los servidores de Anthropic** sino tu Ollama local. Esto se hace configurando unas variables de entorno de forma permanente en PowerShell.

### Hacerlo permanente (recomendado)

Así no tendrás que configurar nada cada vez que abras PowerShell:

1. En PowerShell escribe:

```powershell
notepad $PROFILE
```

2. Si te pregunta si quieres crear el archivo, di que **Sí**.
3. En el Bloc de notas que se abre, añade estas líneas al final:

```powershell
# Configuración Claude Code + Ollama local
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY = ""
```

4. Guarda el archivo y ciérralo.
5. **Cierra y vuelve a abrir PowerShell** para que se aplique.

Verifica que las variables están activas:

```powershell
echo $env:ANTHROPIC_BASE_URL
```

Deberías ver: `http://localhost:11434`

> ⚠️ **¿Por qué estas variables?** `ANTHROPIC_BASE_URL` le dice a Claude Code dónde está el servidor de IA. Al apuntarlo a `localhost:11434` (donde escucha Ollama), Claude Code usará tu modelo local en lugar de los servidores de Anthropic. La `API_KEY` puede quedar vacía porque Ollama no la necesita.

---

## PASO 6 — Configurar el contexto largo (importante)

Claude Code necesita mucha "memoria de conversación" (contexto largo). Hay que decirle a Ollama que lo active añadiendo otra línea al mismo perfil de PowerShell:

1. Vuelve a abrir el perfil:

```powershell
notepad $PROFILE
```

2. Añade esta línea justo debajo de las anteriores:

```powershell
$env:OLLAMA_CONTEXT_LENGTH = "20000"
```

3. Guarda, cierra y **reinicia PowerShell**.

> 💡 **¿Por qué 20000?** Claude Code envía instrucciones muy largas al modelo. Con menos de 20.000 tokens el modelo puede "olvidar" partes importantes del proyecto. Más de 20.000 puede hacerlo lento en tu RTX 3060.

El perfil completo debería quedar así:

```powershell
# Configuración Claude Code + Ollama local
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY = ""
$env:OLLAMA_CONTEXT_LENGTH = "20000"
```

---

## PASO 7 — Lanzar Claude Code con tu modelo local

Con todo configurado, ya puedes lanzar Claude Code. Hay dos formas:

### Opción A — Comando directo de Ollama (la más fácil)

```powershell
ollama launch claude --model glm-4.7-flash
```

Ollama se encarga de todo automáticamente.

### Opción B — Comando estándar de Claude Code

```powershell
claude --model glm-4.7-flash
```

Como ya configuraste las variables en el Paso 5, Claude Code sabe que tiene que conectarse a Ollama.

> 💡 Ambas opciones hacen exactamente lo mismo. Usa la que más te guste.

---

## PASO 8 — Usar Claude Code con tu proyecto

### Abrir tu proyecto

1. Navega a la carpeta de tu proyecto en PowerShell:

```powershell
cd C:\TusProyectos\MiApp
```

2. Lanza Claude Code:

```powershell
ollama launch claude --model glm-4.7-flash
```

### Comandos útiles dentro de Claude Code

Una vez dentro verás una interfaz de texto. Puedes escribir en español directamente:

```
> Explícame qué hace este proyecto
> Añade validación al formulario de login en forms.py
> Busca y corrige los errores en el archivo main.js
> Crea un README para este proyecto
> Haz un commit con todos los cambios de hoy
```

### Modo Planning (planificación antes de actuar)

Antes de que Claude Code empiece a editar archivos, puedes pedirle que te explique el plan:

- Pulsa **Shift + Tab dos veces** para activar el modo Planning
- Claude Code te dirá qué va a hacer antes de hacerlo
- Si te parece bien, dile que continúe

### Comandos especiales

| Comando | Qué hace |
|---|---|
| `/model` | Ver qué modelo estás usando |
| `/help` | Ver todos los comandos disponibles |
| `/bye` o `Ctrl+C` | Salir de Claude Code |
| `/clear` | Limpiar la conversación |

---

## PASO 9 — Integración con Git (para revisar tu código automáticamente)

Si tu proyecto tiene git iniciado, Claude Code ya lo usa automáticamente. Puede:

- Ver el historial de cambios
- Hacer commits con mensaje descriptivo
- Crear ramas nuevas
- Revisar qué ha cambiado desde el último commit

Para iniciar git en un proyecto que no lo tiene aún:

```powershell
cd C:\TusProyectos\MiApp
git init
```

Luego lanza Claude Code normalmente y ya tendrá acceso al historial.

---

## Solución a problemas comunes

### ❌ "claude no se reconoce como comando"
- Cierra y vuelve a abrir PowerShell después de instalar Node.js
- Verifica con `node --version` que Node.js está instalado

### ❌ Claude Code muy lento
- Asegúrate de que Ollama usa la GPU: abre otra ventana de PowerShell y escribe `ollama ps`. Deberías ver `100% GPU`
- Si dice `100% CPU`, puede que falten drivers CUDA. Actualiza los drivers de NVIDIA desde [https://www.nvidia.com/drivers](https://www.nvidia.com/drivers)

### ❌ "Error de conexión" o "No se puede conectar"
- Verifica que Ollama está corriendo (icono en la barra de tareas)
- Si no está corriendo, ábrelo desde el menú Inicio
- Prueba escribir en PowerShell: `ollama list` para ver si responde

### ❌ El modelo se "bloquea" o repite lo mismo
- Reduce el contexto: en el Paso 6 prueba con `OLLAMA_CONTEXT_LENGTH=10000` en lugar de 20000
- O usa un modelo más ligero: `ollama pull qwen2.5-coder:7b`

### ❌ Error de permisos en PowerShell
Ejecuta PowerShell como Administrador y escribe:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Resumen de lo instalado

| Herramienta | Para qué sirve |
|---|---|
| **Ollama** | Motor que corre los modelos de IA en tu PC |
| **GLM 4.7 Flash** | El modelo de IA que procesa tus peticiones |
| **Node.js** | Necesario para que funcione Claude Code |
| **Claude Code** | La herramienta que edita tu código con IA |

---

## Modelos alternativos si GLM 4.7 Flash no va bien

```powershell
# Más ligero, muy bueno para código
ollama pull qwen2.5-coder:7b

# Para uso general (no solo código)
ollama pull llama3.1:8b
```

Para cambiar de modelo dentro de Claude Code, simplemente lánzalo con otro:

```powershell
ollama launch claude --model qwen2.5-coder:7b
```
