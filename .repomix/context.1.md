This file is a merged representation of a subset of the codebase, containing files not matching ignore patterns, combined into a single document by Repomix.
The content has been processed where line numbers have been added.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching these patterns are excluded: **/*.png, **/*.env, **/node_modules/**
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Line numbers have been added to the beginning of each line
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
backup/
  backup.sh
  Dockerfile
  entrypoint.sh
  restore.sh
client/
  img/
    ServerPortada.jpeg
  Dockerfile
  entrypoint.sh
web/
  assets/
    example.webp
  Data/
    OpenMuContext.cs
  Endpoints/
    ArmoryEndpoints.cs
    EventsEndpoints.cs
    PasswordEndpoints.cs
    RankingEndpoints.cs
    RegistrationEndpoints.cs
  Models/
    Account.cs
    Character.cs
    ItemStorage.cs
  Pages/
    Shared/
      _Layout.cshtml
    _ViewStart.cshtml
    Armory.cshtml
    Changepass.cshtml
    Commands.cshtml
    Events.cshtml
    Index.cshtml
    Register.cshtml
    Stats.cshtml
  Services/
    RateLimiter.cs
  wwwroot/
    css/
      commands.css
      events.css
      index.css
    img/
      char-placeholder.svg
    js/
      armory.js
      changepass.js
      commands.js
      events.js
      index.js
      register.js
      stats.js
    content.js
    en.js
    es.js
    lang.js
    mubg.jpg
    style.css
    template_lang.js
  appsettings.json
  Dockerfile
  OpenMU_Web.csproj
  Program.cs
  README.md
.env.example
.gitignore
docker-compose.yml
mu.sh
package.json
repomix.sh
````

# Files

## File: backup/backup.sh
````bash
 1: #!/bin/bash
 2: set -euo pipefail
 3: 
 4: BACKUP_DIR="${BACKUP_DIR:-/backups}"
 5: RETENTION_DAYS="${RETENTION_DAYS:-7}"
 6: PGDATABASE="${PGDATABASE:-openmu}"
 7: PGHOST="${PGHOST:-openmu-database}"
 8: PGUSER="${PGUSER:-postgres}"
 9: 
10: mkdir -p "$BACKUP_DIR"
11: 
12: TIMESTAMP=$(date +%Y%m%d_%H%M%S)
13: DEST="${BACKUP_DIR}/${PGDATABASE}_${TIMESTAMP}.dump"
14: TEMP_DEST="${DEST}.tmp"
15: 
16: log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BACKUP] $*"; }
17: 
18: log "Iniciando respaldo de: ${PGDATABASE}@${PGHOST}..."
19: 
20: # 1. Volcado con formato personalizado de Postgres (-Fc) y compresión máxima nativa (-Z 9)
21: if ! pg_dump -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -Fc -Z 9 -f "$TEMP_DEST"; then
22:     log "ERROR: pg_dump falló. Eliminando archivo temporal incompleto."
23:     rm -f "$TEMP_DEST"
24:     exit 1
25: fi
26: 
27: # 2. Verificación de integridad: pg_restore examina la tabla de contenidos (TOC)
28: if ! pg_restore --list "$TEMP_DEST" >/dev/null 2>&1; then
29:     log "ERROR: El volcado no superó la prueba de integridad de pg_restore. Eliminando."
30:     rm -f "$TEMP_DEST"
31:     exit 1
32: fi
33: 
34: mv "$TEMP_DEST" "$DEST"
35: SIZE=$(du -h "$DEST" | cut -f1)
36: log "Respaldo completado exitosamente: ${DEST} (${SIZE})"
37: 
38: # 3. Política de retención: limpiar dumps más antiguos que RETENTION_DAYS
39: DELETED=$(find "$BACKUP_DIR" -type f \( -name "${PGDATABASE}_*.dump" -o -name "${PGDATABASE}_*.dump.tmp" \) -mtime "+${RETENTION_DAYS}" -print -delete | wc -l)
40: if [ "$DELETED" -gt 0 ]; then
41:     log "Retención: Eliminado(s) ${DELETED} archivo(s) con más de ${RETENTION_DAYS} días de antigüedad."
42: fi
````

## File: backup/Dockerfile
````dockerfile
 1: FROM postgres:16-bookworm
 2: 
 3: # Instalar el demonio cron
 4: RUN apt-get update && \
 5:     apt-get install -y --no-install-recommends cron && \
 6:     rm -rf /var/lib/apt/lists/*
 7: 
 8: # Copiar scripts
 9: COPY backup.sh /usr/local/bin/backup.sh
10: COPY restore.sh /usr/local/bin/restore.sh
11: COPY entrypoint.sh /usr/local/bin/entrypoint.sh
12: 
13: RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/restore.sh /usr/local/bin/entrypoint.sh
14: 
15: ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
````

## File: backup/entrypoint.sh
````bash
 1: #!/bin/bash
 2: set -euo pipefail
 3: 
 4: # Exportar variables de entorno para que cron las reconozca al ejecutarse
 5: printenv | grep -E '^(PG|BACKUP_|RETENTION_|TZ|PATH)' > /etc/environment
 6: 
 7: CRON_SCHEDULE="${BACKUP_CRON_SCHEDULE:-0 3 * * *}"
 8: BACKUP_DIR="${BACKUP_DIR:-/backups}"
 9: RETENTION_DAYS="${RETENTION_DAYS:-7}"
10: 
11: echo "=========================================================="
12: echo " OpenMU PostgreSQL Backup Service (Cron Scheduler)"
13: echo " Base de datos objetivo: ${PGDATABASE:-openmu}@${PGHOST:-openmu-database}"
14: echo " Horario Cron: ${CRON_SCHEDULE}"
15: echo " Retención: ${RETENTION_DAYS} días"
16: echo " Carpeta de Backups: ${BACKUP_DIR}"
17: echo "=========================================================="
18: 
19: # Configurar crontab de sistema en Debian (/etc/cron.d/)
20: CRON_FILE="/etc/cron.d/openmu-backup"
21: cat <<EOF > "$CRON_FILE"
22: SHELL=/bin/bash
23: PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
24: ${CRON_SCHEDULE} root /usr/local/bin/backup.sh >> /proc/1/fd/1 2>> /proc/1/fd/2
25: EOF
26: 
27: # Permisos estrictos requeridos por cron en Debian
28: chmod 0644 "$CRON_FILE"
29: 
30: # Backup inicial al arrancar el contenedor
31: if [ "${RUN_ON_STARTUP:-true}" = "true" ]; then
32:     echo "[STARTUP] Ejecutando backup inicial de verificación..."
33:     /usr/local/bin/backup.sh || echo "[STARTUP] Advertencia: Falló el backup inicial, el demonio cron continuará en espera."
34: fi
35: 
36: echo "[CRON] Demonio cron activo y escuchando..."
37: exec cron -f
````

## File: backup/restore.sh
````bash
 1: #!/bin/bash
 2: set -euo pipefail
 3: 
 4: BACKUP_FILE="${1:-}"
 5: 
 6: if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
 7:     echo "=========================================================="
 8:     echo " USO: restore.sh /backups/<archivo>.dump"
 9:     echo "=========================================================="
10:     echo "Archivos disponibles en /backups:"
11:     ls -lh /backups/*.dump 2>/dev/null || echo "No se encontraron archivos .dump en /backups"
12:     exit 1
13: fi
14: 
15: PGDATABASE="${PGDATABASE:-openmu}"
16: PGHOST="${PGHOST:-openmu-database}"
17: PGUSER="${PGUSER:-postgres}"
18: 
19: echo "=========================================================="
20: echo " ADVERTENCIA: Se restaurará la base de datos '$PGDATABASE'"
21: echo " Host: $PGHOST | Usuario: $PGUSER"
22: echo " Archivo a restaurar: $BACKUP_FILE"
23: echo "=========================================================="
24: echo "Iniciando restauración en 5 segundos (Presiona CTRL+C para cancelar)..."
25: sleep 5
26: 
27: echo "Restaurando base de datos..."
28: pg_restore -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" --clean --if-exists "$BACKUP_FILE"
29: 
30: echo "=========================================================="
31: echo " [OK] Restauración completada con éxito."
32: echo "=========================================================="
````

## File: package.json
````json
 1: {
 2:   "name": "mu",
 3:   "version": "1.0.0",
 4:   "description": "Private mu server with opemMU",
 5:   "keywords": [
 6:     "mu"
 7:   ],
 8:   "homepage": "https://github.com/dev-lusaja/mu#readme",
 9:   "bugs": {
10:     "url": "https://github.com/dev-lusaja/mu/issues"
11:   },
12:   "repository": {
13:     "type": "git",
14:     "url": "git+https://github.com/dev-lusaja/mu.git"
15:   },
16:   "author": "devlusaja",
17:   "type": "commonjs",
18:   "main": "index.js",
19:   "scripts": {
20:     "code:context": "bash ./repomix.sh"
21:   },
22:   "devDependencies": {
23:     "repomix": "^1.18.0"
24:   }
25: }
````

## File: repomix.sh
````bash
1: #!/usr/bin/env bash
2: 
3: repomix --style markdown \
4:   --output-show-line-numbers \
5:   --output "./.repomix/context.md" \
6:   --split-output=1mb \
7:   --ignore "**/*.png,**/*.env,**/node_modules/**"
````

## File: client/Dockerfile
````dockerfile
 1: FROM oven/bun:1.2-slim
 2: 
 3: RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
 4: 
 5: WORKDIR /app
 6: 
 7: # Clone repo at build time (shallow clone for speed)
 8: #RUN git clone --depth 1 https://github.com/Ignies/OpenMu-Client-Babylon.git .
 9: RUN git clone --depth 1 https://github.com/dev-lusaja/OpenMu-Client-Babylon.git .
10: 
11: # Install dependencies
12: RUN bun install
13: 
14: COPY entrypoint.sh /entrypoint.sh
15: RUN chmod +x /entrypoint.sh
16: 
17: EXPOSE 4173 3000
18: 
19: ENTRYPOINT ["/entrypoint.sh"]
````

## File: client/entrypoint.sh
````bash
 1: #!/bin/bash
 2: set -e
 3: 
 4: PREVIEW_PORT="${CLIENT_VITE_PORT:-4173}"
 5: BUILD_MARKER="/app/dist/.build-done"
 6: 
 7: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
 8: echo "🎨 Aplicando personalizaciones al cliente..."
 9: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
10: # 1. Poner Modo de Video Clásico por defecto (Preajuste Clásica exacto)
11: sed -i 's/lightingQuality: 1/lightingQuality: 0/' src/common/gameOptions.ts
12: sed -i 's/materialQuality: 1/materialQuality: 0/' src/common/gameOptions.ts
13: # 2. Desactivar la creación automática de "Local (OpenMU)" en serverConfig.ts
14: sed -i 's/function seedsDefaultProfile(): boolean {/function seedsDefaultProfile(): boolean { return false;/' src/common/serverConfig.ts
15: # 3. Zoom inicial más alejado (1700 en lugar de 1200)
16: sed -i 's/const PORTED_DEFAULT_DISTANCE = 1200;/const PORTED_DEFAULT_DISTANCE = 1700;/' src/camera/recipes.ts
17: # 4. Splash screen fijo de 2 segundos con fade-out suave
18: sed -i 's|<div id="root"></div>|<div id="root"></div><div id="splash" style="position:fixed;inset:0;background:#000000;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#e5c158;font-family:sans-serif;letter-spacing:2px;font-size:14px;z-index:99999;transition:opacity 0.6s ease-out;pointer-events:none;"><img src="./Data/Logo/logo.jpg" style="max-width:280px;width:60%;margin-bottom:18px;image-rendering:pixelated;" alt="MU Online"/><div>CARGANDO CLIENTE...</div></div><script>setTimeout(function(){var s=document.getElementById("splash");if(s){s.style.opacity="0";setTimeout(function(){s.remove()},600);}},3000);</script>|' index.html
19: echo ""
20: 
21: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
22: echo "🔨 Building OpenMu-Client-Babylon (prod)..."
23: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
24: bun run build
25: echo "✅ Build completado"
26: echo ""
27: 
28: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
29: echo "▶ Starting WS↔TCP proxy on port ${PORT:-3000}..."
30: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
31: bun run proxy &
32: PROXY_PID=$!
33: 
34: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
35: echo "▶ Starting preview server on port ${PREVIEW_PORT}..."
36: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
37: bun run vite preview --host 0.0.0.0 --port "${PREVIEW_PORT}" --strictPort &
38: PREVIEW_PID=$!
39: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
40: echo "🌐 Client ready → http://localhost:${PREVIEW_PORT}/online"
41: echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
42: 
43: # Monitorear ambos procesos; si uno cae, matar el otro y salir
44: monitor() {
45:   while true; do
46:     for pid in $PROXY_PID $PREVIEW_PID; do
47:       if ! kill -0 "$pid" 2>/dev/null; then
48:         echo "Proceso $pid terminó — apagando contenedor"
49:         kill $PROXY_PID $PREVIEW_PID 2>/dev/null || true
50:         exit 1
51:       fi
52:     done
53:     sleep 2
54:   done
55: }
56: 
57: trap 'kill $PROXY_PID $PREVIEW_PID 2>/dev/null; exit 0' SIGTERM SIGINT
58: 
59: monitor
````

## File: mu.sh
````bash
  1: #!/usr/bin/env bash
  2: # =============================================================================
  3: # mu.sh — Administrador de servicios OpenMU
  4: # Uso: ./mu.sh [comando] [servicio...]
  5: #      ./mu.sh            (modo interactivo)
  6: # =============================================================================
  7: 
  8: set -euo pipefail
  9: 
 10: # ── Colores ──────────────────────────────────────────────────────────────────
 11: RED='\033[0;31m'
 12: GREEN='\033[0;32m'
 13: YELLOW='\033[1;33m'
 14: BLUE='\033[0;34m'
 15: CYAN='\033[0;36m'
 16: MAGENTA='\033[0;35m'
 17: BOLD='\033[1m'
 18: DIM='\033[2m'
 19: RESET='\033[0m'
 20: 
 21: # ── Directorio del script ─────────────────────────────────────────────────────
 22: SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 23: COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
 24: DC="docker compose -f $COMPOSE_FILE"
 25: 
 26: # ── Servicios disponibles ─────────────────────────────────────────────────────
 27: SERVICES=(
 28:   "openmu-database"
 29:   "openmu-db-backup"
 30:   "openmu-startup"
 31:   "openmu-web"
 32:   "openmu-client"
 33: )
 34: 
 35: SERVICE_LABELS=(
 36:   "🗄️  Base de datos  (PostgreSQL)"
 37:   "💾  Backups BD     (Cron Scheduler)"
 38:   "⚙️  Servidor OpenMU"
 39:   "🌐  Sitio web      (ASP.NET)"
 40:   "🎮  Cliente web    (BabylonJS · Vite + Proxy)"
 41: )
 42: 
 43: # =============================================================================
 44: # Helpers
 45: # =============================================================================
 46: 
 47: print_banner() {
 48:   echo -e ""
 49:   echo -e "${BOLD}${MAGENTA}  ╔═══════════════════════════════════════╗${RESET}"
 50:   echo -e "${BOLD}${MAGENTA}  ║      🧙  OpenMU Service Manager       ║${RESET}"
 51:   echo -e "${BOLD}${MAGENTA}  ╚═══════════════════════════════════════╝${RESET}"
 52:   echo -e ""
 53: }
 54: 
 55: print_status() {
 56:   echo -e "${BOLD}${CYAN}  ► Estado actual de los contenedores${RESET}"
 57:   echo -e "${DIM}  ──────────────────────────────────────────────────${RESET}"
 58:   $DC ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | \
 59:     awk 'NR==1 {print "  "$0} NR>1 {
 60:       if ($0 ~ /Up/) printf "  \033[0;32m✔\033[0m %s\n", $0
 61:       else if ($0 ~ /Exit|Exited/) printf "  \033[0;31m✘\033[0m %s\n", $0
 62:       else printf "  \033[1;33m●\033[0m %s\n", $0
 63:     }' || echo -e "${DIM}  (sin contenedores corriendo)${RESET}"
 64:   echo ""
 65: }
 66: 
 67: print_menu() {
 68:   echo -e "${BOLD}  Comandos disponibles:${RESET}"
 69:   echo -e "  ${GREEN}[1]${RESET} up       — Levantar servicios"
 70:   echo -e "  ${RED}[2]${RESET} down     — Detener y remover servicios"
 71:   echo -e "  ${YELLOW}[3]${RESET} restart  — Reiniciar servicios"
 72:   echo -e "  ${BLUE}[4]${RESET} build    — Rebuild de imágenes + up"
 73:   echo -e "  ${CYAN}[5]${RESET} logs     — Ver logs en tiempo real"
 74:   echo -e "  ${MAGENTA}[6]${RESET} status   — Ver estado (ps)"
 75:   echo -e "  ${DIM}[0]${RESET} exit     — Salir"
 76:   echo ""
 77: }
 78: 
 79: print_service_selector() {
 80:   echo -e "${BOLD}  Selecciona servicios ${DIM}(Enter = todos)${RESET}${BOLD}:${RESET}"
 81:   for i in "${!SERVICES[@]}"; do
 82:     echo -e "  ${CYAN}[$((i+1))]${RESET} ${SERVICE_LABELS[$i]}"
 83:   done
 84:   echo -e "  ${DIM}[a]${RESET} Todos los servicios"
 85:   echo ""
 86: }
 87: 
 88: # Retorna lista de servicios seleccionados en $SELECTED
 89: select_services() {
 90:   print_service_selector
 91:   echo -ne "${BOLD}  Opción(es) ${DIM}[ej: 1 3 4 | a | Enter para todos]${RESET}${BOLD}: ${RESET}"
 92:   read -r raw
 93: 
 94:   SELECTED=()
 95:   if [[ -z "$raw" || "$raw" == "a" ]]; then
 96:     # todos
 97:     return
 98:   fi
 99: 
100:   for token in $raw; do
101:     if [[ "$token" =~ ^[0-9]+$ ]]; then
102:       idx=$((token - 1))
103:       if [[ $idx -ge 0 && $idx -lt ${#SERVICES[@]} ]]; then
104:         SELECTED+=("${SERVICES[$idx]}")
105:       else
106:         echo -e "${YELLOW}  ⚠ Índice '$token' inválido, ignorado.${RESET}"
107:       fi
108:     fi
109:   done
110: }
111: 
112: log_action() {
113:   local verb="$1"; shift
114:   echo -e "\n${BOLD}${BLUE}  ┌─ $verb ${DIM}$(date '+%H:%M:%S')${RESET}"
115:   if [[ ${#@} -gt 0 ]]; then
116:     echo -e "${BLUE}  │  Servicios: ${CYAN}$*${RESET}"
117:   else
118:     echo -e "${BLUE}  │  Servicios: ${CYAN}todos${RESET}"
119:   fi
120:   echo -e "${BLUE}  └──────────────────────────────────────────${RESET}\n"
121: }
122: 
123: # =============================================================================
124: # Acciones
125: # =============================================================================
126: 
127: do_up() {
128:   log_action "▲  UP" "$@"
129:   $DC up -d "$@"
130:   echo -e "\n${GREEN}  ✔ Servicios levantados.${RESET}"
131:   print_status
132: }
133: 
134: do_down() {
135:   log_action "▼  DOWN" "$@"
136:   if [[ ${#@} -eq 0 ]]; then
137:     $DC down
138:   else
139:     $DC stop "$@"
140:     $DC rm -f "$@"
141:   fi
142:   echo -e "\n${RED}  ✔ Servicios detenidos.${RESET}"
143: }
144: 
145: do_restart() {
146:   log_action "↺  RESTART" "$@"
147:   if [[ ${#@} -eq 0 ]]; then
148:     $DC restart
149:   else
150:     $DC restart "$@"
151:   fi
152:   echo -e "\n${YELLOW}  ✔ Servicios reiniciados.${RESET}"
153:   print_status
154: }
155: 
156: do_build() {
157:   log_action "🔨 BUILD + UP" "$@"
158:   $DC up -d --build "$@"
159:   echo -e "\n${BLUE}  ✔ Build completado y servicios levantados.${RESET}"
160:   print_status
161: }
162: 
163: do_logs() {
164:   log_action "📋 LOGS" "$@"
165:   echo -e "${DIM}  (Ctrl+C para salir de los logs)${RESET}\n"
166:   $DC logs -f --tail=100 "$@"
167: }
168: 
169: do_status() {
170:   print_status
171: }
172: 
173: # =============================================================================
174: # Modo no interactivo: ./mu.sh <comando> [servicio...]
175: # =============================================================================
176: 
177: run_command() {
178:   local cmd="$1"; shift
179:   local svcs=("$@")
180: 
181:   case "$cmd" in
182:     up)      do_up      "${svcs[@]}" ;;
183:     down)    do_down    "${svcs[@]}" ;;
184:     restart) do_restart "${svcs[@]}" ;;
185:     build)   do_build   "${svcs[@]}" ;;
186:     logs)    do_logs    "${svcs[@]}" ;;
187:     status|ps) do_status ;;
188:     *)
189:       echo -e "${RED}  ✘ Comando desconocido: '$cmd'${RESET}"
190:       echo -e "  Uso: $0 {up|down|restart|build|logs|status} [servicio...]"
191:       exit 1
192:       ;;
193:   esac
194: }
195: 
196: # =============================================================================
197: # Modo interactivo
198: # =============================================================================
199: 
200: interactive() {
201:   while true; do
202:     clear
203:     print_banner
204:     print_status
205:     print_menu
206: 
207:     echo -ne "${BOLD}  Comando [0-6]: ${RESET}"
208:     read -r choice
209:     echo ""
210: 
211:     case "$choice" in
212:       0) echo -e "${DIM}  Hasta luego.${RESET}\n"; exit 0 ;;
213:       6) do_status; read -rp "  Presiona Enter para continuar..." ;;
214:       1|2|3|4|5)
215:         SELECTED=()
216:         select_services
217:         case "$choice" in
218:           1) do_up      "${SELECTED[@]}" ;;
219:           2) do_down    "${SELECTED[@]}" ;;
220:           3) do_restart "${SELECTED[@]}" ;;
221:           4) do_build   "${SELECTED[@]}" ;;
222:           5) do_logs    "${SELECTED[@]}" ;;
223:         esac
224:         echo ""
225:         read -rp "  Presiona Enter para continuar..." ;;
226:       *)
227:         echo -e "${YELLOW}  ⚠ Opción inválida.${RESET}"
228:         sleep 1 ;;
229:     esac
230:   done
231: }
232: 
233: # =============================================================================
234: # Entry point
235: # =============================================================================
236: 
237: if [[ $# -ge 1 ]]; then
238:   # Modo CLI: ./mu.sh up openmu-client
239:   run_command "$@"
240: else
241:   # Modo interactivo
242:   interactive
243: fi
````

## File: web/Data/OpenMuContext.cs
````csharp
 1: using Microsoft.EntityFrameworkCore;
 2: using OpenMU_Web.Models;
 3: 
 4: namespace OpenMU_Web.Data;
 5: 
 6: public class OpenMuContext : DbContext
 7: {
 8:     public OpenMuContext(DbContextOptions<OpenMuContext> options) : base(options) { }
 9: 
10:     public DbSet<Account> Accounts => Set<Account>();
11:     public DbSet<ItemStorage> ItemStorages => Set<ItemStorage>();
12:     public DbSet<Character> Characters => Set<Character>();
13: 
14:     protected override void OnModelCreating(ModelBuilder modelBuilder)
15:     {
16:         modelBuilder.Entity<Account>()
17:             .HasOne<ItemStorage>()
18:             .WithMany()
19:             .HasForeignKey(a => a.VaultId);
20:     }
21: }
````

## File: web/Endpoints/ArmoryEndpoints.cs
````csharp
  1: using System.Data;
  2: using System.Globalization;
  3: using System.Text;
  4: using Microsoft.AspNetCore.Mvc;
  5: using Microsoft.EntityFrameworkCore;
  6: using OpenMU_Web.Data;
  7: using OpenMU_Web.Services;
  8: 
  9: namespace OpenMU_Web.Endpoints;
 10: 
 11: public static class ArmoryEndpoints
 12: {
 13:     // Maps the item level to the level used in the item image file name (mirrors the admin panel item editor).
 14:     private static readonly int[] LevelMapping = { 0, 0, 0, 3, 3, 5, 5, 7, 7, 9, 9, 11, 11, 13, 13, 15, 15 };
 15: 
 16:     private const int WingsSlot = 7;
 17:     private const int PetSlot = 8;
 18: 
 19:     private sealed class ItemRow
 20:     {
 21:         public Guid Id;
 22:         public int Slot;
 23:         public int Group;
 24:         public int Number;
 25:         public string Name = "";
 26:         public int Level;
 27:         public bool HasSkill;
 28:         public int Sockets;
 29:         public bool Excellent;
 30:         public string? AncientSet;
 31:     }
 32: 
 33:     private sealed class OptionRow
 34:     {
 35:         public string OptType = "";
 36:         public string? Target;
 37:         public double? Value;
 38:     }
 39: 
 40:     public static void MapArmoryEndpoints(this WebApplication app)
 41:     {
 42:         app.MapGet("/api/public/armory/{name}", async (string name, OpenMuContext db, HttpContext context, [FromKeyedServices("armory")] RateLimiter rateLimiter, [FromServices] ILogger<Program> logger) =>
 43:         {
 44:             try
 45:             {
 46:                 var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
 47: 
 48:                 if (rateLimiter.IsLimited(ip, 30, TimeSpan.FromMinutes(1)))
 49:                     return Results.Json(new { code = "RATE_LIMIT_ARMORY", message = "Too many requests. Try again later." }, statusCode: 429);
 50: 
 51:                 name = name.Trim();
 52:                 if (name.Length is < 1 or > 10)
 53:                     return Results.Json(new { code = "ARMORY_NOT_FOUND", message = "Character not found." }, statusCode: 404);
 54: 
 55:                 var connection = db.Database.GetDbConnection();
 56:                 if (connection.State != ConnectionState.Open) await connection.OpenAsync();
 57: 
 58:                 // 1. Character header (class, level, resets, master level) and its inventory id.
 59:                 Guid inventoryId;
 60:                 string className;
 61:                 int level, resets, masterLevel;
 62: 
 63:                 const string headerSql = @"
 64:                     SELECT
 65:                         cc.""Name"" as ""ClassName"",
 66:                         c.""InventoryId"",
 67:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
 68:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
 69:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Level' LIMIT 1) as ""Level"",
 70:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
 71:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
 72:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Resets' LIMIT 1) as ""Resets"",
 73:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
 74:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
 75:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Master Level' LIMIT 1) as ""MasterLevel""
 76:                     FROM data.""Character"" c
 77:                     JOIN config.""CharacterClass"" cc ON c.""CharacterClassId"" = cc.""Id""
 78:                     WHERE c.""Name"" = @name
 79:                     LIMIT 1";
 80: 
 81:                 using (var command = connection.CreateCommand())
 82:                 {
 83:                     command.CommandText = headerSql;
 84:                     AddParameter(command, "name", name);
 85:                     using var reader = await command.ExecuteReaderAsync();
 86:                     if (!await reader.ReadAsync() || reader["InventoryId"] == DBNull.Value)
 87:                         return Results.Json(new { code = "ARMORY_NOT_FOUND", message = "Character not found." }, statusCode: 404);
 88: 
 89:                     className = reader["ClassName"].ToString() ?? "";
 90:                     inventoryId = (Guid)reader["InventoryId"];
 91:                     level = reader["Level"] != DBNull.Value ? Convert.ToInt32(reader["Level"]) : 1;
 92:                     resets = reader["Resets"] != DBNull.Value ? Convert.ToInt32(reader["Resets"]) : 0;
 93:                     masterLevel = reader["MasterLevel"] != DBNull.Value ? Convert.ToInt32(reader["MasterLevel"]) : 0;
 94:                 }
 95: 
 96:                 // 2. Equipped items only (slots 0-11 of the character inventory).
 97:                 const string itemsSql = @"
 98:                     SELECT
 99:                         i.""Id"" as ""Id"",
100:                         i.""ItemSlot"" as ""Slot"",
101:                         d.""Group"" as ""Grp"",
102:                         d.""Number"" as ""Num"",
103:                         d.""Name"" as ""ItemName"",
104:                         i.""Level"" as ""Level"",
105:                         i.""HasSkill"" as ""HasSkill"",
106:                         i.""SocketCount"" as ""Sockets"",
107:                         EXISTS(SELECT 1 FROM data.""ItemOptionLink"" ol
108:                                JOIN config.""IncreasableItemOption"" io ON ol.""ItemOptionId"" = io.""Id""
109:                                JOIN config.""ItemOptionType"" ot ON io.""OptionTypeId"" = ot.""Id""
110:                                WHERE ol.""ItemId"" = i.""Id"" AND ot.""Name"" = 'Excellent Option') as ""Excellent"",
111:                         (SELECT sg.""Name"" FROM data.""ItemItemOfItemSet"" iis
112:                          JOIN config.""ItemOfItemSet"" ois ON iis.""ItemOfItemSetId"" = ois.""Id""
113:                          JOIN config.""ItemSetGroup"" sg ON ois.""ItemSetGroupId"" = sg.""Id""
114:                          WHERE iis.""ItemId"" = i.""Id"" AND ois.""AncientSetDiscriminator"" > 0 LIMIT 1) as ""AncientSet""
115:                     FROM data.""Item"" i
116:                     JOIN config.""ItemDefinition"" d ON i.""DefinitionId"" = d.""Id""
117:                     WHERE i.""ItemStorageId"" = @inventoryId AND i.""ItemSlot"" BETWEEN 0 AND 11
118:                     ORDER BY i.""ItemSlot""";
119: 
120:                 var rows = new List<ItemRow>();
121:                 using (var command = connection.CreateCommand())
122:                 {
123:                     command.CommandText = itemsSql;
124:                     AddParameter(command, "inventoryId", inventoryId);
125:                     using var reader = await command.ExecuteReaderAsync();
126:                     while (await reader.ReadAsync())
127:                     {
128:                         rows.Add(new ItemRow
129:                         {
130:                             Id = (Guid)reader["Id"],
131:                             Slot = Convert.ToInt32(reader["Slot"]),
132:                             Group = Convert.ToInt32(reader["Grp"]),
133:                             Number = Convert.ToInt32(reader["Num"]),
134:                             Name = reader["ItemName"].ToString() ?? "",
135:                             Level = Convert.ToInt32(reader["Level"]),
136:                             HasSkill = reader["HasSkill"] != DBNull.Value && Convert.ToBoolean(reader["HasSkill"]),
137:                             Sockets = reader["Sockets"] != DBNull.Value ? Convert.ToInt32(reader["Sockets"]) : 0,
138:                             Excellent = Convert.ToBoolean(reader["Excellent"]),
139:                             AncientSet = reader["AncientSet"] != DBNull.Value ? reader["AncientSet"].ToString() : null,
140:                         });
141:                     }
142:                 }
143: 
144:                 // 3. Concrete options of those items, with the resolved target attribute and value.
145:                 //    Level dependent options (e.g. the regular "+option") take their value from the
146:                 //    matching ItemOptionOfLevel; the others use the option's own power up definition.
147:                 var optionsByItem = new Dictionary<Guid, List<OptionRow>>();
148:                 if (rows.Count > 0)
149:                 {
150:                     const string optionsSql = @"
151:                         SELECT
152:                             ol.""ItemId"" as ""ItemId"",
153:                             ot.""Name"" as ""OptType"",
154:                             COALESCE(
155:                                 (SELECT ad.""Designation"" FROM config.""ItemOptionOfLevel"" lvl
156:                                  JOIN config.""PowerUpDefinition"" p ON lvl.""PowerUpDefinitionId"" = p.""Id""
157:                                  JOIN config.""AttributeDefinition"" ad ON p.""TargetAttributeId"" = ad.""Id""
158:                                  WHERE lvl.""IncreasableItemOptionId"" = io.""Id"" AND lvl.""Level"" = ol.""Level"" LIMIT 1),
159:                                 (SELECT ad.""Designation"" FROM config.""PowerUpDefinition"" p
160:                                  JOIN config.""AttributeDefinition"" ad ON p.""TargetAttributeId"" = ad.""Id""
161:                                  WHERE p.""Id"" = io.""PowerUpDefinitionId"" LIMIT 1)
162:                             ) as ""Target"",
163:                             COALESCE(
164:                                 (SELECT v.""Value"" FROM config.""ItemOptionOfLevel"" lvl
165:                                  JOIN config.""PowerUpDefinition"" p ON lvl.""PowerUpDefinitionId"" = p.""Id""
166:                                  JOIN config.""PowerUpDefinitionValue"" v ON p.""BoostId"" = v.""Id""
167:                                  WHERE lvl.""IncreasableItemOptionId"" = io.""Id"" AND lvl.""Level"" = ol.""Level"" LIMIT 1),
168:                                 (SELECT v.""Value"" FROM config.""PowerUpDefinition"" p
169:                                  JOIN config.""PowerUpDefinitionValue"" v ON p.""BoostId"" = v.""Id""
170:                                  WHERE p.""Id"" = io.""PowerUpDefinitionId"" LIMIT 1)
171:                             ) as ""Value""
172:                         FROM data.""Item"" i
173:                         JOIN data.""ItemOptionLink"" ol ON ol.""ItemId"" = i.""Id""
174:                         JOIN config.""IncreasableItemOption"" io ON ol.""ItemOptionId"" = io.""Id""
175:                         JOIN config.""ItemOptionType"" ot ON io.""OptionTypeId"" = ot.""Id""
176:                         WHERE i.""ItemStorageId"" = @inventoryId AND i.""ItemSlot"" BETWEEN 0 AND 11
177:                         ORDER BY ol.""ItemId"", ot.""Name""";
178: 
179:                     using var command = connection.CreateCommand();
180:                     command.CommandText = optionsSql;
181:                     AddParameter(command, "inventoryId", inventoryId);
182:                     using var reader = await command.ExecuteReaderAsync();
183:                     while (await reader.ReadAsync())
184:                     {
185:                         var itemId = (Guid)reader["ItemId"];
186:                         if (!optionsByItem.TryGetValue(itemId, out var list))
187:                         {
188:                             list = new List<OptionRow>();
189:                             optionsByItem[itemId] = list;
190:                         }
191: 
192:                         list.Add(new OptionRow
193:                         {
194:                             OptType = reader["OptType"].ToString() ?? "",
195:                             Target = reader["Target"] != DBNull.Value ? reader["Target"].ToString() : null,
196:                             Value = reader["Value"] != DBNull.Value ? Convert.ToDouble(reader["Value"]) : null,
197:                         });
198:                     }
199:                 }
200: 
201:                 var items = rows.Select(r => new
202:                 {
203:                     slot = r.Slot,
204:                     image = BuildImageName(r.Group, r.Number, r.Level, r.Slot, r.Excellent, r.AncientSet != null),
205:                     description = BuildDescription(r, optionsByItem.GetValueOrDefault(r.Id)),
206:                     excellent = r.Excellent,
207:                     ancient = r.AncientSet != null,
208:                     sockets = r.Sockets,
209:                 }).ToList();
210: 
211:                 return Results.Ok(new { name, className, level, resets, masterLevel, items });
212:             }
213:             catch (Exception ex)
214:             {
215:                 logger.LogError(ex, "Error fetching armory");
216:                 return Results.Json(new { code = "DATABASE_ERROR", message = "Database error. Please try again later." }, statusCode: 500);
217:             }
218:         });
219:     }
220: 
221:     private static void AddParameter(System.Data.Common.DbCommand command, string name, object value)
222:     {
223:         var parameter = command.CreateParameter();
224:         parameter.ParameterName = name;
225:         parameter.Value = value;
226:         command.Parameters.Add(parameter);
227:     }
228: 
229:     private static string BuildImageName(int group, int number, int level, int slot, bool excellent, bool ancient)
230:     {
231:         // Wings and pets always use the base image; everything else maps the level to an effect tier.
232:         int effectLevel = slot is WingsSlot or PetSlot
233:             ? 0
234:             : (level >= 0 && level < LevelMapping.Length ? LevelMapping[level] : 0);
235: 
236:         var suffix = ancient ? "_a" : (group < 12 && excellent ? "_e" : string.Empty);
237:         return $"item_{group}_{number}_{effectLevel}{suffix}.png";
238:     }
239: 
240:     private static string BuildDescription(ItemRow item, List<OptionRow>? options)
241:     {
242:         var header = new StringBuilder();
243:         if (item.Excellent)
244:         {
245:             header.Append("Excellent ");
246:         }
247: 
248:         if (!string.IsNullOrEmpty(item.AncientSet))
249:         {
250:             header.Append(item.AncientSet).Append(' ');
251:         }
252: 
253:         header.Append(item.Name);
254:         if (item.Level > 0)
255:         {
256:             header.Append('+').Append(item.Level);
257:         }
258: 
259:         // Each meaningful option is listed on its own line so the tooltip explains the item.
260:         var lines = new List<string> { header.ToString() };
261:         var allOptions = options ?? Enumerable.Empty<OptionRow>();
262: 
263:         // Luck is always listed first, directly under the item name.
264:         if (allOptions.Any(o => o.OptType.StartsWith("Luck", StringComparison.Ordinal)))
265:         {
266:             lines.Add("+ Luck");
267:         }
268: 
269:         // Then all the other options.
270:         foreach (var option in allOptions)
271:         {
272:             if (option.OptType.StartsWith("Luck", StringComparison.Ordinal))
273:             {
274:                 continue;
275:             }
276: 
277:             // Individual socket seeds are represented by the socket count below.
278:             if (option.OptType == "Socket Option" || string.IsNullOrEmpty(option.Target))
279:             {
280:                 continue;
281:             }
282: 
283:             // The value is only shown for additive "Option" bonuses; the others (excellent, wing,
284:             // fenrir, guardian, ...) are often percentages/chances, so they are listed by name only.
285:             var line = option.OptType switch
286:             {
287:                 "Option" => $"+ {option.Target}{FormatValue(option.Value)}",
288:                 "Excellent Option" => $"+ Exc: {option.Target}",
289:                 "Wing Option" => $"+ Wing: {option.Target}",
290:                 "Socket Bonus Option" => $"+ Socket Bonus: {option.Target}",
291:                 _ => $"+ {option.Target}",
292:             };
293:             lines.Add(line);
294:         }
295: 
296:         if (item.Sockets > 0)
297:         {
298:             lines.Add($"+ {item.Sockets} Socket{(item.Sockets > 1 ? "s" : "")}");
299:         }
300: 
301:         // Skill is always listed last.
302:         if (item.HasSkill)
303:         {
304:             lines.Add("+ Skill");
305:         }
306: 
307:         return string.Join("\n", lines);
308:     }
309: 
310:     private static string FormatValue(double? value)
311:     {
312:         if (value is null)
313:         {
314:             return string.Empty;
315:         }
316: 
317:         // Option values are additive, so show them as a rounded "+N" bonus. Fractional values below 1
318:         // are multipliers/percentages rather than flat bonuses, so they are shown by name only (no "+0").
319:         var rounded = Math.Round(value.Value, MidpointRounding.AwayFromZero);
320:         if (Math.Abs(rounded) < 1)
321:         {
322:             return string.Empty;
323:         }
324: 
325:         return " +" + rounded.ToString("0", CultureInfo.InvariantCulture);
326:     }
327: }
````

## File: web/Endpoints/EventsEndpoints.cs
````csharp
  1: using System.Data;
  2: using System.Text.Json;
  3: using Microsoft.AspNetCore.Mvc;
  4: using Microsoft.EntityFrameworkCore;
  5: using OpenMU_Web.Data;
  6: using OpenMU_Web.Services;
  7: 
  8: namespace OpenMU_Web.Endpoints;
  9: 
 10: public static class EventsEndpoints
 11: {
 12:     private static readonly Dictionary<Guid, string> EventNames = new()
 13:     {
 14:         [Guid.Parse("548A76CC-242C-441C-BC9D-6C22745A2D72")] = "Red Dragon Invasion",
 15:         [Guid.Parse("06D18A9E-2919-4C17-9DBC-6E4F7756495C")] = "Golden Invasion",
 16:         [Guid.Parse("95E68C14-AD87-4B3C-AF46-45B8F1C3BC2A")] = "Blood Castle",
 17:         [Guid.Parse("3AD96A70-ED24-4979-80B8-169E461E548F")] = "Chaos Castle",
 18:         [Guid.Parse("61C61A58-211E-4D6A-9EA1-D25E0C4A47C5")] = "Devil Square",
 19:         [Guid.Parse("6542E452-9780-45B8-85AE-4036422E9A6E")] = "Happy Hour",
 20:         [Guid.Parse("4B5D0F55-5B26-4447-B9C0-C272E5D0A141")] = "White Wizard Invasion",
 21:     };
 22: 
 23:     public static void MapEventsEndpoints(this WebApplication app)
 24:     {
 25:         app.MapGet("/api/public/events", async (OpenMuContext db, HttpContext context, [FromKeyedServices("events")] RateLimiter rateLimiter, [FromServices] ILogger<Program> logger) =>
 26:         {
 27:             try
 28:             {
 29:                 var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
 30: 
 31:                 if (rateLimiter.IsLimited(ip, 30, TimeSpan.FromMinutes(1)))
 32:                     return Results.Json(new { code = "RATE_LIMIT_RANKING", message = "Too many requests. Try again later." }, statusCode: 429);
 33: 
 34:                 var guids = EventNames.Keys.ToList();
 35:                 var paramList = string.Join(", ", guids.Select((_, i) => $"@g{i}::uuid"));
 36: 
 37:                 var sql = $@"
 38:                     SELECT ""TypeId"", ""IsActive"", ""CustomConfiguration""
 39:                     FROM config.""PlugInConfiguration""
 40:                     WHERE ""TypeId"" IN ({paramList})
 41:                     AND ""IsActive"" = true";
 42: 
 43:                 var connection = db.Database.GetDbConnection();
 44:                 if (connection.State != ConnectionState.Open) await connection.OpenAsync();
 45: 
 46:                 var nowUtc = DateTime.UtcNow;
 47:                 var tz = await ResolveServerTimeZoneAsync(connection, logger);
 48:                 var nowLocal = TimeZoneInfo.ConvertTimeFromUtc(nowUtc, tz);
 49:                 var todayLocal = DateOnly.FromDateTime(nowLocal);
 50:                 var result = new List<object>();
 51: 
 52:                 using (var command = connection.CreateCommand())
 53:                 {
 54:                     command.CommandText = sql;
 55:                     for (int i = 0; i < guids.Count; i++)
 56:                     {
 57:                         var p = command.CreateParameter();
 58:                         p.ParameterName = $"g{i}";
 59:                         p.Value = guids[i];
 60:                         command.Parameters.Add(p);
 61:                     }
 62: 
 63:                     using (var reader = await command.ExecuteReaderAsync())
 64:                     {
 65:                         while (await reader.ReadAsync())
 66:                         {
 67:                             var typeId = (Guid)reader["TypeId"];
 68:                             var customConfig = reader["CustomConfiguration"] as string;
 69:                             var isActive = (bool)reader["IsActive"];
 70: 
 71:                             if (!isActive || string.IsNullOrEmpty(customConfig))
 72:                                 continue;
 73: 
 74:                             using var doc = JsonDocument.Parse(customConfig);
 75:                             var timetableElement = doc.RootElement.GetProperty("Timetable");
 76:                             if (timetableElement.ValueKind == JsonValueKind.Object && timetableElement.TryGetProperty("$values", out var values))
 77:                                 timetableElement = values;
 78:                             var timetable = timetableElement.EnumerateArray()
 79:                                 .Select(t => TimeOnly.Parse(t.GetString()!))
 80:                                 .OrderBy(t => t)
 81:                                 .ToList();
 82: 
 83:                             if (timetable.Count == 0)
 84:                                 continue;
 85: 
 86:                             var durationStr = doc.RootElement.GetProperty("TaskDuration").GetString();
 87:                             var duration = TimeSpan.Parse(durationStr!);
 88: 
 89:                             // The timetable holds local times of day in the server's configured time zone
 90:                             // (SystemConfiguration.TimeZoneId); OpenMU matches them against that same zone
 91:                             // (PeriodicTaskConfiguration.IsItTimeToStart). Convert each occurrence to UTC for the
 92:                             // countdown and back for display, which stays correct across DST.
 93:                             var occurrences = timetable
 94:                                 .Select(t =>
 95:                                 {
 96:                                     var localTime = DateTime.SpecifyKind(todayLocal.ToDateTime(t), DateTimeKind.Unspecified);
 97:                                     var candidate = TimeZoneInfo.ConvertTimeToUtc(localTime, tz);
 98:                                     if (candidate <= nowUtc)
 99:                                         candidate = TimeZoneInfo.ConvertTimeToUtc(localTime.AddDays(1), tz);
100: 
101:                                     return (Utc: candidate, Local: TimeZoneInfo.ConvertTimeFromUtc(candidate, tz));
102:                                 })
103:                                 .ToList();
104: 
105:                             var next = occurrences.MinBy(o => o.Utc);
106:                             var timetableLocal = occurrences
107:                                 .Select(o => TimeOnly.FromDateTime(o.Local))
108:                                 .OrderBy(t => t)
109:                                 .ToList();
110: 
111:                             result.Add(new
112:                             {
113:                                 name = EventNames.GetValueOrDefault(typeId, "Unknown Event"),
114:                                 nextRunUtc = next.Utc.ToString("o"),
115:                                 countdownSeconds = (int)(next.Utc - nowUtc).TotalSeconds,
116:                                 durationMinutes = (int)duration.TotalMinutes,
117:                                 timetable = timetableLocal.Select(t => t.ToString("HH:mm")).ToList(),
118:                                 nextRunLocal = TimeOnly.FromDateTime(next.Local).ToString("HH:mm"),
119:                                 experienceMultiplier = doc.RootElement.TryGetProperty("ExperienceMultiplier", out var exp) ? exp.GetSingle() : (float?)null,
120:                             });
121:                         }
122:                     }
123:                 }
124: 
125:                 return Results.Ok(result);
126:             }
127:             catch (Exception ex)
128:             {
129:                 logger.LogError(ex, "Error fetching events");
130:                     return Results.Json(new { code = "DATABASE_ERROR", message = "Database error. Please try again later." }, statusCode: 500);
131:             }
132:         });
133:     }
134: 
135:     /// <summary>
136:     /// Reads the server time zone from <c>config."SystemConfiguration"."TimeZoneId"</c> and resolves it.
137:     /// This is the same value the game server uses to interpret the event timetable, so the page and the
138:     /// server share a single source of truth and no longer depend on the container's TZ environment.
139:     /// Falls back to UTC when the column is absent (feature not deployed yet), the value is empty, or the id
140:     /// cannot be resolved — which matches the server's own fallback behavior.
141:     /// </summary>
142:     private static async Task<TimeZoneInfo> ResolveServerTimeZoneAsync(System.Data.Common.DbConnection connection, ILogger logger)
143:     {
144:         string? tzId;
145:         try
146:         {
147:             using var command = connection.CreateCommand();
148:             command.CommandText = @"SELECT ""TimeZoneId"" FROM config.""SystemConfiguration"" LIMIT 1";
149:             tzId = await command.ExecuteScalarAsync() as string;
150:         }
151:         catch (Exception ex)
152:         {
153:             logger.LogWarning(ex, "Could not read SystemConfiguration.TimeZoneId; falling back to UTC.");
154:             return TimeZoneInfo.Utc;
155:         }
156: 
157:         if (string.IsNullOrWhiteSpace(tzId))
158:             return TimeZoneInfo.Utc;
159: 
160:         try
161:         {
162:             return TimeZoneInfo.FindSystemTimeZoneById(tzId);
163:         }
164:         catch (Exception ex) when (ex is TimeZoneNotFoundException or InvalidTimeZoneException)
165:         {
166:             logger.LogWarning(ex, "Could not resolve server time zone '{TimeZoneId}'; falling back to UTC.", tzId);
167:             return TimeZoneInfo.Utc;
168:         }
169:     }
170: }
````

## File: web/Endpoints/PasswordEndpoints.cs
````csharp
 1: using Microsoft.AspNetCore.Mvc;
 2: using Microsoft.EntityFrameworkCore;
 3: using OpenMU_Web.Data;
 4: using OpenMU_Web.Services;
 5: 
 6: namespace OpenMU_Web.Endpoints;
 7: 
 8: public static class PasswordEndpoints
 9: {
10:     public static void MapPasswordEndpoints(this WebApplication app)
11:     {
12:         app.MapPost("/api/change-password", async (HttpContext context, OpenMuContext db, [FromKeyedServices("password")] RateLimiter rateLimiter, [FromServices] ILogger<Program> logger) =>
13:         {
14:             try
15:             {
16:                 if (!context.Request.Headers.TryGetValue("X-Requested-With", out var v) || v != "XMLHttpRequest")
17:                     return Results.Json(new { code = "INVALID_REQUEST" }, statusCode: 400);
18: 
19:                 var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
20: 
21:                 if (rateLimiter.IsLimited(ip, 5, TimeSpan.FromMinutes(15)))
22:                     return Results.Json(new { code = "RATE_LIMIT_PASSWORD", message = "Too many attempts. Try again in 15 minutes." }, statusCode: 429);
23: 
24:                 var form = await context.Request.ReadFormAsync();
25:                 var username = form["username"].ToString().Trim();
26:                 var oldPassword = form["oldPassword"].ToString();
27:                 var newPassword = form["newPassword"].ToString();
28: 
29:                 if (string.IsNullOrEmpty(oldPassword))
30:                     return Results.Json(new { code = "INVALID_OLD_PASSWORD", message = "Current password is incorrect." }, statusCode: 401);
31: 
32:                 var account = await db.Accounts.FirstOrDefaultAsync(a => a.LoginName == username);
33:                 if (account == null)
34:                     return Results.Json(new { code = "USER_NOT_FOUND", message = "User not found." }, statusCode: 404);
35: 
36:                 if (!BCrypt.Net.BCrypt.Verify(oldPassword, account.PasswordHash))
37:                     return Results.Json(new { code = "INVALID_OLD_PASSWORD", message = "Current password is incorrect." }, statusCode: 401);
38: 
39:                 if (newPassword.Length < 8 || newPassword.Length > 16)
40:                     return Results.Json(new { code = "INVALID_PASSWORD_LENGTH", message = "New password must be 8-16 characters." }, statusCode: 400);
41: 
42:                 account.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
43:                 await db.SaveChangesAsync();
44: 
45:                     return Results.Json(new { code = "PASSWORD_CHANGE_SUCCESS", message = "Password changed successfully!" });
46:             }
47:             catch (Exception ex)
48:             {
49:                 logger.LogError(ex, "Error during password change");
50:                     return Results.Json(new { code = "SERVER_ERROR", message = "Failed to change password." }, statusCode: 500);
51:             }
52:         });
53:     }
54: }
````

## File: web/Endpoints/RankingEndpoints.cs
````csharp
 1: using System.Data;
 2: using Microsoft.AspNetCore.Mvc;
 3: using Microsoft.EntityFrameworkCore;
 4: using OpenMU_Web.Data;
 5: using OpenMU_Web.Services;
 6: 
 7: namespace OpenMU_Web.Endpoints;
 8: 
 9: public static class RankingEndpoints
10: {
11:     public static void MapRankingEndpoints(this WebApplication app)
12:     {
13:         app.MapGet("/api/public/ranking", async (OpenMuContext db, HttpContext context, [FromKeyedServices("ranking")] RateLimiter rateLimiter, [FromServices] ILogger<Program> logger) =>
14:         {
15:             try
16:             {
17:                 var ip = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
18: 
19:                 if (rateLimiter.IsLimited(ip, 30, TimeSpan.FromMinutes(1)))
20:                     return Results.Json(new { code = "RATE_LIMIT_RANKING", message = "Too many requests. Try again later." }, statusCode: 429);
21: 
22:                     var sql = @"
23:                     SELECT
24:                         c.""Name"",
25:                         c.""Experience"",
26:                         cc.""Name"" as ""ClassName"",
27:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
28:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
29:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Level' LIMIT 1) as ""Level"",
30:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
31:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
32:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Resets' LIMIT 1) as ""Resets"",
33:                         (SELECT a.""Value"" FROM data.""StatAttribute"" a
34:                          JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
35:                          WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Master Level' LIMIT 1) as ""MasterLevel""
36:                     FROM data.""Character"" c
37:                     JOIN config.""CharacterClass"" cc ON c.""CharacterClassId"" = cc.""Id""
38:                     ORDER BY COALESCE((SELECT a.""Value"" FROM data.""StatAttribute"" a
39:                      JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
40:                      WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Master Level' LIMIT 1), 0) DESC,
41:                              COALESCE((SELECT a.""Value"" FROM data.""StatAttribute"" a
42:                      JOIN config.""AttributeDefinition"" ad ON a.""DefinitionId"" = ad.""Id""
43:                      WHERE a.""CharacterId"" = c.""Id"" AND ad.""Designation"" = 'Resets' LIMIT 1), 0) DESC
44:                     LIMIT 10";
45: 
46:                 var result = new List<object>();
47: 
48:                 var connection = db.Database.GetDbConnection();
49:                 if (connection.State != ConnectionState.Open) await connection.OpenAsync();
50: 
51:                 using (var command = connection.CreateCommand())
52:                 {
53:                     command.CommandText = sql;
54:                     using (var reader = await command.ExecuteReaderAsync())
55:                     {
56:                         while (await reader.ReadAsync())
57:                         {
58:                             result.Add(new
59:                             {
60:                                 name = reader["Name"].ToString(),
61:                                 experience = reader["Experience"],
62:                                 className = reader["ClassName"].ToString(),
63:                                 level = reader["Level"] != DBNull.Value ? Convert.ToInt32(reader["Level"]) : 1,
64:                                 resets = reader["Resets"] != DBNull.Value ? Convert.ToInt32(reader["Resets"]) : 0,
65:                                 masterLevel = reader["MasterLevel"] != DBNull.Value ? Convert.ToInt32(reader["MasterLevel"]) : 0
66:                             });
67:                         }
68:                     }
69:                 }
70: 
71:                 return Results.Ok(result);
72:             }
73:             catch (Exception ex)
74:             {
75:                 logger.LogError(ex, "Error fetching ranking");
76:                     return Results.Json(new { code = "DATABASE_ERROR", message = "Database error. Please try again later." }, statusCode: 500);
77:             }
78:         });
79:     }
80: }
````

## File: web/Endpoints/RegistrationEndpoints.cs
````csharp
 1: using Microsoft.AspNetCore.Mvc;
 2: using Microsoft.EntityFrameworkCore;
 3: using OpenMU_Web.Data;
 4: using OpenMU_Web.Models;
 5: using System.Collections.Concurrent;
 6: 
 7: namespace OpenMU_Web.Endpoints;
 8: 
 9: public static class RegistrationEndpoints
10: {
11:     public static void MapRegistrationEndpoints(this WebApplication app)
12:     {
13:         app.MapPost("/api/register", async (HttpContext context, OpenMuContext db, ConcurrentDictionary<string, DateTime> ipLimit, [FromServices] ILogger<Program> logger) =>
14:         {
15:             try
16:             {
17:                 if (!context.Request.Headers.TryGetValue("X-Requested-With", out var v) || v != "XMLHttpRequest")
18:                     return Results.Json(new { code = "INVALID_REQUEST" }, statusCode: 400);
19: 
20:                 var remoteIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
21:                 if (ipLimit.TryGetValue(remoteIp, out var lastReg) && lastReg > DateTime.UtcNow.AddDays(-1))
22:                     return Results.Json(new { code = "RATE_LIMIT_IP", message = "Limit of 1 account per 24h for this IP." }, statusCode: 429);
23: 
24:                 var form = await context.Request.ReadFormAsync();
25:                 var username = form["username"].ToString().Trim();
26:                 var password = form["password"].ToString();
27:                 var confirmPassword = form["confirmPassword"].ToString();
28: 
29:                 if (!System.Text.RegularExpressions.Regex.IsMatch(username, "^[a-zA-Z0-9]{3,10}$"))
30:                     return Results.Json(new { code = "INVALID_USERNAME", message = "Invalid username format (3-10 characters)." }, statusCode: 400);
31: 
32:                 if (password.Length < 8 || password.Length > 16)
33:                     return Results.Json(new { code = "INVALID_PASSWORD_LENGTH", message = "Password must be 8-16 characters." }, statusCode: 400);
34: 
35:                 if (password != confirmPassword)
36:                     return Results.Json(new { code = "PASSWORDS_DO_NOT_MATCH", message = "Passwords do not match." }, statusCode: 400);
37: 
38:                 var securityCode = form["securityCode"].ToString();
39:                 if (!System.Text.RegularExpressions.Regex.IsMatch(securityCode, "^[0-9]{6,10}$"))
40:                     return Results.Json(new { code = "INVALID_SECURITY_CODE", message = "Security code must be 6-10 digits." }, statusCode: 400);
41: 
42:                 var email = form["email"].ToString().Trim();
43:                 if (!System.Net.Mail.MailAddress.TryCreate(email, out _))
44:                     return Results.Json(new { code = "INVALID_EMAIL", message = "Invalid email format." }, statusCode: 400);
45: 
46:                 if (await db.Accounts.AnyAsync(a => a.LoginName == username))
47:                     return Results.Json(new { code = "USERNAME_TAKEN", message = "Username is already taken." }, statusCode: 400);
48: 
49:                 var newVault = new ItemStorage { Id = Guid.NewGuid(), Money = 0 };
50:                 var account = new Account
51:                 {
52:                     Id = Guid.NewGuid(),
53:                     LoginName = username,
54:                     PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
55:                     SecurityCode = form["securityCode"].ToString(),
56:                     EMail = email,
57:                     RegistrationDate = DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Utc),
58:                     VaultId = newVault.Id,
59:                     LanguageIsoCode = form["language"].ToString() ?? "en",
60:                     State = 0
61:                 };
62: 
63:                 // OpenMU's DB rejects inserting the vault and the account in a single
64:                 // SaveChanges, so they go in sequence (vault first, for the FK). Wrapping
65:                 // both in one transaction keeps that order but makes them atomic: if the
66:                 // account insert fails (e.g. a race on the unique login), both roll back
67:                 // and no orphan vault is left behind.
68:                 await using var tx = await db.Database.BeginTransactionAsync();
69:                 db.ItemStorages.Add(newVault);
70:                 await db.SaveChangesAsync();
71:                 db.Accounts.Add(account);
72:                 try
73:                 {
74:                     await db.SaveChangesAsync();
75:                 }
76:                 catch (DbUpdateException)
77:                 {
78:                     return Results.Json(new { code = "USERNAME_TAKEN", message = "Username is already taken." }, statusCode: 400);
79:                 }
80:                 await tx.CommitAsync();
81: 
82:                 ipLimit[remoteIp] = DateTime.UtcNow;
83:                 return Results.Json(new { code = "REGISTRATION_SUCCESS", message = "Account created successfully!" });
84:             }
85:             catch (Exception ex)
86:             {
87:                 logger.LogError(ex, "Error during registration");
88:                     return Results.Json(new { code = "SERVER_ERROR", message = "An unexpected server error occurred." }, statusCode: 500);
89:             }
90:         });
91:     }
92: }
````

## File: web/Models/Account.cs
````csharp
 1: using System.ComponentModel.DataAnnotations;
 2: using System.ComponentModel.DataAnnotations.Schema;
 3: 
 4: namespace OpenMU_Web.Models;
 5: 
 6: [Table("Account", Schema = "data")]
 7: public class Account
 8: {
 9:     [Key] public Guid Id { get; set; }
10:     public string LoginName { get; set; } = "";
11:     public string PasswordHash { get; set; } = "";
12:     public string SecurityCode { get; set; } = "";
13:     public string EMail { get; set; } = "";
14:     public DateTime RegistrationDate { get; set; }
15:     public int State { get; set; } = 0;
16:     public short TimeZone { get; set; } = 0;
17:     public string VaultPassword { get; set; } = "";
18:     public bool IsVaultExtended { get; set; } = false;
19:     public bool IsTemplate { get; set; } = false;
20:     public string LanguageIsoCode { get; set; } = "en";
21:     public Guid? VaultId { get; set; }
22: }
````

## File: web/Models/Character.cs
````csharp
 1: using System.ComponentModel.DataAnnotations;
 2: using System.ComponentModel.DataAnnotations.Schema;
 3: 
 4: namespace OpenMU_Web.Models;
 5: 
 6: [Table("Character", Schema = "data")]
 7: public class Character
 8: {
 9:     [Key] public Guid Id { get; set; }
10:     public string Name { get; set; } = "";
11:     public long Experience { get; set; }
12:     public Guid CharacterClassId { get; set; }
13: }
````

## File: web/Models/ItemStorage.cs
````csharp
 1: using System.ComponentModel.DataAnnotations;
 2: using System.ComponentModel.DataAnnotations.Schema;
 3: 
 4: namespace OpenMU_Web.Models;
 5: 
 6: [Table("ItemStorage", Schema = "data")]
 7: public class ItemStorage
 8: {
 9:     [Key] public Guid Id { get; set; }
10:     public int Money { get; set; }
11: }
````

## File: web/Pages/_ViewStart.cshtml
````razor
1: @{
2:     Layout = "_Layout";
3: }
````

## File: web/Pages/Armory.cshtml
````razor
 1: @page "/armory"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Armory";
 4:     ViewData["BodyClass"] = "armory-body";
 5:     ViewData["ActivePage"] = "/armory";
 6: }
 7: 
 8: <h2 data-i18n="armoryTitle">Armory</h2>
 9: 
10: <div class="server-status" id="serverStatus">
11:     <span class="status-dot" id="statusDot"></span>
12:     <span id="statusText">Checking...</span>
13: </div>
14: 
15: <form class="armory-search" id="armorySearch">
16:     <input type="text" id="charInput" maxlength="10" autocomplete="off"
17:            data-i18n-placeholder="armorySearch" placeholder="Character name...">
18:     <button type="submit" data-i18n="armoryBtn">Search</button>
19: </form>
20: 
21: <div class="armory-content">
22:     <!-- Left: character panel (placeholder image + basic info) -->
23:     <div class="armory-char">
24:         <img id="charImage" class="armory-char-image" src="/img/char-placeholder.svg" alt="Character">
25:         <div class="armory-char-info" id="charInfo"></div>
26:     </div>
27: 
28:     <!-- Right: equipped items (paper doll) -->
29:     <div class="armory-equip" id="armoryEquip">
30:         <p class="armory-message" id="armoryMessage" data-i18n="armoryHint">
31:             Search for a character to view their equipment.
32:         </p>
33:     </div>
34: </div>
35: 
36: @* Tooltip lives in BodyEnd (outside .container) so its position:fixed resolves against the    *@
37: @* viewport — .container's backdrop-filter would otherwise become its containing block.         *@
38: @section BodyEnd {
39:     <div id="itemTooltip" class="item-tooltip" role="tooltip"></div>
40: }
41: 
42: @section Scripts {
43:     <script src="/js/armory.js"></script>
44: }
````

## File: web/Pages/Changepass.cshtml
````razor
 1: @page "/changepass"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Change Password";
 4: }
 5: 
 6: <h2 data-i18n="titleChange">Change Password</h2>
 7: <form id="changePassForm">
 8:     <div class="form-group">
 9:         <label data-i18n="login">Login</label>
10:         <input type="text" name="username" required data-i18n-placeholder="placeholderLogin">
11:     </div>
12:     <div class="form-group">
13:         <label data-i18n="oldPass">Current Password</label>
14:         <input type="password" name="oldPassword" required data-i18n-placeholder="placeholderPass">
15:     </div>
16:     <div class="form-group">
17:         <label data-i18n="newPass">New Password</label>
18:         <input type="password" name="newPassword" required minlength="8" maxlength="16"
19:                data-i18n-placeholder="placeholderPass">
20:     </div>
21:     <button type="submit" id="submitBtn">
22:         <span id="btnText" data-i18n="btnChange">Update Password</span>
23:         <div id="btnLoader" class="spinner-loader"></div>
24:     </button>
25: </form>
26: <div id="message"></div>
27: 
28: @section FooterNav {
29:     <a href="/" class="nav-link"><span data-i18n="navHome">Home</span></a>
30: }
31: 
32: @section Scripts {
33:     <script src="/js/changepass.js"></script>
34: }
````

## File: web/Pages/Commands.cshtml
````razor
 1: @page "/commands"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Commands";
 4:     ViewData["BodyClass"] = "stats-body";
 5:     ViewData["ActivePage"] = "/commands";
 6: }
 7: 
 8: <h2 data-i18n="commandsTitle">Chat Commands</h2>
 9: <p class="commands-intro" data-i18n="commandsIntro">Commands available to players.</p>
10: 
11: <div id="commandsContainer"></div>
12: 
13: <div class="cmd-hint" id="cmdHint" data-i18n="cmdHint"></div>
14: 
15: @section Styles {
16:     <link rel="stylesheet" href="/css/commands.css">
17: }
18: 
19: @section Scripts {
20:     <script src="/js/commands.js"></script>
21: }
````

## File: web/Pages/Events.cshtml
````razor
 1: @page "/events"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Events";
 4:     ViewData["BodyClass"] = "stats-body";
 5:     ViewData["ActivePage"] = "/events";
 6: }
 7: 
 8: <h2 data-i18n="eventsTitle">Nadchodzące Wydarzenia</h2>
 9: 
10: <div class="server-status" id="serverStatus">
11:     <span class="status-dot" id="statusDot"></span>
12:     <span id="statusText">Checking...</span>
13: </div>
14: 
15: <div id="eventsContainer">
16:     <div class="event-loader">...</div>
17: </div>
18: 
19: @section Styles {
20:     <link rel="stylesheet" href="/css/events.css">
21: }
22: 
23: @section Scripts {
24:     <script src="/js/events.js"></script>
25: }
````

## File: web/Pages/Index.cshtml
````razor
 1: @page "/"
 2: @{
 3:     ViewData["Title"] = "OpenMU";
 4:     ViewData["ContainerClass"] = "index-container";
 5:     ViewData["ActivePage"] = "/";
 6: }
 7: 
 8: <div class="index-grid">
 9:     <div class="index-left">
10:         <div class="index-title" id="welcomeTitle">Welcome to OpenMU</div>
11:         <div class="index-text" id="welcomeText"></div>
12:         <div class="details-list" id="detailsList"></div>
13:     </div>
14: 
15:     <div class="index-right">
16:         <div class="index-status-row">
17:             <div class="index-status">
18:                 <div class="status-dot-box" id="indexStatusDot"></div>
19:                 <div class="status-value" id="indexStatusText">---</div>
20:                 <div class="status-label" data-i18n="srvStatus">Server Status</div>
21:             </div>
22:             <div class="index-status">
23:                 <div class="players-value" id="indexPlayersText">0</div>
24:                 <div class="status-label" data-i18n="playersOnline">Online Players</div>
25:             </div>
26:         </div>
27:         <div id="downloadArea" class="dl-area"></div>
28:     </div>
29: </div>
30: 
31: @section Styles {
32:     <link rel="stylesheet" href="/css/index.css">
33: }
34: 
35: @section Scripts {
36:     <script src="/js/index.js"></script>
37: }
````

## File: web/Pages/Register.cshtml
````razor
 1: @page "/register"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Registration";
 4: }
 5: 
 6: <h2 data-i18n="title">OpenMU</h2>
 7: <form id="regForm">
 8:     <div class="form-group">
 9:         <label data-i18n="login">Login</label>
10:         <input type="text" name="username" required minlength="3" maxlength="10"
11:                data-i18n-placeholder="placeholderLogin">
12:     </div>
13:     <div class="form-group">
14:         <label data-i18n="email">Email</label>
15:         <input type="email" name="email" required data-i18n-placeholder="placeholderEmail">
16:     </div>
17:     <div class="form-group">
18:         <label data-i18n="pass">Password</label>
19:         <input type="password" name="password" required minlength="8" maxlength="16"
20:                data-i18n-placeholder="placeholderPass">
21:     </div>
22:     <div class="form-group">
23:         <label data-i18n="confirmPass">Confirm Password</label>
24:         <input type="password" name="confirmPassword" required minlength="8" maxlength="16"
25:                data-i18n-placeholder="placeholderConfirmPass">
26:     </div>
27:     <div class="form-group">
28:         <label data-i18n="pin">Security Code (PIN)</label>
29:         <input type="text" name="securityCode" required minlength="6" maxlength="10" pattern="[0-9]{6,10}"
30:                data-i18n-placeholder="placeholderPin">
31:         <div class="warning-box" data-i18n="pinWarn">Required for in-game character operations.</div>
32:     </div>
33:     <button type="submit" id="submitBtn">
34:         <span id="btnText" data-i18n="btnReg">Create Account</span>
35:         <div id="btnLoader" class="spinner-loader"></div>
36:     </button>
37: </form>
38: <div id="message"></div>
39: 
40: @section FooterNav {
41:     <a href="/" class="nav-link"><span data-i18n="navHome">Home</span></a>
42:     <a href="/changepass" class="nav-link"><span data-i18n="navChangePass">Change Password</span></a>
43: }
44: 
45: @section Scripts {
46:     <script src="/js/register.js"></script>
47: }
````

## File: web/Pages/Stats.cshtml
````razor
 1: @page "/stats"
 2: @{
 3:     ViewData["Title"] = "OpenMU - Server Statistics";
 4:     ViewData["BodyClass"] = "stats-body";
 5:     ViewData["ActivePage"] = "/stats";
 6: }
 7: 
 8: <h2 data-i18n="rankingTitle">Top 10 Heroes</h2>
 9: 
10: <div class="server-status" id="serverStatus">
11:     <span class="status-dot" id="statusDot"></span>
12:     <span id="statusText">Checking...</span>
13: </div>
14: 
15: <table>
16:     <thead>
17:         <tr>
18:             <th style="width: 50px;">#</th>
19:             <th data-i18n="charName">Character</th>
20:             <th data-i18n="charClass">Class</th>
21:             <th data-i18n="charLvl">Level</th>
22:             <th data-i18n="charMl" class="master-level">Master Level</th>
23:         </tr>
24:     </thead>
25:     <tbody id="rankingBody">
26:         <tr>
27:             <td colspan="5" class="table-loader">...</td>
28:         </tr>
29:     </tbody>
30: </table>
31: 
32: @section Scripts {
33:     <script src="/js/stats.js"></script>
34: }
````

## File: web/Services/RateLimiter.cs
````csharp
 1: using System.Collections.Concurrent;
 2: 
 3: namespace OpenMU_Web.Services;
 4: 
 5: public class RateLimiter
 6: {
 7:     private readonly ConcurrentDictionary<string, (int Count, DateTime WindowStart)> _store = new();
 8: 
 9:     public bool IsLimited(string key, int maxAttempts, TimeSpan window)
10:     {
11:         var now = DateTime.UtcNow;
12:         var (count, _) = _store.AddOrUpdate(key,
13:             _ => (1, now),
14:             (_, entry) =>
15:             {
16:                 if (now - entry.WindowStart > window)
17:                     return (1, now);
18:                 return (entry.Count + 1, entry.WindowStart);
19:             });
20: 
21:         return count > maxAttempts;
22:     }
23: 
24:     public void Cleanup(DateTime now, TimeSpan expiration)
25:     {
26:         var expiredKeys = _store
27:             .Where(kvp => now - kvp.Value.WindowStart > expiration)
28:             .Select(kvp => kvp.Key)
29:             .ToList();
30: 
31:         foreach (var key in expiredKeys)
32:             _store.TryRemove(key, out _);
33:     }
34: }
````

## File: web/wwwroot/css/commands.css
````css
  1: .commands-intro {
  2:     text-align: center;
  3:     font-size: 0.9rem;
  4:     color: #aaa;
  5:     margin: -0.4rem 0 1.6rem;
  6: }
  7: 
  8: .cmd-section {
  9:     margin-bottom: 1.6rem;
 10: }
 11: 
 12: .cmd-section-title {
 13:     font-size: 0.8rem;
 14:     text-transform: uppercase;
 15:     letter-spacing: 2px;
 16:     color: var(--primary);
 17:     margin: 0 0 0.7rem;
 18:     padding-bottom: 0.4rem;
 19:     border-bottom: 1px solid rgba(212, 175, 55, 0.2);
 20: }
 21: 
 22: .cmd-card {
 23:     display: flex;
 24:     align-items: baseline;
 25:     gap: 0.9rem;
 26:     background: rgba(0, 0, 0, 0.3);
 27:     border: 1px solid rgba(255, 255, 255, 0.08);
 28:     border-radius: 10px;
 29:     padding: 0.7rem 1rem;
 30:     margin-bottom: 0.5rem;
 31:     transition: border-color 0.3s;
 32: }
 33: 
 34: .cmd-card:hover {
 35:     border-color: rgba(212, 175, 55, 0.35);
 36: }
 37: 
 38: .cmd-signature {
 39:     flex: 0 0 auto;
 40:     font-family: "Liberation Mono", "DejaVu Sans Mono", monospace;
 41:     font-size: 0.9rem;
 42:     white-space: nowrap;
 43: }
 44: 
 45: .cmd-key {
 46:     color: var(--primary);
 47:     font-weight: bold;
 48: }
 49: 
 50: .cmd-args {
 51:     color: #7f8c9a;
 52:     margin-left: 4px;
 53: }
 54: 
 55: .cmd-desc {
 56:     flex: 1;
 57:     min-width: 0;
 58:     font-size: 0.85rem;
 59:     color: #ccc;
 60:     line-height: 1.5;
 61: }
 62: 
 63: .cmd-desc code {
 64:     font-family: "Liberation Mono", "DejaVu Sans Mono", monospace;
 65:     font-size: 0.82rem;
 66:     color: var(--primary);
 67:     background: rgba(212, 175, 55, 0.1);
 68:     padding: 1px 5px;
 69:     border-radius: 4px;
 70: }
 71: 
 72: .cmd-desc b {
 73:     color: #e0e0e0;
 74: }
 75: 
 76: .cmd-hint {
 77:     text-align: center;
 78:     font-size: 0.8rem;
 79:     color: #888;
 80:     font-style: italic;
 81:     margin-top: 1.5rem;
 82:     padding: 0.9rem 1rem;
 83:     background: rgba(0, 0, 0, 0.2);
 84:     border-radius: 10px;
 85:     border: 1px solid rgba(255, 255, 255, 0.05);
 86: }
 87: 
 88: .cmd-hint code {
 89:     font-family: "Liberation Mono", "DejaVu Sans Mono", monospace;
 90:     color: var(--primary);
 91:     background: rgba(212, 175, 55, 0.1);
 92:     padding: 1px 6px;
 93:     border-radius: 4px;
 94: }
 95: 
 96: @media (max-width: 600px) {
 97:     .cmd-card {
 98:         flex-direction: column;
 99:         gap: 0.25rem;
100:     }
101:     .cmd-signature {
102:         white-space: normal;
103:     }
104: }
````

## File: web/wwwroot/css/events.css
````css
  1: .event-card {
  2:     background: rgba(0, 0, 0, 0.3);
  3:     border: 1px solid rgba(255, 255, 255, 0.08);
  4:     border-radius: 12px;
  5:     padding: 1.5rem;
  6:     margin-bottom: 1.2rem;
  7:     transition: border-color 0.3s;
  8: }
  9: 
 10: .event-card:last-child {
 11:     margin-bottom: 0;
 12: }
 13: 
 14: .event-header {
 15:     display: flex;
 16:     align-items: center;
 17:     justify-content: space-between;
 18:     margin-bottom: 0.8rem;
 19: }
 20: 
 21: .event-name {
 22:     font-size: 1.1rem;
 23:     font-weight: bold;
 24:     color: #fff;
 25:     letter-spacing: 1px;
 26: }
 27: 
 28: .event-duration {
 29:     font-size: 0.75rem;
 30:     color: #888;
 31:     background: rgba(255, 255, 255, 0.05);
 32:     padding: 4px 10px;
 33:     border-radius: 20px;
 34:     letter-spacing: 0.5px;
 35: }
 36: 
 37: .event-countdown {
 38:     text-align: center;
 39:     padding: 1rem 0;
 40: }
 41: 
 42: .countdown-number {
 43:     font-size: 2.0rem;
 44:     font-weight: bold;
 45:     font-variant-numeric: tabular-nums;
 46:     color: var(--primary);
 47:     text-shadow: 0 0 20px rgba(212, 175, 55, 0.3);
 48:     letter-spacing: 2px;
 49: }
 50: 
 51: .countdown-label {
 52:     font-size: 0.75rem;
 53:     color: #888;
 54:     text-transform: uppercase;
 55:     letter-spacing: 2px;
 56:     margin-top: 4px;
 57: }
 58: 
 59: .event-timetable {
 60:     display: flex;
 61:     flex-wrap: wrap;
 62:     gap: 6px;
 63:     justify-content: center;
 64: }
 65: 
 66: .event-body {
 67:     display: flex;
 68:     gap: 1.5rem;
 69:     align-items: center;
 70:     margin-top: 1rem;
 71: }
 72: 
 73: .event-left {
 74:     flex: 0 0 220px;
 75:     text-align: center;
 76: }
 77: 
 78: .event-right {
 79:     flex: 1;
 80:     min-width: 0;
 81:     padding-left: 1.5rem;
 82:     border-left: 1px solid rgba(255, 255, 255, 0.1);
 83: }
 84: 
 85: @media (max-width: 600px) {
 86:     .event-body {
 87:         flex-direction: column;
 88:     }
 89:     .event-left {
 90:         flex: none;
 91:     }
 92:     .event-right {
 93:         border-left: none;
 94:         padding-left: 0;
 95:         padding-top: 1rem;
 96:         border-top: 1px solid rgba(255, 255, 255, 0.1);
 97:         width: 100%;
 98:     }
 99: }
100: 
101: .event-time-badge {
102:     font-size: 0.7rem;
103:     padding: 3px 10px;
104:     border-radius: 4px;
105:     background: rgba(255, 255, 255, 0.06);
106:     color: #aaa;
107:     letter-spacing: 0.5px;
108: }
109: 
110: .event-time-badge.next {
111:     background: rgba(212, 175, 55, 0.15);
112:     color: var(--primary);
113:     border: 1px solid rgba(212, 175, 55, 0.3);
114:     font-weight: bold;
115: }
116: 
117: .event-status {
118:     text-align: center;
119:     font-size: 0.85rem;
120:     color: #2ecc71;
121:     margin-top: 0.5rem;
122:     display: none;
123: }
124: 
125: .event-status.active {
126:     display: block;
127:     animation: pulse 2s infinite;
128: }
129: 
130: .event-icon {
131:     font-size: 1.3rem;
132:     margin-right: 8px;
133: }
134: 
135: .event-red-dragon .event-name { color: #e74c3c; }
136: .event-red-dragon .countdown-number { color: #e74c3c; text-shadow: 0 0 20px rgba(231, 76, 60, 0.3); }
137: .event-red-dragon .event-time-badge.next { background: rgba(231, 76, 60, 0.15); color: #e74c3c; border-color: rgba(231, 76, 60, 0.3); }
138: 
139: .event-golden .event-name { color: #ffd700; }
140: .event-golden .countdown-number { color: #ffd700; text-shadow: 0 0 20px rgba(255, 215, 0, 0.3); }
141: .event-golden .event-time-badge.next { background: rgba(255, 215, 0, 0.15); color: #ffd700; border-color: rgba(255, 215, 0, 0.3); }
142: 
143: .event-blood-castle .event-name { color: #3498db; }
144: .event-blood-castle .countdown-number { color: #3498db; text-shadow: 0 0 20px rgba(52, 152, 219, 0.3); }
145: .event-blood-castle .event-time-badge.next { background: rgba(52, 152, 219, 0.15); color: #3498db; border-color: rgba(52, 152, 219, 0.3); }
146: 
147: .event-chaos-castle .event-name { color: #9b59b6; }
148: .event-chaos-castle .countdown-number { color: #9b59b6; text-shadow: 0 0 20px rgba(155, 89, 182, 0.3); }
149: .event-chaos-castle .event-time-badge.next { background: rgba(155, 89, 182, 0.15); color: #9b59b6; border-color: rgba(155, 89, 182, 0.3); }
150: 
151: .event-devil-square .event-name { color: #1abc9c; }
152: .event-devil-square .countdown-number { color: #1abc9c; text-shadow: 0 0 20px rgba(26, 188, 156, 0.3); }
153: .event-devil-square .event-time-badge.next { background: rgba(26, 188, 156, 0.15); color: #1abc9c; border-color: rgba(26, 188, 156, 0.3); }
154: 
155: .event-happy-hour .event-name { color: #e84393; }
156: .event-happy-hour .countdown-number { color: #e84393; text-shadow: 0 0 20px rgba(232, 67, 147, 0.3); }
157: .event-happy-hour .event-time-badge.next { background: rgba(232, 67, 147, 0.15); color: #e84393; border-color: rgba(232, 67, 147, 0.3); }
158: .event-happy-hour .event-description { font-weight: bold; }
159: 
160: .event-white-wizard .event-name { color: #e8eeff; }
161: .event-white-wizard .countdown-number { color: #e8eeff; text-shadow: 0 0 20px rgba(232, 238, 255, 0.3); }
162: .event-white-wizard .event-time-badge.next { background: rgba(232, 238, 255, 0.15); color: #e8eeff; border-color: rgba(232, 238, 255, 0.3); }
163: 
164: .event-description {
165:     text-align: center;
166:     font-size: 0.8rem;
167:     color: #aaa;
168:     margin-top: -0.5rem;
169:     margin-bottom: 0.5rem;
170:     font-style: italic;
171: }
172: 
173: .event-loader {
174:     text-align: center;
175:     padding: 2rem;
176:     color: #888;
177:     font-size: 0.9rem;
178: }
````

## File: web/wwwroot/css/index.css
````css
  1: .index-container {
  2:     max-width: 900px;
  3: }
  4: 
  5: .index-container .lang-switch {
  6:     margin-bottom: 0;
  7: }
  8: 
  9: .index-grid {
 10:     display: flex;
 11:     gap: 2.5rem;
 12:     align-items: stretch;
 13: }
 14: 
 15: .index-left {
 16:     flex: 1.4;
 17:     display: flex;
 18:     flex-direction: column;
 19:     gap: 1rem;
 20:     margin-top: 2rem;
 21:     position: relative;
 22: }
 23: .index-left::after {
 24:     content: "";
 25:     position: absolute;
 26:     right: -1.25rem;
 27:     top: 0;
 28:     bottom: 0;
 29:     width: 1px;
 30:     background: rgba(255, 255, 255, 0.15);
 31: }
 32: 
 33: .index-right {
 34:     flex: 1;
 35:     display: flex;
 36:     flex-direction: column;
 37:     gap: 0.2rem;
 38: }
 39: 
 40: .index-status-row {
 41:     display: flex;
 42:     gap: 0.5rem;
 43:     margin-top: 2rem;
 44: }
 45: 
 46: .index-status-row .index-status {
 47:     flex: 1;
 48:     margin-top: 0;
 49: }
 50: 
 51: .index-status {
 52:     text-align: center;
 53:     padding: 0.8rem 1rem;
 54:     background: rgba(0, 0, 0, 0.25);
 55:     border-radius: 12px;
 56:     border: 1px solid rgba(255, 255, 255, 0.06);
 57: }
 58: 
 59: .index-title {
 60:     font-size: 1.6rem;
 61:     font-weight: bold;
 62:     color: var(--primary);
 63:     letter-spacing: 2px;
 64:     text-transform: uppercase;
 65: }
 66: 
 67: .index-text {
 68:     font-size: 0.9rem;
 69:     line-height: 1.7;
 70:     color: #ccc;
 71:     white-space: pre-line;
 72: }
 73: 
 74: .details-list {
 75:     list-style: none;
 76:     padding: 0;
 77:     margin: 0;
 78:     display: flex;
 79:     flex-direction: column;
 80:     gap: 6px;
 81: }
 82: 
 83: .details-row {
 84:     display: flex;
 85:     flex-wrap: wrap;
 86:     gap: 6px;
 87: }
 88: 
 89: .details-row li {
 90:     font-size: 0.8rem;
 91:     padding: 6px 14px;
 92:     border-radius: 20px;
 93:     background: rgba(212, 175, 55, 0.1);
 94:     border: 1px solid rgba(212, 175, 55, 0.25);
 95:     color: var(--primary);
 96:     letter-spacing: 0.5px;
 97:     list-style: none;
 98: }
 99: 
100: .details-row .detail-label {
101:     color: #ccc;
102: }
103: 
104: .details-row a {
105:     color: #3498db;
106:     text-decoration: none;
107: }
108: 
109: .details-row a:hover {
110:     text-decoration: underline;
111: }
112: 
113: .status-dot-box {
114:     width: 18px;
115:     height: 18px;
116:     border-radius: 50%;
117:     display: inline-block;
118:     margin-bottom: 6px;
119:     transition: background 0.3s;
120: }
121: 
122: .status-dot-box.online {
123:     background: #2ecc71;
124:     box-shadow: 0 0 10px rgba(46, 204, 113, 0.5);
125:     animation: pulse 2s infinite;
126: }
127: 
128: .status-dot-box.offline {
129:     background: #e74c3c;
130:     box-shadow: 0 0 10px rgba(231, 76, 60, 0.5);
131: }
132: 
133: .status-value {
134:     font-size: 1.2rem;
135:     font-weight: bold;
136:     letter-spacing: 1px;
137:     margin-bottom: 2px;
138: }
139: 
140: .status-value.online { color: #2ecc71; }
141: .status-value.offline { color: #e74c3c; }
142: 
143: .status-label {
144:     font-size: 0.75rem;
145:     color: #888;
146:     text-transform: uppercase;
147:     letter-spacing: 2px;
148: }
149: 
150: .players-value {
151:     font-size: 1.8rem;
152:     font-weight: bold;
153:     letter-spacing: 2px;
154:     color: #3498db;
155:     margin-bottom: 4px;
156: }
157: 
158: /* === DOWNLOAD DROPDOWN === */
159: /* A single gold "Download" button reveals the targets from muConfig.downloads. */
160: .dl-area { margin-top: 0.4rem; }
161: 
162: .dl-gold {
163:     background: linear-gradient(135deg, #d4af37 0%, #a68a2d 100%);
164:     color: #000;
165:     border: none;
166: }
167: .dl-gold:hover {
168:     filter: brightness(1.1);
169:     transform: translateY(-2px);
170:     box-shadow: 0 8px 25px rgba(212, 175, 55, 0.35);
171: }
172: 
173: .dlC-wrap { position: relative; }
174: .dlC-trigger {
175:     display: flex;
176:     align-items: center;
177:     justify-content: center;
178:     gap: 10px;
179:     padding: 16px;
180:     border-radius: 8px;
181:     font-weight: bold;
182:     font-size: 1rem;
183:     text-transform: uppercase;
184:     letter-spacing: 2px;
185:     cursor: pointer;
186:     transition: all 0.3s;
187: }
188: .dlC-trigger .dlC-caret { font-size: 0.7rem; transition: transform 0.25s ease; }
189: .dlC-wrap.open .dlC-caret { transform: rotate(180deg); }
190: 
191: .dlC-menu {
192:     position: absolute;
193:     left: 0; right: 0;
194:     margin-top: 8px;
195:     background: rgba(15, 15, 15, 0.97);
196:     border: 1px solid rgba(212, 175, 55, 0.35);
197:     border-radius: 10px;
198:     overflow: hidden;
199:     z-index: 50;
200:     box-shadow: 0 12px 32px rgba(0, 0, 0, 0.6);
201:     /* animated slide-down reveal (can't transition display, so use opacity/transform) */
202:     opacity: 0;
203:     visibility: hidden;
204:     transform: translateY(-10px) scaleY(0.97);
205:     transform-origin: top center;
206:     max-height: 0;
207:     transition: opacity 0.22s ease, transform 0.24s ease, max-height 0.28s ease, visibility 0s linear 0.24s;
208: }
209: .dlC-wrap.open .dlC-menu {
210:     opacity: 1;
211:     visibility: visible;
212:     transform: translateY(0) scaleY(1);
213:     max-height: 320px;
214:     transition: opacity 0.22s ease, transform 0.24s ease, max-height 0.28s ease, visibility 0s;
215: }
216: 
217: .dlC-item {
218:     display: flex;
219:     align-items: center;
220:     gap: 10px;
221:     padding: 11px 14px;
222:     color: #ddd;
223:     text-decoration: none;
224:     font-size: 0.9rem;
225:     border-bottom: 1px solid rgba(255, 255, 255, 0.06);
226:     /* each row eases in slightly after the menu opens (cascade) */
227:     opacity: 0;
228:     transform: translateY(-6px);
229:     transition: opacity 0.2s ease, transform 0.2s ease, background 0.2s ease, color 0.2s ease;
230: }
231: .dlC-wrap.open .dlC-item { opacity: 1; transform: translateY(0); }
232: .dlC-wrap.open .dlC-item:nth-child(1) { transition-delay: 0.06s, 0.06s, 0s, 0s; }
233: .dlC-wrap.open .dlC-item:nth-child(2) { transition-delay: 0.11s, 0.11s, 0s, 0s; }
234: .dlC-wrap.open .dlC-item:nth-child(3) { transition-delay: 0.16s, 0.16s, 0s, 0s; }
235: .dlC-item:last-child { border-bottom: none; }
236: /* Gold is reserved as the "recommended" identity (Launcher only). Hovering the other
237:    options gives a neutral lift instead, so two items never glow gold at once. */
238: .dlC-item:hover { background: rgba(255, 255, 255, 0.04); color: #fff; }
239: .dlC-item .dlC-tag { margin-left: auto; font-size: 0.62rem; text-transform: uppercase; letter-spacing: 1px; }
240: /* Recommended option (Launcher): bold + gold accent so it reads as the suggested pick,
241:    while every entry stays an explicit, equal click — nothing auto-downloads. */
242: .dlC-item.recommended { font-weight: bold; color: #fff; background: rgba(212, 175, 55, 0.07); box-shadow: inset 3px 0 0 var(--primary); }
243: .dlC-item.recommended:hover { background: rgba(212, 175, 55, 0.14); }
244: .dlC-item.recommended .dlC-tag { color: var(--primary); font-weight: bold; }
245: .dlC-item.soon { opacity: 0.5; pointer-events: none; }
246: .dlC-item.soon .dlC-tag { color: #aaa; }
247: 
248: @media (max-width: 700px) {
249:     .index-grid {
250:         flex-direction: column;
251:         gap: 1.5rem;
252:     }
253:     /* the vertical separator only makes sense in the 2-column desktop layout;
254:        in the stacked layout it floats at the right edge and looks broken */
255:     .index-left::after {
256:         display: none;
257:     }
258: }
````

## File: web/wwwroot/img/char-placeholder.svg
````xml
 1: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 260" width="200" height="260" role="img" aria-label="Character">
 2:   <defs>
 3:     <linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
 4:       <stop offset="0" stop-color="#d4af37"/>
 5:       <stop offset="1" stop-color="#8a6d1f"/>
 6:     </linearGradient>
 7:   </defs>
 8:   <rect width="200" height="260" rx="12" fill="rgba(0,0,0,0.25)"/>
 9:   <g fill="url(#g)" opacity="0.85">
10:     <!-- helmet/head -->
11:     <circle cx="100" cy="64" r="30"/>
12:     <!-- shoulders / torso -->
13:     <path d="M52 150c0-30 21-52 48-52s48 22 48 52v8H52z"/>
14:     <!-- simple sword behind -->
15:     <rect x="150" y="40" width="6" height="150" rx="3" transform="rotate(8 153 115)"/>
16:     <rect x="140" y="60" width="26" height="8" rx="4" transform="rotate(8 153 64)"/>
17:   </g>
18:   <text x="100" y="240" text-anchor="middle" fill="#777" font-family="Liberation Sans, Arial, sans-serif" font-size="14" letter-spacing="2">CHARACTER</text>
19: </svg>
````

## File: web/wwwroot/js/armory.js
````javascript
  1: // Equipment slot layout (paper doll): 3 columns x 4 rows.
  2: const SLOTS = [
  3:     { slot: 8, col: 1, row: 1, label: 'Pet' },      // Fenrir / pet - top left
  4:     { slot: 2, col: 2, row: 1, label: 'Helm' },
  5:     { slot: 7, col: 3, row: 1, label: 'Wings' },
  6:     { slot: 0, col: 1, row: 2, label: 'Weapon' },
  7:     { slot: 3, col: 2, row: 2, label: 'Armor' },
  8:     { slot: 1, col: 3, row: 2, label: 'Shield' },
  9:     { slot: 5, col: 1, row: 3, label: 'Gloves' },
 10:     { slot: 4, col: 2, row: 3, label: 'Pants' },
 11:     { slot: 6, col: 3, row: 3, label: 'Boots' },
 12:     { slot: 9, col: 1, row: 4, label: 'Pendant' },  // accessories in one line at the bottom
 13:     { slot: 10, col: 2, row: 4, label: 'Ring' },
 14:     { slot: 11, col: 3, row: 4, label: 'Ring' },
 15: ];
 16: 
 17: function t() {
 18:     return window.muTranslations[window.currentLang()];
 19: }
 20: 
 21: async function checkServerStatus() {
 22:     const statusDot = document.getElementById('statusDot');
 23:     const statusText = document.getElementById('statusText');
 24:     try {
 25:         const response = await fetch('/api/public/server-status');
 26:         const data = await response.json();
 27:         statusDot.className = data.online ? 'status-dot online' : 'status-dot offline';
 28:         statusText.innerText = data.online ? (t().online || 'Online') : (t().offline || 'Offline');
 29:     } catch {
 30:         statusDot.className = 'status-dot offline';
 31:         statusText.innerText = t().offline || 'Offline';
 32:     }
 33: }
 34: checkServerStatus();
 35: setInterval(checkServerStatus, 30000);
 36: 
 37: function escapeHtml(value) {
 38:     return String(value).replace(/[&<>"']/g, c =>
 39:         ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
 40: }
 41: 
 42: // Custom, themed item tooltip (replaces the native browser title tooltip).
 43: const itemTooltip = document.getElementById('itemTooltip');
 44: 
 45: function buildTooltip(desc) {
 46:     const lines = desc.split('\n');
 47:     const head = `<div class="tip-head">${escapeHtml(lines[0])}</div>`;
 48:     const opts = lines.slice(1).map(line => {
 49:         let cls = 'tip-line';
 50:         if (line.startsWith('+ Exc')) cls += ' exc';
 51:         else if (line.startsWith('+ Skill')) cls += ' skill';
 52:         else if (line.includes('Socket')) cls += ' sock';
 53:         else cls += ' opt';
 54:         return `<div class="${cls}">${escapeHtml(line)}</div>`;
 55:     }).join('');
 56:     return head + opts;
 57: }
 58: 
 59: function moveTooltip(e) {
 60:     const pad = 16;
 61:     const rect = itemTooltip.getBoundingClientRect();
 62:     let x = e.clientX + pad;
 63:     let y = e.clientY + pad;
 64:     if (x + rect.width > window.innerWidth - 8) x = e.clientX - rect.width - pad;
 65:     if (y + rect.height > window.innerHeight - 8) y = window.innerHeight - rect.height - 8;
 66:     itemTooltip.style.left = Math.max(8, x) + 'px';
 67:     itemTooltip.style.top = Math.max(8, y) + 'px';
 68: }
 69: 
 70: document.addEventListener('mouseover', e => {
 71:     const slot = e.target.closest?.('.armory-slot.filled');
 72:     if (!slot || !slot.dataset.tip) return;
 73:     itemTooltip.innerHTML = buildTooltip(slot.dataset.tip);
 74:     itemTooltip.style.display = 'block';
 75:     moveTooltip(e);
 76: });
 77: document.addEventListener('mousemove', e => {
 78:     if (itemTooltip.style.display === 'block' && e.target.closest?.('.armory-slot.filled')) moveTooltip(e);
 79: });
 80: document.addEventListener('mouseout', e => {
 81:     if (e.target.closest?.('.armory-slot.filled')) itemTooltip.style.display = 'none';
 82: });
 83: 
 84: function renderEquip(items) {
 85:     const equip = document.getElementById('armoryEquip');
 86:     const bySlot = {};
 87:     items.forEach(it => bySlot[it.slot] = it);
 88: 
 89:     const cells = SLOTS.map(def => {
 90:         const item = bySlot[def.slot];
 91:         const style = `grid-column:${def.col};grid-row:${def.row};`;
 92:         if (!item) {
 93:             return `<div class="armory-slot empty" style="${style}"><span class="slot-label">${def.label}</span></div>`;
 94:         }
 95:         const badges =
 96:             (item.excellent ? '<span class="badge exc">EXC</span>' : '') +
 97:             (item.ancient ? '<span class="badge anc">ANC</span>' : '') +
 98:             (item.sockets > 0 ? `<span class="badge sock">${item.sockets}S</span>` : '');
 99:         return `<div class="armory-slot filled" style="${style}" data-tip="${escapeHtml(item.description)}">
100:                     <img src="/img/items/${escapeHtml(item.image)}" alt="${escapeHtml(item.description)}"
101:                          onerror="this.classList.add('img-missing')">
102:                     ${badges}
103:                 </div>`;
104:     }).join('');
105: 
106:     equip.innerHTML = `<div class="armory-doll">${cells}</div>`;
107: }
108: 
109: async function loadCharacter(name) {
110:     const equip = document.getElementById('armoryEquip');
111:     const charInfo = document.getElementById('charInfo');
112:     const tr = t();
113:     equip.innerHTML = `<p class="armory-message">...</p>`;
114:     charInfo.innerHTML = '';
115: 
116:     try {
117:         const response = await fetch('/api/public/armory/' + encodeURIComponent(name));
118:         if (response.status === 404) {
119:             equip.innerHTML = `<p class="armory-message error">${tr.ARMORY_NOT_FOUND}</p>`;
120:             return;
121:         }
122:         if (!response.ok) {
123:             const err = await response.json().catch(() => ({}));
124:             equip.innerHTML = `<p class="armory-message error">${tr[err.code] || tr.rankingError}</p>`;
125:             return;
126:         }
127: 
128:         const data = await response.json();
129: 
130:         charInfo.innerHTML = `
131:             <div class="armory-char-name">${escapeHtml(data.name)}</div>
132:             <div class="armory-char-class">${escapeHtml(data.className)}</div>
133:             <div class="armory-char-stats">
134:                 <span>${tr.charLvl}: <b>${data.level}</b></span>
135:                 <span>${tr.armoryResets}: <b>${data.resets}</b></span>
136:                 <span>ML: <b>${data.masterLevel}</b></span>
137:             </div>`;
138: 
139:         if (!data.items || data.items.length === 0) {
140:             renderEquip([]);
141:             equip.insertAdjacentHTML('afterbegin', `<p class="armory-message">${tr.armoryNoItems}</p>`);
142:             return;
143:         }
144:         renderEquip(data.items);
145:     } catch {
146:         equip.innerHTML = `<p class="armory-message error">${tr.rankingError}</p>`;
147:     }
148: }
149: 
150: document.getElementById('armorySearch').addEventListener('submit', e => {
151:     e.preventDefault();
152:     const name = document.getElementById('charInput').value.trim();
153:     if (name) {
154:         history.replaceState(null, '', '/armory?name=' + encodeURIComponent(name));
155:         loadCharacter(name);
156:     }
157: });
158: 
159: // Allow deep-linking via ?name=
160: const params = new URLSearchParams(location.search);
161: const initial = params.get('name');
162: if (initial) {
163:     document.getElementById('charInput').value = initial;
164:     loadCharacter(initial);
165: }
````

## File: web/wwwroot/js/changepass.js
````javascript
 1: document.getElementById('changePassForm').addEventListener('submit', async (e) => {
 2:     e.preventDefault();
 3:     const btn = document.getElementById('submitBtn'), btnText = document.getElementById('btnText'),
 4:         btnLoader = document.getElementById('btnLoader'), msgDiv = document.getElementById('message'),
 5:         t = window.muTranslations[window.currentLang()];
 6: 
 7:     msgDiv.style.display = 'none'; btn.disabled = true;
 8:     btnText.style.display = 'none'; btnLoader.style.display = 'block';
 9: 
10:     try {
11:         const response = await fetch('/api/change-password', { method: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: new FormData(e.target) });
12:         const data = await response.json();
13:         msgDiv.style.display = 'block'; msgDiv.className = response.ok ? 'success' : 'error';
14:         msgDiv.innerText = t[data.code] || data.message;
15:         if (response.ok) e.target.reset();
16:     } catch (error) {
17:         msgDiv.style.display = 'block'; msgDiv.className = 'error'; msgDiv.innerText = t.connError;
18:     } finally {
19:         btn.disabled = false;
20:         btnText.style.display = 'block'; btnLoader.style.display = 'none';
21:     }
22: });
````

## File: web/wwwroot/js/commands.js
````javascript
 1: // Player (Normal) chat commands only. Descriptions live in the translation files
 2: // (keyed by descKey); this table only holds the command signature.
 3: const COMMAND_SECTIONS = [
 4:     {
 5:         titleKey: 'cmdSecStats',
 6:         commands: [
 7:             { key: '/add', args: '&lt;stat&gt; &lt;amount&gt;', descKey: 'cmdAddDesc' },
 8:         ]
 9:     },
10:     {
11:         titleKey: 'cmdSecReset',
12:         commands: [
13:             { key: '/reset', args: '', descKey: 'cmdResetDesc' },
14:             { key: '/resetinfo', args: '', descKey: 'cmdResetInfoDesc' },
15:             { key: '/resetstats', args: '', descKey: 'cmdResetStatsDesc' },
16:         ]
17:     },
18:     {
19:         titleKey: 'cmdSecChar',
20:         commands: [
21:             { key: '/move', args: '&lt;place&gt;', descKey: 'cmdMoveDesc' },
22:             { key: '/clearinv', args: '', descKey: 'cmdClearInvDesc' },
23:             { key: '/npc', args: '', descKey: 'cmdNpcDesc' },
24:             { key: '/openware', args: '', descKey: 'cmdOpenWareDesc' },
25:             { key: '/offlevel', args: '', descKey: 'cmdOffLevelDesc' },
26:             { key: '/language', args: '&lt;code&gt;', descKey: 'cmdLanguageDesc' },
27:         ]
28:     },
29:     {
30:         titleKey: 'cmdSecSocial',
31:         commands: [
32:             { key: '/post', args: '&lt;text&gt;', descKey: 'cmdPostDesc' },
33:             { key: '/war', args: '&lt;guild&gt;', descKey: 'cmdWarDesc' },
34:             { key: '/battlesoccer', args: '&lt;guild&gt;', descKey: 'cmdBattleSoccerDesc' },
35:         ]
36:     },
37:     {
38:         titleKey: 'cmdSecHelp',
39:         commands: [
40:             { key: '/list', args: '', descKey: 'cmdListDesc' },
41:             { key: '/help', args: '&lt;command&gt;', descKey: 'cmdHelpDesc' },
42:         ]
43:     },
44: ];
45: 
46: function renderCommands(lang) {
47:     const t = window.muTranslations[lang];
48:     const html = COMMAND_SECTIONS.map(section => {
49:         const rows = section.commands.map(c => `
50:             <div class="cmd-card">
51:                 <div class="cmd-signature">
52:                     <span class="cmd-key">${c.key}</span>${c.args ? `<span class="cmd-args">${c.args}</span>` : ''}
53:                 </div>
54:                 <div class="cmd-desc">${t[c.descKey] || c.descKey}</div>
55:             </div>
56:         `).join('');
57:         return `
58:             <div class="cmd-section">
59:                 <div class="cmd-section-title">${t[section.titleKey] || section.titleKey}</div>
60:                 ${rows}
61:             </div>
62:         `;
63:     }).join('');
64:     document.getElementById('commandsContainer').innerHTML = html;
65: }
66: 
67: // lang.js applies the data-i18n text and renders the language buttons; re-render the
68: // command list (its descriptions live in the translation files) on every change.
69: window.onLanguageChanged = renderCommands;
````

## File: web/wwwroot/js/events.js
````javascript
  1: async function checkServerStatus() {
  2:     const statusDot = document.getElementById('statusDot');
  3:     const statusText = document.getElementById('statusText');
  4:     const t = window.muTranslations[window.currentLang()];
  5: 
  6:     try {
  7:         const response = await fetch('/api/public/server-status');
  8:         const data = await response.json();
  9:         if (data.online) {
 10:             statusDot.className = 'status-dot online';
 11:             statusText.innerText = t.online || 'Online';
 12:         } else {
 13:             statusDot.className = 'status-dot offline';
 14:             statusText.innerText = t.offline || 'Offline';
 15:         }
 16:     } catch {
 17:         statusDot.className = 'status-dot offline';
 18:         statusText.innerText = t.offline || 'Offline';
 19:     }
 20: }
 21: 
 22: checkServerStatus();
 23: setInterval(checkServerStatus, 30000);
 24: 
 25: function formatCountdown(seconds) {
 26:     const h = Math.floor(seconds / 3600);
 27:     const m = Math.floor((seconds % 3600) / 60);
 28:     const s = seconds % 60;
 29:     return String(h).padStart(2, '0') + ':' +
 30:            String(m).padStart(2, '0') + ':' +
 31:            String(s).padStart(2, '0');
 32: }
 33: 
 34: const EVENT_STYLES = {
 35:     'Red Dragon Invasion': { css: 'event-red-dragon', icon: '🐉' },
 36:     'Golden Invasion': { css: 'event-golden', icon: '👑' },
 37:     'Blood Castle': { css: 'event-blood-castle', icon: '🏰' },
 38:     'Chaos Castle': { css: 'event-chaos-castle', icon: '⚡' },
 39:     'Devil Square': { css: 'event-devil-square', icon: '👹' },
 40:     'Happy Hour': { css: 'event-happy-hour', icon: '🎉' },
 41:     'White Wizard Invasion': { css: 'event-white-wizard', icon: '🧙' },
 42: };
 43: 
 44: function renderEvent(event) {
 45:     const style = EVENT_STYLES[event.name] || { css: '', icon: '📅' };
 46:     const lang = window.currentLang();
 47: 
 48:     const countdownSeconds = event.countdownSeconds;
 49:     const nextTimeStr = event.nextRunLocal || null;
 50:     const timetableHtml = event.timetable.map(t =>
 51:         `<span class="event-time-badge${t === nextTimeStr ? ' next' : ''}">${t}</span>`
 52:     ).join('');
 53: 
 54:     const t = window.muTranslations[lang];
 55:     const durationLabel = (t.eventsDuration || 'Czas trwania') + ': ' + event.durationMinutes + ' ' + (t.eventsMin || 'min');
 56: 
 57:     const descHtml = event.experienceMultiplier
 58:         ? `<div class="event-description">${(t.eventsXpMult || 'Experience')} x${event.experienceMultiplier.toFixed(1)}</div>`
 59:         : '';
 60: 
 61:     return `
 62:         <div class="event-card ${style.css}" data-event="${event.name}">
 63:             <div class="event-header">
 64:                 <div class="event-name">
 65:                     <span class="event-icon">${style.icon}</span>
 66:                     ${event.name}
 67:                 </div>
 68:                 <div class="event-duration">${durationLabel}</div>
 69:             </div>
 70:             ${descHtml}
 71:             <div class="event-body">
 72:                 <div class="event-left">
 73:                     <div class="event-countdown">
 74:                         <div class="countdown-number" data-seconds="${countdownSeconds}">
 75:                             ${formatCountdown(countdownSeconds)}
 76:                         </div>
 77:                         <div class="countdown-label" data-i18n="eventsRemaining">${t.eventsRemaining || 'remaining'}</div>
 78:                     </div>
 79:                 </div>
 80:                 <div class="event-right">
 81:                     <div class="event-timetable">${timetableHtml}</div>
 82:                 </div>
 83:             </div>
 84:         </div>
 85:     `;
 86: }
 87: 
 88: function updateCountdowns() {
 89:     document.querySelectorAll('.countdown-number').forEach(el => {
 90:         let sec = parseInt(el.getAttribute('data-seconds'));
 91:         if (sec > 0) {
 92:             sec--;
 93:             el.setAttribute('data-seconds', sec);
 94:             el.innerText = formatCountdown(sec);
 95:         }
 96:     });
 97: }
 98: 
 99: const EVENT_ORDER = ['Happy Hour', 'Chaos Castle', 'Blood Castle', 'Devil Square', 'Red Dragon Invasion', 'Golden Invasion', 'White Wizard Invasion'];
100: 
101: async function loadEvents() {
102:     const container = document.getElementById('eventsContainer');
103:     const lang = window.currentLang();
104:     const t = window.muTranslations[lang];
105: 
106:     try {
107:         const response = await fetch('/api/public/events');
108:         if (!response.ok) throw new Error('Failed to load');
109: 
110:         const data = await response.json();
111: 
112:         if (!data || data.length === 0) {
113:             container.innerHTML = '<div style="text-align:center;padding:2rem;color:#888;">' + (t.eventsNone || 'No events configured.') + '</div>';
114:             return;
115:         }
116: 
117:         data.sort((a, b) => EVENT_ORDER.indexOf(a.name) - EVENT_ORDER.indexOf(b.name));
118: 
119:         container.innerHTML = data.map(renderEvent).join('');
120:         setLanguage(lang);
121: 
122:     } catch (error) {
123:         container.innerHTML = '<div style="text-align:center;padding:2rem;color:#e74c3c;">' + (t.connError || 'Connection error.') + '</div>';
124:     }
125: }
126: 
127: loadEvents();
128: setInterval(loadEvents, 60000);
129: setInterval(updateCountdowns, 1000);
````

## File: web/wwwroot/js/register.js
````javascript
 1: document.getElementById('regForm').addEventListener('submit', async (e) => {
 2:     e.preventDefault();
 3:     const btn = document.getElementById('submitBtn'), btnText = document.getElementById('btnText'),
 4:         btnLoader = document.getElementById('btnLoader'), msgDiv = document.getElementById('message'),
 5:         t = window.muTranslations[window.currentLang()];
 6: 
 7:     btn.disabled = true; btnText.style.display = 'none'; btnLoader.style.display = 'block';
 8:     try {
 9:         const formData = new FormData(e.target);
10:         formData.append('language', window.currentLang());
11:         const response = await fetch('/api/register', { method: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: formData });
12:         const data = await response.json();
13:         msgDiv.className = response.ok ? 'success' : 'error';
14:         msgDiv.innerText = t[data.code] || data.message;
15:         msgDiv.style.display = 'block';
16:         if (response.ok) e.target.reset();
17:     } catch (error) {
18:         msgDiv.className = 'error'; msgDiv.innerText = t.connError; msgDiv.style.display = 'block';
19:     } finally {
20:         btn.disabled = false; btnText.style.display = 'block'; btnLoader.style.display = 'none';
21:     }
22: });
````

## File: web/wwwroot/js/stats.js
````javascript
 1: async function checkServerStatus() {
 2:     const statusDot = document.getElementById('statusDot');
 3:     const statusText = document.getElementById('statusText');
 4:     const t = window.t();
 5: 
 6:     try {
 7:         const response = await fetch('/api/public/server-status');
 8:         const data = await response.json();
 9: 
10:         if (data.online) {
11:             statusDot.className = 'status-dot online';
12:             statusText.innerText = t.online || 'Online';
13:         } else {
14:             statusDot.className = 'status-dot offline';
15:             statusText.innerText = t.offline || 'Offline';
16:         }
17:     } catch {
18:         statusDot.className = 'status-dot offline';
19:         statusText.innerText = t.offline || 'Offline';
20:     }
21: }
22: 
23: checkServerStatus();
24: setInterval(checkServerStatus, 30000);
25: 
26: async function loadRanking() {
27:     const rankingBody = document.getElementById('rankingBody');
28:     const t = window.t();
29: 
30:     try {
31:         const response = await fetch('/api/public/ranking');
32:         if (!response.ok) throw new Error('Failed to load');
33: 
34:         const data = await response.json();
35: 
36:         if (!data || data.length === 0) {
37:             rankingBody.innerHTML = `<tr><td colspan="5" style="text-align:center">${t.rankingNone}</td></tr>`;
38:             return;
39:         }
40: 
41:         const maxResets = (window.muConfig && window.muConfig.maxResets) || 0;
42: 
43:         rankingBody.innerHTML = data.map((char, index) => `
44:             <tr>
45:                 <td class="rank-number">${index + 1}</td>
46:                 <td class="char-name">${char.name}</td>
47:                 <td style="color: #aaa; font-size: 0.85rem; font-style: italic;">${char.className}</td>
48:                 <td style="white-space: nowrap;">
49:                     <span style="color: #fff; font-weight: bold; display: inline-block; width: 32px; text-align: right;">${char.level}</span>
50:                     <span class="reset-badge${maxResets > 0 && char.resets === maxResets ? ' max-reset' : ''}">${char.resets} RR</span>
51:                 </td>
52:                 <td class="master-level">${char.masterLevel}</td>
53:             </tr>
54:         `).join('');
55: 
56:     } catch (error) {
57:         rankingBody.innerHTML = `<tr><td colspan="5" style="text-align:center; color: #e74c3c;">${t.rankingError}</td></tr>`;
58:     }
59: }
60: 
61: loadRanking();
````

## File: web/wwwroot/en.js
````javascript
  1: window.muTranslations = window.muTranslations || {};
  2: window.muTranslations.en = {
  3:     title: "OpenMU Registration",
  4:     titleChange: "Change Password",
  5:     rankingTitle: "Top 10 Heroes",
  6: 
  7:     login: "Login",
  8:     email: "Email",
  9:     pass: "Password",
 10:     confirmPass: "Confirm Password",
 11:     oldPass: "Current Password",
 12:     newPass: "New Password",
 13:     pin: "Security Code (PIN)",
 14:     pinWarn: "Required for in-game character operations.",
 15: 
 16:     btnReg: "Create Account",
 17:     btnChange: "Update Password",
 18: 
 19:     placeholderLogin: "Account name",
 20:     placeholderEmail: "your@email.com",
 21:     placeholderPass: "********",
 22:     placeholderConfirmPass: "Repeat password",
 23:     placeholderPin: "Security code",
 24: 
 25:     connError: "Connection error.",
 26:     processing: "Processing...",
 27:     srvStatus: "Server Status",
 28:     playersOnline: "Online Players",
 29:     dlDownload: "Download",
 30:     dlRecommended: "recommended",
 31:     dlSoon: "soon",
 32:     online: "Online",
 33:     offline: "Offline",
 34: 
 35:     charName: "Character",
 36:     charClass: "Class",
 37:     charLvl: "Level",
 38:     charMl: "Master Level",
 39: 
 40:     navStats: "Server Stats",
 41:     navEvents: "Events",
 42:     navHome: "Home",
 43:     navChangePass: "Change Password",
 44:     navRegister: "Register Account",
 45:     navArmory: "Armory",
 46:     navCommands: "Commands",
 47: 
 48:     commandsTitle: "Chat Commands",
 49:     commandsIntro: "Commands available to players. Type them in the in-game chat.",
 50:     cmdSecStats: "Stats",
 51:     cmdSecReset: "Resets",
 52:     cmdSecChar: "Character & Interface",
 53:     cmdSecSocial: "Social",
 54:     cmdSecHelp: "Help",
 55:     cmdHint: "Tip: type /list in-game to see available commands, or /help &lt;command&gt; for syntax.",
 56: 
 57:     cmdAddDesc: "Adds points to the chosen stat. Stat: <b>str</b> (strength), <b>agi</b> (agility), <b>vit</b> (vitality), <b>ene</b> (energy), <b>cmd</b> (command). E.g. <code>/add str 100</code>.",
 58:     cmdResetDesc: "Performs a character reset (if available).",
 59:     cmdResetInfoDesc: "Shows the cost and rewards for the next reset.",
 60:     cmdResetStatsDesc: "Resets stats to base values and refunds points.",
 61:     cmdMoveDesc: "Teleports to a warp point (e.g. /move Lorencia).",
 62:     cmdClearInvDesc: "Clears the inventory.",
 63:     cmdNpcDesc: "Opens the NPC merchant store.",
 64:     cmdOpenWareDesc: "Opens the warehouse (vault).",
 65:     cmdOffLevelDesc: "Enables offline leveling (MU Helper).",
 66:     cmdLanguageDesc: "Changes the client language.",
 67:     cmdPostDesc: "Sends a blue message visible to all players.",
 68:     cmdWarDesc: "Requests a guild war with another guild.",
 69:     cmdBattleSoccerDesc: "Requests a guild Battle Soccer event.",
 70:     cmdListDesc: "Lists all commands available to you.",
 71:     cmdHelpDesc: "Shows the syntax and arguments of a command.",
 72: 
 73:     armoryTitle: "Armory",
 74:     armorySearch: "Character name...",
 75:     armoryBtn: "Search",
 76:     armoryResets: "Resets",
 77:     armoryHint: "Search for a character to view their equipment.",
 78:     armoryNoItems: "This character has no equipped items.",
 79:     ARMORY_NOT_FOUND: "Character not found.",
 80:     RATE_LIMIT_ARMORY: "Too many requests. Try again later.",
 81: 
 82:     eventsTitle: "Upcoming Events",
 83:     eventsRemaining: "remaining",
 84:     eventsDuration: "Duration",
 85:     eventsMin: "min",
 86:     eventsXpMult: "Experience",
 87:     eventsShow: "Schedule",
 88:     eventsHide: "Hide",
 89:     eventsNone: "No events configured.",
 90: 
 91:     INVALID_REQUEST: "Invalid request.",
 92:     RATE_LIMIT_IP: "Limit: 1 account per 24h per IP.",
 93:     INVALID_USERNAME: "Invalid username format (3-10 characters, letters and numbers only).",
 94:     INVALID_PASSWORD_LENGTH: "Password must be 8-16 characters long.",
 95:     INVALID_SECURITY_CODE: "Security code must contain 6-10 digits.",
 96:     INVALID_EMAIL: "Invalid email format.",
 97:     USERNAME_TAKEN: "Username is already taken.",
 98:     PASSWORDS_DO_NOT_MATCH: "Passwords do not match.",
 99:     REGISTRATION_SUCCESS: "Account created successfully!",
100:     RATE_LIMIT_PASSWORD: "Too many attempts. Try again in 15 minutes.",
101:     USER_NOT_FOUND: "User does not exist.",
102:     INVALID_OLD_PASSWORD: "Current password is incorrect.",
103:     PASSWORD_CHANGE_SUCCESS: "Password changed successfully!",
104:     RATE_LIMIT_RANKING: "Too many requests. Try again later.",
105:     DATABASE_ERROR: "Database error. Please try again later.",
106:     SERVER_ERROR: "An unexpected server error occurred.",
107:     rankingNone: "No heroes found.",
108:     rankingError: "Connection error."
109: };
````

## File: web/wwwroot/es.js
````javascript
  1: window.muTranslations = window.muTranslations || {};
  2: window.muTranslations.es = {
  3:     title: "Registro OpenMU",
  4:     titleChange: "Cambiar Contraseña",
  5:     rankingTitle: "Top 10 Héroes",
  6: 
  7:     login: "Usuario",
  8:     email: "Correo Electrónico",
  9:     pass: "Contraseña",
 10:     confirmPass: "Confirmar Contraseña",
 11:     oldPass: "Contraseña Actual",
 12:     newPass: "Nueva Contraseña",
 13:     pin: "Código de Seguridad (PIN)",
 14:     pinWarn: "Requerido para operaciones de personajes en el juego.",
 15: 
 16:     btnReg: "Crear Cuenta",
 17:     btnChange: "Actualizar Contraseña",
 18: 
 19:     placeholderLogin: "Nombre de usuario",
 20:     placeholderEmail: "tu@email.com",
 21:     placeholderPass: "********",
 22:     placeholderConfirmPass: "Repetir contraseña",
 23:     placeholderPin: "Código de seguridad",
 24: 
 25:     connError: "Error de conexión.",
 26:     processing: "Procesando...",
 27:     srvStatus: "Estado del Servidor",
 28:     playersOnline: "Jugadores En Línea",
 29:     dlDownload: "Descargar",
 30:     dlRecommended: "recomendado",
 31:     dlSoon: "próximamente",
 32:     online: "En línea",
 33:     offline: "Desconectado",
 34: 
 35:     charName: "Personaje",
 36:     charClass: "Clase",
 37:     charLvl: "Nivel",
 38:     charMl: "Nivel Master",
 39: 
 40:     navStats: "Estadísticas del Servidor",
 41:     navEvents: "Eventos",
 42:     navHome: "Inicio",
 43:     navChangePass: "Cambiar Contraseña",
 44:     navRegister: "Registrar Cuenta",
 45:     navArmory: "Armería",
 46:     navCommands: "Comandos",
 47: 
 48:     commandsTitle: "Comandos de Chat",
 49:     commandsIntro: "Comandos disponibles para los jugadores. Escríbelos en el chat del juego.",
 50:     cmdSecStats: "Puntos de atributo",
 51:     cmdSecReset: "Resets",
 52:     cmdSecChar: "Personaje e Interfaz",
 53:     cmdSecSocial: "Social",
 54:     cmdSecHelp: "Ayuda",
 55:     cmdHint: "Consejo: escribe /list en el juego para ver los comandos disponibles, o /help &lt;comando&gt; para la sintaxis.",
 56: 
 57:     cmdAddDesc: "Añade puntos al atributo seleccionado. Atributo: <b>str</b> (fuerza), <b>agi</b> (agilidad), <b>vit</b> (vitalidad), <b>ene</b> (energía), <b>cmd</b> (comando). Ej. <code>/add str 100</code>.",
 58:     cmdResetDesc: "Realiza un reset al personaje (si está disponible).",
 59:     cmdResetInfoDesc: "Muestra el costo y las recompensas del siguiente reset.",
 60:     cmdResetStatsDesc: "Restablece los atributos a sus valores base y devuelve los puntos.",
 61:     cmdMoveDesc: "Te transporta a un punto de teletransporte (ej. /move Lorencia).",
 62:     cmdClearInvDesc: "Limpia el inventario.",
 63:     cmdNpcDesc: "Abre la tienda del comerciante NPC.",
 64:     cmdOpenWareDesc: "Abre el baúl (warehouse).",
 65:     cmdOffLevelDesc: "Activa el leveleo desconectado (MU Helper).",
 66:     cmdLanguageDesc: "Cambia el idioma del cliente.",
 67:     cmdPostDesc: "Envía un mensaje azul visible para todos los jugadores.",
 68:     cmdWarDesc: "Solicita una guerra de clanes (Guild War) con otro clan.",
 69:     cmdBattleSoccerDesc: "Solicita un evento de Battle Soccer de clan.",
 70:     cmdListDesc: "Lista todos los comandos disponibles para ti.",
 71:     cmdHelpDesc: "Muestra la sintaxis y los argumentos de un comando.",
 72: 
 73:     armoryTitle: "Armería",
 74:     armorySearch: "Nombre del personaje...",
 75:     armoryBtn: "Buscar",
 76:     armoryResets: "Resets",
 77:     armoryHint: "Busca un personaje para ver su equipamiento.",
 78:     armoryNoItems: "Este personaje no tiene objetos equipados.",
 79:     ARMORY_NOT_FOUND: "Personaje no encontrado.",
 80:     RATE_LIMIT_ARMORY: "Demasiadas solicitudes. Inténtalo de nuevo más tarde.",
 81: 
 82:     eventsTitle: "Próximos Eventos",
 83:     eventsRemaining: "restantes",
 84:     eventsDuration: "Duración",
 85:     eventsMin: "min",
 86:     eventsXpMult: "Experiencia",
 87:     eventsShow: "Horarios",
 88:     eventsHide: "Ocultar",
 89:     eventsNone: "No hay eventos configurados.",
 90: 
 91:     INVALID_REQUEST: "Solicitud inválida.",
 92:     RATE_LIMIT_IP: "Límite: 1 cuenta por cada 24h por IP.",
 93:     INVALID_USERNAME: "Formato de usuario inválido (3-10 caracteres, solo letras y números).",
 94:     INVALID_PASSWORD_LENGTH: "La contraseña debe tener entre 8 y 16 caracteres.",
 95:     INVALID_SECURITY_CODE: "El código de seguridad debe tener entre 6 y 10 dígitos.",
 96:     INVALID_EMAIL: "Formato de correo electrónico inválido.",
 97:     USERNAME_TAKEN: "El nombre de usuario ya está registrado.",
 98:     PASSWORDS_DO_NOT_MATCH: "Las contraseñas no coinciden.",
 99:     REGISTRATION_SUCCESS: "¡Cuenta creada exitosamente!",
100:     RATE_LIMIT_PASSWORD: "Demasiados intentos. Inténtalo de nuevo en 15 minutos.",
101:     USER_NOT_FOUND: "El usuario no existe.",
102:     INVALID_OLD_PASSWORD: "La contraseña actual es incorrecta.",
103:     PASSWORD_CHANGE_SUCCESS: "¡Contraseña cambiada exitosamente!",
104:     RATE_LIMIT_RANKING: "Demasiadas solicitudes. Inténtalo de nuevo más tarde.",
105:     DATABASE_ERROR: "Error en la base de datos. Por favor, inténtalo de nuevo más tarde.",
106:     SERVER_ERROR: "Ocurrió un error inesperado en el servidor.",
107:     rankingNone: "No se encontraron héroes.",
108:     rankingError: "Error de conexión."
109: };
````

## File: web/wwwroot/style.css
````css
  1: /* === VARIABLES === */
  2: :root {
  3:     --primary: #d4af37;
  4:     --text: #e0e0e0;
  5: }
  6: 
  7: /* === BASE === */
  8: html {
  9:     overflow-x: hidden;   /* belt-and-suspenders: no horizontal pan/zoom on mobile */
 10: }
 11: 
 12: body {
 13:     margin: 0;
 14:     padding: 2rem 0;
 15:     min-height: 100vh;
 16:     box-sizing: border-box;
 17:     overflow-x: hidden;
 18:     max-width: 100%;
 19:     display: flex;
 20:     flex-direction: column;
 21:     justify-content: center;
 22:     align-items: center;
 23:     font-family: "Liberation Sans", Arial, sans-serif;
 24:     color: var(--text);
 25:     background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('mubg.jpg') no-repeat center center fixed;
 26:     background-size: cover;
 27:     background-color: #0a0a0a;
 28: }
 29: 
 30: .stats-body {
 31:     background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('mubg.jpg') no-repeat center center fixed;
 32:     background-size: cover;
 33: }
 34: 
 35: /* === LANGUAGE SWITCHER === */
 36: .lang-switch {
 37:     text-align: right;
 38:     font-size: 0.7rem;
 39:     margin-bottom: -10px;
 40:     font-weight: bold;
 41: }
 42: 
 43: .lang-switch span {
 44:     cursor: pointer;
 45:     color: #666;
 46:     transition: 0.3s;
 47:     padding: 0 5px;
 48: }
 49: 
 50: .lang-switch span.active {
 51:     color: var(--primary);
 52: }
 53: 
 54: /* === CONTAINER === */
 55: .container {
 56:     background: rgba(20, 20, 20, 0.7);
 57:     backdrop-filter: blur(15px);
 58:     -webkit-backdrop-filter: blur(15px);
 59:     padding: 2.5rem;
 60:     border-radius: 16px;
 61:     box-shadow: 0 20px 50px rgba(0, 0, 0, 0.8);
 62:     width: 100%;
 63:     max-width: 400px;
 64:     border: 1px solid rgba(255, 255, 255, 0.1);
 65:     border-top: 4px solid var(--primary);
 66: }
 67: 
 68: .stats-body .container {
 69:     max-width: 800px;
 70: }
 71: 
 72: /* === HEADINGS === */
 73: h2 {
 74:     text-align: center;
 75:     color: var(--primary);
 76:     margin-bottom: 2rem;
 77:     letter-spacing: 3px;
 78:     text-transform: uppercase;
 79: }
 80: 
 81: /* === FORMS === */
 82: .form-group {
 83:     margin-bottom: 1.2rem;
 84: }
 85: 
 86: label {
 87:     display: block;
 88:     margin-bottom: 0.5rem;
 89:     font-size: 0.75rem;
 90:     color: #aaa;
 91:     text-transform: uppercase;
 92: }
 93: 
 94: input {
 95:     width: 100%;
 96:     padding: 12px;
 97:     box-sizing: border-box;
 98:     background: rgba(0, 0, 0, 0.5);
 99:     border: 1px solid rgba(255, 255, 255, 0.1);
100:     color: white;
101:     border-radius: 6px;
102:     transition: 0.3s;
103: }
104: 
105: input:focus {
106:     outline: none;
107:     border-color: var(--primary);
108:     background: rgba(0, 0, 0, 0.7);
109: }
110: 
111: /* === BUTTONS === */
112: button {
113:     width: 100%;
114:     padding: 14px;
115:     background: linear-gradient(135deg, #d4af37 0%, #a68a2d 100%);
116:     border: none;
117:     color: #000;
118:     font-weight: bold;
119:     cursor: pointer;
120:     border-radius: 6px;
121:     text-transform: uppercase;
122:     transition: 0.3s;
123:     margin-top: 1rem;
124: }
125: 
126: button:hover {
127:     filter: brightness(1.1);
128:     transform: translateY(-2px);
129:     box-shadow: 0 5px 15px rgba(212, 175, 55, 0.3);
130: }
131: 
132: /* === MESSAGES === */
133: #message {
134:     margin-top: 1.5rem;
135:     padding: 12px;
136:     border-radius: 6px;
137:     text-align: center;
138:     display: none;
139:     font-size: 0.9rem;
140:     backdrop-filter: blur(5px);
141: }
142: 
143: .success {
144:     background: rgba(39, 174, 96, 0.2);
145:     color: #2ecc71;
146:     border: 1px solid #2ecc71;
147: }
148: 
149: .error {
150:     background: rgba(192, 57, 43, 0.2);
151:     color: #e74c3c;
152:     border: 1px solid #e74c3c;
153: }
154: 
155: /* === WARNING BOX === */
156: .warning-box {
157:     background: rgba(212, 175, 55, 0.1);
158:     border-left: 3px solid var(--primary);
159:     padding: 10px;
160:     font-size: 0.75rem;
161:     margin-top: 10px;
162:     color: #d4af37;
163: }
164: 
165: /* === LOADER SPINNER === */
166: .spinner-loader {
167:     display: none;
168:     width: 20px;
169:     height: 20px;
170:     border: 3px solid rgba(0, 0, 0, 0.1);
171:     border-radius: 50%;
172:     border-top: 3px solid #000;
173:     animation: spin 1s linear infinite;
174:     margin: 0 auto;
175: }
176: 
177: @keyframes spin {
178:     0% { transform: rotate(0deg); }
179:     100% { transform: rotate(360deg); }
180: }
181: 
182: /* === FOOTER NAV === */
183: .footer-nav {
184:     margin-top: 2.5rem;
185:     padding-top: 2rem;
186:     border-top: 1px solid rgba(255, 255, 255, 0.1);
187:     display: flex;
188:     flex-wrap: wrap;
189:     justify-content: center;
190:     gap: 15px;
191: }
192: 
193: .nav-link {
194:     text-decoration: none;
195:     font-size: 0.85rem;
196:     font-weight: 600;
197:     text-transform: uppercase;
198:     letter-spacing: 1px;
199:     padding: 10px 20px;
200:     border-radius: 8px;
201:     color: var(--text);
202:     background: rgba(255, 255, 255, 0.05);
203:     border: 1px solid rgba(255, 255, 255, 0.1);
204:     transition: all 0.3s ease;
205:     display: inline-flex;
206:     align-items: center;
207: }
208: 
209: .nav-link:hover {
210:     background: rgba(212, 175, 55, 0.1);
211:     border-color: var(--primary);
212:     color: var(--primary);
213:     transform: translateY(-2px);
214:     box-shadow: 0 5px 15px rgba(212, 175, 55, 0.2);
215: }
216: 
217: .nav-link:active {
218:     transform: translateY(0);
219: }
220: 
221: /* === CREDITS === */
222: .credits {
223:     margin-top: 1.5rem;
224:     margin-bottom: 1rem;
225:     width: 100%;
226:     text-align: center;
227:     font-size: 0.7rem;
228:     letter-spacing: 1px;
229:     text-transform: uppercase;
230: }
231: 
232: .credits a {
233:     text-decoration: none;
234:     color: rgba(255, 255, 255, 0.3);
235:     transition: all 0.4s ease;
236:     font-weight: 400;
237: }
238: 
239: .credits a span {
240:     font-weight: 300;
241: }
242: 
243: .credits a:hover {
244:     color: var(--primary);
245:     opacity: 1;
246:     text-shadow: 0 0 8px rgba(212, 175, 55, 0.4);
247: }
248: 
249: /* === RANKING TABLE === */
250: table {
251:     width: 100%;
252:     border-collapse: collapse;
253:     margin-top: 10px;
254: }
255: 
256: th {
257:     text-align: left;
258:     color: var(--primary);
259:     text-transform: uppercase;
260:     font-size: 0.75rem;
261:     padding: 15px;
262:     border-bottom: 1px solid rgba(255, 255, 255, 0.1);
263: }
264: 
265: td {
266:     padding: 15px;
267:     font-size: 0.95rem;
268:     border-bottom: 1px solid rgba(255, 255, 255, 0.05);
269: }
270: 
271: .master-level {
272:     text-align: center;
273: }
274: 
275: td.master-level {
276:     color: #8b0000;
277:     font-weight: bold;
278: }
279: 
280: tr:hover {
281:     background: rgba(255, 255, 255, 0.03);
282: }
283: 
284: .char-name {
285:     font-weight: bold;
286:     color: #fff;
287: }
288: 
289: .rank-number {
290:     color: var(--primary);
291:     font-weight: bold;
292:     width: 30px;
293: }
294: 
295: .reset-badge {
296:     background: rgba(212, 175, 55, 0.15);
297:     color: var(--primary);
298:     border: 1px solid rgba(212, 175, 55, 0.4);
299:     padding: 2px 8px;
300:     border-radius: 4px;
301:     font-size: 0.75rem;
302:     font-weight: bold;
303:     margin-left: 10px;
304:     display: inline-block;
305:     vertical-align: middle;
306:     text-transform: uppercase;
307:     letter-spacing: 0.5px;
308: }
309: 
310: tr:nth-child(1) .char-name {
311:     color: #ffd700;
312:     text-shadow: 0 0 10px rgba(255, 215, 0, 0.5);
313: }
314: 
315: /* characters who reached the server reset cap (muConfig.maxResets) get a glowing
316:    reset badge — rank #1 is marked separately by its gold character name */
317: .reset-badge.max-reset {
318:     background: rgba(255, 215, 0, 0.25);
319:     border-color: #ffd700;
320:     color: #ffd700;
321:     box-shadow: 0 0 8px rgba(255, 215, 0, 0.45);
322: }
323: 
324: .table-loader {
325:     text-align: center;
326:     padding: 20px;
327:     color: var(--primary);
328: }
329: 
330: /* === SERVER STATUS === */
331: .server-status {
332:     display: flex;
333:     align-items: center;
334:     justify-content: center;
335:     gap: 8px;
336:     margin-top: -10px;
337:     margin-bottom: 20px;
338:     font-size: 0.85rem;
339:     color: #aaa;
340: }
341: 
342: .status-dot {
343:     width: 14px;
344:     height: 14px;
345:     border-radius: 50%;
346:     background: #666;
347:     display: inline-block;
348:     flex-shrink: 0;
349:     transition: background 0.3s;
350: }
351: 
352: #statusText {
353:     line-height: 1;
354: }
355: 
356: .status-dot.online {
357:     background: #2ecc71;
358:     box-shadow: 0 0 8px rgba(46, 204, 113, 0.6);
359:     animation: pulse 2s infinite;
360: }
361: 
362: .status-dot.offline {
363:     background: #e74c3c;
364:     box-shadow: 0 0 8px rgba(231, 76, 60, 0.6);
365: }
366: 
367: @keyframes pulse {
368:     0%, 100% { opacity: 1; }
369:     50% { opacity: 0.5; }
370: }
371: 
372: /* === ARMORY === */
373: .armory-body {
374:     background: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url('mubg.jpg') no-repeat center center fixed;
375:     background-size: cover;
376: }
377: 
378: .armory-body .container {
379:     max-width: 860px;
380: }
381: 
382: .armory-search {
383:     display: flex;
384:     align-items: center;
385:     gap: 10px;
386:     justify-content: center;
387:     margin-bottom: 1.8rem;
388: }
389: 
390: .armory-search input {
391:     flex: 1 1 auto;
392:     width: auto;          /* override global "input { width: 100% }" */
393:     min-width: 0;         /* allow the flex item to shrink properly */
394:     max-width: 300px;
395:     padding: 0.7rem 1rem;
396:     box-sizing: border-box;
397:     border-radius: 8px;
398:     border: 1px solid rgba(255, 255, 255, 0.15);
399:     background: rgba(0, 0, 0, 0.35);
400:     color: var(--text);
401:     font-size: 1rem;
402: }
403: 
404: .armory-search input:focus {
405:     outline: none;
406:     border-color: var(--primary);
407: }
408: 
409: .armory-search button {
410:     flex: 0 0 auto;       /* keep the button at its content size */
411:     width: auto;          /* override global "button { width: 100% }" */
412:     margin-top: 0;        /* override global "button { margin-top: 1rem }" */
413:     padding: 0.7rem 1.4rem;
414:     border: none;
415:     border-radius: 8px;
416:     background: var(--primary);
417:     color: #1a1a1a;
418:     font-weight: bold;
419:     text-transform: uppercase;
420:     letter-spacing: 1px;
421:     white-space: nowrap;
422:     cursor: pointer;
423:     transition: filter 0.2s;
424: }
425: 
426: .armory-search button:hover {
427:     filter: brightness(1.1);
428: }
429: 
430: .armory-content {
431:     display: flex;
432:     gap: 1.5rem;
433:     align-items: flex-start;
434: }
435: 
436: /* Left: character panel */
437: .armory-char {
438:     flex: 0 0 240px;
439:     background: rgba(0, 0, 0, 0.3);
440:     border: 1px solid rgba(255, 255, 255, 0.1);
441:     border-radius: 12px;
442:     padding: 1rem;
443:     text-align: center;
444: }
445: 
446: .armory-char-image {
447:     width: 100%;
448:     max-width: 200px;
449:     height: auto;
450:     opacity: 0.9;
451: }
452: 
453: .armory-char-name {
454:     color: var(--primary);
455:     font-size: 1.3rem;
456:     font-weight: bold;
457:     margin-top: 0.5rem;
458: }
459: 
460: .armory-char-class {
461:     color: #aaa;
462:     font-style: italic;
463:     font-size: 0.9rem;
464:     margin-bottom: 0.8rem;
465: }
466: 
467: .armory-char-stats {
468:     display: flex;
469:     flex-direction: column;
470:     gap: 4px;
471:     font-size: 0.9rem;
472:     color: var(--text);
473: }
474: 
475: .armory-char-stats b {
476:     color: #fff;
477: }
478: 
479: /* Right: equipment paper doll */
480: .armory-equip {
481:     flex: 1;
482:     min-height: 360px;
483:     display: flex;
484:     align-items: center;
485:     justify-content: center;
486: }
487: 
488: .armory-doll {
489:     display: grid;
490:     grid-template-columns: repeat(3, 1fr);
491:     grid-template-rows: repeat(4, 1fr);
492:     gap: 12px;
493:     width: 100%;
494: }
495: 
496: .armory-slot {
497:     position: relative;
498:     aspect-ratio: 1 / 1;
499:     border: 1px solid rgba(255, 255, 255, 0.12);
500:     border-radius: 8px;
501:     background: rgba(0, 0, 0, 0.35);
502:     display: flex;
503:     align-items: center;
504:     justify-content: center;
505:     overflow: hidden;
506: }
507: 
508: .armory-slot.filled {
509:     border-color: rgba(212, 175, 55, 0.4);
510:     background: rgba(212, 175, 55, 0.08);
511:     cursor: help;
512: }
513: 
514: .armory-slot img {
515:     max-width: 86%;
516:     max-height: 86%;
517:     object-fit: contain;
518:     image-rendering: pixelated;
519: }
520: 
521: .armory-slot img.img-missing {
522:     visibility: hidden;
523: }
524: 
525: .armory-slot .slot-label {
526:     color: #555;
527:     font-size: 0.7rem;
528:     text-transform: uppercase;
529:     letter-spacing: 1px;
530: }
531: 
532: .armory-slot .badge {
533:     position: absolute;
534:     font-size: 0.6rem;
535:     font-weight: bold;
536:     padding: 1px 4px;
537:     border-radius: 4px;
538:     line-height: 1.2;
539: }
540: 
541: .armory-slot .badge.exc { top: 3px; left: 3px; background: rgba(46, 204, 113, 0.85); color: #07210f; }
542: .armory-slot .badge.anc { top: 3px; right: 3px; background: rgba(255, 215, 0, 0.9); color: #2a2100; }
543: .armory-slot .badge.sock { bottom: 3px; right: 3px; background: rgba(155, 89, 182, 0.9); color: #fff; }
544: 
545: .armory-message {
546:     text-align: center;
547:     color: #aaa;
548:     padding: 1rem;
549: }
550: 
551: .armory-message.error {
552:     color: #e74c3c;
553: }
554: 
555: /* Themed item tooltip */
556: .item-tooltip {
557:     display: none;
558:     position: fixed;
559:     z-index: 1000;
560:     pointer-events: none;
561:     max-width: 320px;
562:     padding: 10px 13px;
563:     background: rgba(15, 15, 15, 0.95);
564:     border: 1px solid rgba(212, 175, 55, 0.45);
565:     border-top: 3px solid var(--primary);
566:     border-radius: 8px;
567:     box-shadow: 0 12px 32px rgba(0, 0, 0, 0.75);
568:     backdrop-filter: blur(8px);
569:     -webkit-backdrop-filter: blur(8px);
570:     font-size: 0.8rem;
571:     line-height: 1.55;
572:     color: #cfcfcf;
573: }
574: 
575: .item-tooltip .tip-head {
576:     color: var(--primary);
577:     font-weight: bold;
578:     letter-spacing: 0.5px;
579:     margin-bottom: 5px;
580:     padding-bottom: 5px;
581:     border-bottom: 1px solid rgba(255, 255, 255, 0.1);
582: }
583: 
584: .item-tooltip .tip-line.opt { color: #4aa3ff; }   /* normal options & luck - blue */
585: .item-tooltip .tip-line.exc { color: #2ecc71; }   /* excellent options - green */
586: .item-tooltip .tip-line.skill { color: #ffffff; } /* skill - white */
587: .item-tooltip .tip-line.sock { color: #b18bd8; }  /* sockets - purple */
588: 
589: /* armory paper-doll stacks earlier (640px) than the global phone breakpoint */
590: @media (max-width: 640px) {
591:     .armory-content {
592:         flex-direction: column;
593:     }
594:     .armory-char {
595:         flex: none;
596:         width: 100%;
597:         box-sizing: border-box;
598:     }
599: }
600: 
601: /* === MOBILE (phones) === */
602: @media (max-width: 480px) {
603:     body {
604:         padding: 1rem 0.75rem;   /* horizontal breathing room, stop edge-clipping */
605:     }
606: 
607:     .container {
608:         padding: 1.5rem;         /* tighter than the 2.5rem desktop padding */
609:     }
610: 
611:     h2 {
612:         font-size: 1.3rem;
613:         letter-spacing: 1px;
614:         margin-bottom: 1.5rem;
615:         word-break: break-word;
616:     }
617: 
618:     .footer-nav {
619:         gap: 10px;
620:         margin-top: 1.8rem;
621:         padding-top: 1.5rem;
622:     }
623: 
624:     .nav-link {
625:         padding: 8px 14px;
626:         font-size: 0.78rem;
627:     }
628: 
629:     /* ranking table: fit 5 columns on a narrow screen */
630:     th,
631:     td {
632:         padding: 8px 6px;
633:         font-size: 0.82rem;
634:     }
635: 
636:     .reset-badge {
637:         margin-left: 6px;
638:         padding: 1px 5px;
639:         font-size: 0.65rem;
640:     }
641: }
````

## File: web/Dockerfile
````dockerfile
 1: FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
 2: WORKDIR /src
 3: 
 4: COPY ["OpenMU_Web.csproj", "./"]
 5: RUN dotnet restore "OpenMU_Web.csproj"
 6: 
 7: COPY . .
 8: RUN dotnet publish "OpenMU_Web.csproj" -c Release -o /app/publish
 9: 
10: FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
11: WORKDIR /app
12: 
13: # tzdata so the TZ env var resolves real zones (e.g. Europe/Warsaw); icu-libs for
14: # full globalization, matching the previous Ubuntu image's behaviour.
15: RUN apk add --no-cache tzdata icu-libs
16: ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
17: 
18: COPY --from=build /app/publish .
19: 
20: USER app
21: 
22: EXPOSE 8080
23: ENV ASPNETCORE_URLS=http://+:8080
24: 
25: HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
26:   CMD wget -q --spider http://127.0.0.1:8080/ || exit 1
27: 
28: ENTRYPOINT ["dotnet", "OpenMU_Web.dll"]
````

## File: web/OpenMU_Web.csproj
````
 1: <Project Sdk="Microsoft.NET.Sdk.Web">
 2:   <PropertyGroup>
 3:     <TargetFramework>net8.0</TargetFramework>
 4:     <Nullable>enable</Nullable>
 5:     <ImplicitUsings>enable</ImplicitUsings>
 6:   </PropertyGroup>
 7: 
 8:   <ItemGroup>
 9:   <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
10:   <PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
11: </ItemGroup>
12: </Project>
````

## File: web/Program.cs
````csharp
  1: using Microsoft.EntityFrameworkCore;
  2: using System.Collections.Concurrent;
  3: using OpenMU_Web.Data;
  4: using OpenMU_Web.Endpoints;
  5: using OpenMU_Web.Services;
  6: using System.Text.Json;
  7: 
  8: var builder = WebApplication.CreateBuilder(args);
  9: var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
 10: 
 11: // --- SERVICES ---
 12: builder.Services.AddRazorPages();
 13: builder.Services.AddDbContext<OpenMuContext>(options => options.UseNpgsql(connectionString));
 14: builder.Services.AddCors(options =>
 15: {
 16:     options.AddPolicy("AllowAll", p => p
 17:         .AllowAnyOrigin()
 18:         .AllowAnyMethod()
 19:         .AllowAnyHeader());
 20: });
 21: 
 22: // Rate limiting stores
 23: builder.Services.AddSingleton<ConcurrentDictionary<string, DateTime>>(_ => new ConcurrentDictionary<string, DateTime>());
 24: builder.Services.AddKeyedSingleton<RateLimiter>("password");
 25: builder.Services.AddKeyedSingleton<RateLimiter>("ranking");
 26: builder.Services.AddKeyedSingleton<RateLimiter>("events");
 27: builder.Services.AddKeyedSingleton<RateLimiter>("armory");
 28: builder.Services.AddHttpClient();
 29: 
 30: var app = builder.Build();
 31: 
 32: app.UseCors("AllowAll");
 33: 
 34: // Friendly URLs are now owned by Razor Pages (Pages/*.cshtml, routed via @@page "/route");
 35: // no URL rewriting needed. Static assets (css/js/img/translations) are served from wwwroot.
 36: app.UseStaticFiles();
 37: 
 38: // Periodic cleanup of expired rate limiter entries (every 10 minutes)
 39: var cleanupTimer = new PeriodicTimer(TimeSpan.FromMinutes(10));
 40: _ = Task.Run(async () =>
 41: {
 42:     while (await cleanupTimer.WaitForNextTickAsync())
 43:     {
 44:         var now = DateTime.UtcNow;
 45:         var ipLimit = app.Services.GetRequiredService<ConcurrentDictionary<string, DateTime>>();
 46:         var passwordLimiter = app.Services.GetRequiredKeyedService<RateLimiter>("password");
 47:         var rankingLimiter = app.Services.GetRequiredKeyedService<RateLimiter>("ranking");
 48:         var eventsLimiter = app.Services.GetRequiredKeyedService<RateLimiter>("events");
 49:         var armoryLimiter = app.Services.GetRequiredKeyedService<RateLimiter>("armory");
 50: 
 51:         foreach (var key in ipLimit.Keys)
 52:             if (ipLimit[key] < now.AddDays(-1)) ipLimit.TryRemove(key, out _);
 53: 
 54:         passwordLimiter.Cleanup(now, TimeSpan.FromMinutes(15));
 55:         rankingLimiter.Cleanup(now, TimeSpan.FromMinutes(1));
 56:         eventsLimiter.Cleanup(now, TimeSpan.FromMinutes(1));
 57:         armoryLimiter.Cleanup(now, TimeSpan.FromMinutes(1));
 58:     }
 59: });
 60: 
 61: // --- 2. ENDPOINTS ---
 62: app.MapRazorPages();
 63: app.MapRegistrationEndpoints();
 64: app.MapPasswordEndpoints();
 65: app.MapRankingEndpoints();
 66: app.MapEventsEndpoints();
 67: app.MapArmoryEndpoints();
 68: 
 69: var serverCheckConfig = builder.Configuration.GetSection("ServerCheck");
 70: var serverHost = serverCheckConfig["Host"] ?? "openmu-server";
 71: var serverPort = int.Parse(serverCheckConfig["Port"] ?? "44406");
 72: 
 73: app.MapGet("/api/public/server-status", async () =>
 74: {
 75:     try
 76:     {
 77:         using var tcp = new System.Net.Sockets.TcpClient();
 78:         await tcp.ConnectAsync(serverHost, serverPort).WaitAsync(TimeSpan.FromSeconds(2));
 79:         return Results.Json(new { online = true });
 80:     }
 81:     catch
 82:     {
 83:         return Results.Json(new { online = false });
 84:     }
 85: });
 86: 
 87: app.MapGet("/api/public/online-players", async (ILogger<Program> logger, IHttpClientFactory httpClientFactory) =>
 88: {
 89:     try
 90:     {
 91:         using var http = httpClientFactory.CreateClient();
 92:         http.Timeout = TimeSpan.FromSeconds(3);
 93:         var response = await http.GetStringAsync($"http://{serverHost}:8080/api/status");
 94:         using var doc = JsonDocument.Parse(response);
 95:         var players = doc.RootElement.GetProperty("players").GetInt32();
 96:         return Results.Json(new { playerCount = players });
 97:     }
 98:     catch (Exception ex)
 99:     {
100:         logger.LogDebug(ex, "Failed to fetch player count");
101:         return Results.Json(new { playerCount = (int?)null });
102:     }
103: });
104: 
105: app.Run();
````

## File: .env.example
````
 1: # Red Config
 2: RESOLVE_IP=
 3: 
 4: # Admin Panel Config
 5: ADMIN_PANEL_PORT=
 6: OPENMU_ADMIN_USER=
 7: OPENMU_ADMIN_PASSWORD=
 8: OPENMU_ADMIN_TOTP_SECRET=
 9: OPENMU_DATA_PATH=
10: 
11: # Postgres Config
12: OPENMU_DB_PATH=
13: POSTGRES_PASSWORD=
14: POSTGRES_USER=
15: POSTGRES_DB=
16: 
17: # Backup Config (Postgres)
18: OPENMU_BACKUP_PATH=
19: BACKUP_CRON_SCHEDULE="0 3 * * *"   # Cada 24 horas a las 03:00 AM (sintaxis cron: minuto hora día mes día_semana)
20: BACKUP_RETENTION_DAYS=7            # Retener backups de los últimos N días
21: BACKUP_RUN_ON_STARTUP=true         # Realizar un backup al arrancar el contenedor
22: 
23: # Web Config
24: WEB_PORT=
25: DB_HOST=
26: TIMEZ=
27: 
28: # Client Config (OpenMu-Client-Babylon)
29: CLIENT_VITE_PORT=4173   # Puerto del cliente web (vite preview) → http://localhost:4173/online
30: CLIENT_PROXY_PORT=3000  # Puerto del bridge WS↔TCP
31: VITE_SERVER_LIST_URL=
````

## File: .gitignore
````
1: .env
2: bin/
3: obj/
4: web/bin/
5: web/obj/
6: ./node_modules
````

## File: web/wwwroot/js/index.js
````javascript
 1: // lang.js fills in the data-i18n text and renders the language buttons; this hook adds
 2: // the index-only content (welcome text + rates table) from content.js on each switch.
 3: window.onLanguageChanged = function (lang) {
 4:     const c = window.muContent[lang];
 5: 
 6:     document.getElementById('welcomeTitle').innerText = c.welcomeTitle;
 7:     document.getElementById('welcomeText').innerText = c.welcomeText;
 8:     renderDownloads();
 9: 
10:     const list = document.getElementById('detailsList');
11:     list.innerHTML = c.rows.map(row =>
12:         '<div class="details-row">' + row.map(d =>
13:             d.url
14:                 ? `<li><span class="detail-label">${d.label}:</span> <a href="${d.url}" target="_blank">${d.value}</a></li>`
15:                 : `<li><span class="detail-label">${d.label}:</span> ${d.value}</li>`
16:         ).join('') + '</div>'
17:     ).join('');
18: };
19: 
20: async function checkServerStatus() {
21:     const dot = document.getElementById('indexStatusDot');
22:     const text = document.getElementById('indexStatusText');
23:     const t = window.t();
24: 
25:     try {
26:         const res = await fetch('/api/public/server-status');
27:         const data = await res.json();
28:         if (data.online) {
29:             dot.className = 'status-dot-box online';
30:             text.className = 'status-value online';
31:             text.innerText = t.online || 'Online';
32:         } else {
33:             dot.className = 'status-dot-box offline';
34:             text.className = 'status-value offline';
35:             text.innerText = t.offline || 'Offline';
36:         }
37:     } catch {
38:         dot.className = 'status-dot-box offline';
39:         text.className = 'status-value offline';
40:         text.innerText = t.offline || 'Offline';
41:     }
42: }
43: 
44: async function checkOnlinePlayers() {
45:     const text = document.getElementById('indexPlayersText');
46: 
47:     try {
48:         const res = await fetch('/api/public/online-players');
49:         const data = await res.json();
50:         text.innerText = data.playerCount !== null ? data.playerCount : '---';
51:     } catch {
52:         text.innerText = '---';
53:     }
54: }
55: 
56: // Download dropdown: a single "Download" button that reveals the targets from
57: // muConfig.downloads. The recommended one (Launcher) is highlighted; nothing
58: // downloads on its own — every entry is an explicit pick. Re-rendered on each
59: // language change so the generic labels translate.
60: function renderDownloads() {
61:     const area = document.getElementById('downloadArea');
62:     if (!area) return;
63:     const t = window.t();
64:     const launcherUrl = window.muConfig && window.muConfig.launcherUrl;
65:     const items = (window.muConfig.downloads || []).map(d => {
66:         const isLauncher = d.id === 'launcher';
67:         const url = (isLauncher && launcherUrl) ? launcherUrl : d.url;
68:         const cls = d.recommended ? 'recommended' : (d.soon ? 'soon' : '');
69:         const tag = d.recommended ? `<span class="dlC-tag">${t.dlRecommended}</span>`
70:             : (d.soon ? `<span class="dlC-tag">${t.dlSoon}</span>` : '');
71:         const targetAttr = (!d.soon && (isLauncher || d.target === '_blank')) ? ' target="_blank" rel="noopener noreferrer"' : '';
72:         return `<a class="dlC-item ${cls}" href="${d.soon ? '#' : url}"${targetAttr}><span>${d.icon}</span> <span>${d.name}</span> ${tag}</a>`;
73:     }).join('');
74: 
75:     area.innerHTML = `
76:         <div class="dlC-wrap" id="dlCWrap">
77:             <div class="dlC-trigger dl-gold" id="dlCTrigger">
78:                 <span>⬇ ${t.dlDownload}</span><span class="dlC-caret">▼</span>
79:             </div>
80:             <div class="dlC-menu">${items}</div>
81:         </div>`;
82: 
83:     document.getElementById('dlCTrigger').addEventListener('click', e => {
84:         e.stopPropagation();
85:         document.getElementById('dlCWrap').classList.toggle('open');
86:     });
87: }
88: 
89: // Attach the outside-click close once (not per render, to avoid stacking listeners).
90: document.addEventListener('click', () => {
91:     const wrap = document.getElementById('dlCWrap');
92:     if (wrap) wrap.classList.remove('open');
93: });
94: 
95: checkServerStatus();
96: checkOnlinePlayers();
97: setInterval(checkServerStatus, 30000);
98: setInterval(checkOnlinePlayers, 30000);
````

## File: web/wwwroot/lang.js
````javascript
 1: // Shared language switcher for every page.
 2: //
 3: // Translations stay in SEPARATE per-language files (en.js, es.js, de.js, …); each one adds
 4: // its own object to window.muTranslations. To add a language: copy en.js to <code>.js,
 5: // translate the values, and include it with <script src="<code>.js"> on the pages — the
 6: // switch button for it then appears automatically (no per-page button editing).
 7: //
 8: // Mark elements with data-i18n="key" (text/HTML) or data-i18n-placeholder="key". Pages that
 9: // render extra language-dependent content expose a window.onLanguageChanged(lang) hook; it is
10: // called after every language change, including the initial one.
11: (function () {
12:     // Optional pretty labels; languages without an entry fall back to the uppercased code.
13:     const LABELS = { en: 'EN', es: 'ES' };
14: 
15:     // Default language for first-time visitors, taken from <script src="lang.js" data-default="es">.
16:     // Without the attribute the first included language wins (en.js is included first → English).
17:     const scriptDefault = document.currentScript ? document.currentScript.dataset.default : null;
18: 
19:     function languages() {
20:         // Order follows the <script> include order of the language files.
21:         return Object.keys(window.muTranslations || {});
22:     }
23: 
24:     function currentLang() {
25:         const saved = localStorage.getItem('preferred-lang');
26:         const available = languages();
27:         if (saved && available.includes(saved)) return saved;
28:         if (scriptDefault && available.includes(scriptDefault)) return scriptDefault;
29:         return available[0] || 'es';
30:     }
31: 
32:     function applyTranslations(lang) {
33:         const t = window.muTranslations[lang];
34:         // innerHTML (not innerText) so values containing markup/entities — e.g. the
35:         // "&lt;command&gt;" hint — render correctly. Translation values are trusted, static.
36:         document.querySelectorAll('[data-i18n]').forEach(el => {
37:             const value = t[el.getAttribute('data-i18n')];
38:             if (value != null) el.innerHTML = value;
39:         });
40:         document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
41:             const value = t[el.getAttribute('data-i18n-placeholder')];
42:             if (value != null) el.placeholder = value;
43:         });
44:     }
45: 
46:     function renderSwitch(lang) {
47:         const box = document.getElementById('lang-switch');
48:         if (!box) return;
49:         box.innerHTML = languages().map(code =>
50:             `<span data-lang="${code}"${code === lang ? ' class="active"' : ''}>${LABELS[code] || code.toUpperCase()}</span>`
51:         ).join(' | ');
52:         box.querySelectorAll('[data-lang]').forEach(el =>
53:             el.addEventListener('click', () => setLanguage(el.getAttribute('data-lang'))));
54:     }
55: 
56:     function setLanguage(lang) {
57:         if (!window.muTranslations || !window.muTranslations[lang]) return;
58:         localStorage.setItem('preferred-lang', lang);
59:         applyTranslations(lang);
60:         renderSwitch(lang);
61:         if (typeof window.onLanguageChanged === 'function') window.onLanguageChanged(lang);
62:     }
63: 
64:     // Exposed globally: page scripts use these; the buttons are wired up in renderSwitch.
65:     window.setLanguage = setLanguage;
66:     window.currentLang = currentLang;
67:     window.t = () => window.muTranslations[currentLang()];
68: 
69:     // Apply the saved/default language once the DOM (and any onLanguageChanged hook) is ready.
70:     if (document.readyState === 'loading') {
71:         document.addEventListener('DOMContentLoaded', () => setLanguage(currentLang()));
72:     } else {
73:         setLanguage(currentLang());
74:     }
75: })();
````

## File: web/wwwroot/template_lang.js
````javascript
  1: // Skeleton for adding a new interface language. To add e.g. German:
  2: //   1. Copy this file to de.js (or just copy the already-translated en.js).
  3: //   2. Rename the "xx" key below to your language code (e.g. .de).
  4: //   3. Fill in every value with the translation.
  5: //   4. Add <script src="de.js"></script> next to en.js / es.js on every page.
  6: // The switch button (label = the uppercased code, e.g. "DE") then appears automatically;
  7: // to give it a nicer label, add an entry to the LABELS map in lang.js.
  8: window.muTranslations = window.muTranslations || {};
  9: window.muTranslations.xx = {
 10:     title: "",
 11:     titleChange: "",
 12:     rankingTitle: "",
 13: 
 14:     login: "",
 15:     email: "",
 16:     pass: "",
 17:     confirmPass: "",
 18:     oldPass: "",
 19:     newPass: "",
 20:     pin: "",
 21:     pinWarn: "",
 22: 
 23:     btnReg: "",
 24:     btnChange: "",
 25: 
 26:     placeholderLogin: "",
 27:     placeholderEmail: "",
 28:     placeholderPass: "",
 29:     placeholderConfirmPass: "",
 30:     placeholderPin: "",
 31: 
 32:     connError: "",
 33:     processing: "",
 34:     srvStatus: "",
 35:     playersOnline: "",
 36:     dlDownload: "",
 37:     dlRecommended: "",
 38:     dlSoon: "",
 39:     online: "",
 40:     offline: "",
 41: 
 42:     charName: "",
 43:     charClass: "",
 44:     charLvl: "",
 45:     charMl: "",
 46: 
 47:     navStats: "",
 48:     navEvents: "",
 49:     navHome: "",
 50:     navChangePass: "",
 51:     navRegister: "",
 52:     navArmory: "",
 53:     navCommands: "",
 54: 
 55:     commandsTitle: "",
 56:     commandsIntro: "",
 57:     cmdSecStats: "",
 58:     cmdSecReset: "",
 59:     cmdSecChar: "",
 60:     cmdSecSocial: "",
 61:     cmdSecHelp: "",
 62:     cmdHint: "",
 63: 
 64:     cmdAddDesc: "",
 65:     cmdResetDesc: "",
 66:     cmdResetInfoDesc: "",
 67:     cmdResetStatsDesc: "",
 68:     cmdMoveDesc: "",
 69:     cmdClearInvDesc: "",
 70:     cmdNpcDesc: "",
 71:     cmdOpenWareDesc: "",
 72:     cmdOffLevelDesc: "",
 73:     cmdLanguageDesc: "",
 74:     cmdPostDesc: "",
 75:     cmdWarDesc: "",
 76:     cmdBattleSoccerDesc: "",
 77:     cmdListDesc: "",
 78:     cmdHelpDesc: "",
 79: 
 80:     armoryTitle: "",
 81:     armorySearch: "",
 82:     armoryBtn: "",
 83:     armoryResets: "",
 84:     armoryHint: "",
 85:     armoryNoItems: "",
 86:     ARMORY_NOT_FOUND: "",
 87:     RATE_LIMIT_ARMORY: "",
 88: 
 89:     eventsTitle: "",
 90:     eventsRemaining: "",
 91:     eventsDuration: "",
 92:     eventsMin: "",
 93:     eventsXpMult: "",
 94:     eventsShow: "",
 95:     eventsHide: "",
 96:     eventsNone: "",
 97: 
 98:     INVALID_REQUEST: "",
 99:     RATE_LIMIT_IP: "",
100:     INVALID_USERNAME: "",
101:     INVALID_PASSWORD_LENGTH: "",
102:     INVALID_SECURITY_CODE: "",
103:     INVALID_EMAIL: "",
104:     USERNAME_TAKEN: "",
105:     PASSWORDS_DO_NOT_MATCH: "",
106:     REGISTRATION_SUCCESS: "",
107:     RATE_LIMIT_PASSWORD: "",
108:     USER_NOT_FOUND: "",
109:     INVALID_OLD_PASSWORD: "",
110:     PASSWORD_CHANGE_SUCCESS: "",
111:     RATE_LIMIT_RANKING: "",
112:     DATABASE_ERROR: "",
113:     SERVER_ERROR: "",
114:     rankingNone: "",
115:     rankingError: ""
116: };
````

## File: web/README.md
````markdown
 1: # openmu-simple-web
 2: This is simple website for OpenMU. 
 3: 
 4: Website has been created for mine OpenMU server builder: https://github.com/nolt/openmu-docker  
 5: It connects to same docker network where database is.
 6: 
 7: Website is multilanguage English and Spanish.
 8: 
 9: ## Website allows:
10: - register new account
11: - change password
12: - server status
13: - server TOP 10
14: - event status info (BC/DS/CC etc.)
15: - armory (character equipment viewer)
16: - chat commands reference
17: 
18: ## Requirements
19: - Docker
20: - Docker Compose
21: 
22: ## Building
23: - clone this repository
24: - replace values in .env to your own
25: - build
26: 
27: Build your service:
28: 
29: ```docker compose up -d --build```
30: 
31: ## Adding a new language
32: 
33: The pages share a single Razor layout (`Pages/Shared/_Layout.cshtml`), so adding a language
34: means editing **one config list** — no per-page changes.
35: 
36: 1. **Create a translation file**
37:    - Copy `wwwroot/template_lang.js` (an empty skeleton with every key) — or the
38:      already-translated `wwwroot/en.js` — to your language code, e.g. `de.js` for German.
39:    - Change the object key on line 2 (`window.muTranslations.xx`) to your code, e.g. `.de`.
40:    - Fill in every value with your translation.
41: 
42: 2. **Register it in the site config**
43:    Add the code to the `Site:Languages` array in `appsettings.json` — the single place the
44:    language list lives. The shared layout emits the `<script>` tag for every listed language
45:    on every page automatically:
46:    ```json
47:    "Site": {
48:      "Languages": [ "es", "en", "de" ],
49:      "DefaultLanguage": "es"
50:    }
51:    ```
52: 
53: 3. **Update content.js (optional)**
54:    The homepage rates and welcome text come from `window.muContent` in `wwwroot/content.js`.
55:    Add your language section there, following the same pattern as `en` and `es`.
56: 
57: 4. **Done**
58:    `lang.js` builds the switch buttons automatically from every language found in
59:    `window.muTranslations` — no per-page button editing. The button label is the uppercased
60:    code (e.g. `DE`); for a nicer label add an entry to the `LABELS` map in `wwwroot/lang.js`.
61: 
62: To start the site in another language by default, set `Site:DefaultLanguage` (e.g. `"de"`) in
63: `appsettings.json`. That single value is handed to `lang.js`; no page edits.
64: 
65: ## Setting the download links
66: 
67: The home page download menu is driven by `window.muConfig.downloads` in `wwwroot/content.js`.
68: Each entry is one target:
69: 
70: ```js
71: downloads: [
72:     { id: "launcher", icon: "🚀", name: "Launcher", url: "https://...", recommended: true },
73:     { id: "windows",  icon: "🪟", name: "Windows",  url: "https://..." },
74:     { id: "linux",    icon: "🐧", name: "Linux",    url: "#", soon: true },
75: ],
76: ```
77: 
78: - `url` — the download link. **The shipped values are `#` placeholders — set your own.**
79: - `recommended` — highlights the entry (e.g. the auto-updating launcher).
80: - `soon` — shows it as an upcoming, non-clickable target.
81: 
82: Add or remove a platform by editing this list — no markup changes. The generic labels
83: (Download / recommended / soon) come from the `dl*` keys in the language files.
84: 
85: ---
86: Example:
87: ![Website](assets/example.webp)
88: ---
89: More info about OpenMU project you will find here:
90: https://github.com/MUnique/OpenMU
````

## File: web/Pages/Shared/_Layout.cshtml
````razor
 1: @inject IConfiguration Configuration
 2: @{
 3:     // Single source of truth for the site languages + default (appsettings.json -> "Site").
 4:     // Add a language: drop <code>.js in wwwroot and add the code here. Change the default: edit
 5:     // DefaultLanguage. No page or layout edits needed — every page inherits this.
 6:     var langs = Configuration.GetSection("Site:Languages").Get<string[]>() ?? new[] { "es", "en" };
 7:     var defaultLang = Configuration["Site:DefaultLanguage"] ?? (langs.Length > 0 ? langs[0] : "es");
 8:     var launcherUrl = Configuration["Downloads:LauncherUrl"] ?? Configuration["Downloads:Launcher"] ?? Configuration["Site:LauncherUrl"] ?? "http://192.168.0.172:4173/";
 9: 
10:     // Footer navigation, shared by every page; the current page is skipped automatically.
11:     var active = ViewData["ActivePage"] as string;
12:     var nav = new[]
13:     {
14:         ("/",         "navHome",     "Home"),
15:         ("/stats",    "navStats",    "Server Stats"),
16:         ("/armory",   "navArmory",   "Armory"),
17:         ("/events",   "navEvents",   "Events"),
18:         ("/commands", "navCommands", "Commands"),
19:     };
20: }
21: <!DOCTYPE html>
22: <html lang="@defaultLang">
23: 
24: <head>
25:     <meta charset="UTF-8">
26:     <meta name="viewport" content="width=device-width, initial-scale=1.0">
27:     <title>@ViewData["Title"]</title>
28:     <link rel="stylesheet" href="/style.css">
29:     @foreach (var l in langs)
30:     {
31:         <script src="/@(l).js"></script>
32:     }
33:     <script src="/content.js"></script>
34:     @if (!string.IsNullOrEmpty(launcherUrl))
35:     {
36:         <script>
37:             window.muConfig = window.muConfig || {};
38:             window.muConfig.launcherUrl = @Html.Raw(System.Text.Json.JsonSerializer.Serialize(launcherUrl));
39:             if (window.muConfig.downloads) {
40:                 var launcher = window.muConfig.downloads.find(function (d) { return d.id === 'launcher'; });
41:                 if (launcher) {
42:                     launcher.url = window.muConfig.launcherUrl;
43:                 }
44:             }
45:         </script>
46:     }
47:     <script src="/lang.js" data-default="@defaultLang"></script>
48:     @await RenderSectionAsync("Styles", required: false)
49: </head>
50: 
51: <body class="@ViewData["BodyClass"]">
52:     <div class="container @ViewData["ContainerClass"]">
53:         <div class="lang-switch" id="lang-switch"></div>
54: 
55:         @RenderBody()
56: 
57:         <div class="footer-nav">
58:             @* Account pages (register / changepass) supply their own links via a FooterNav     *@
59:             @* section; every other page falls back to the shared, auto-built game navigation.  *@
60:             @if (IsSectionDefined("FooterNav"))
61:             {
62:                 @await RenderSectionAsync("FooterNav")
63:             }
64:             else
65:             {
66:                 // The home page doubles as the account hub: it surfaces Register / Change
67:                 // Password ahead of the game links. Subpages only navigate among game pages.
68:                 if (active == "/")
69:                 {
70:                     <a href="/register" class="nav-link"><span data-i18n="navRegister">Register Account</span></a>
71:                     <a href="/changepass" class="nav-link"><span data-i18n="navChangePass">Change Password</span></a>
72:                 }
73:                 @foreach (var (route, key, label) in nav)
74:                 {
75:                     if (route != active)
76:                     {
77:                         <a href="@route" class="nav-link"><span data-i18n="@key">@label</span></a>
78:                     }
79:                 }
80:             }
81:         </div>
82:     </div>
83:     <div class="credits">
84:         <a href="https://github.com/nolt" target="_blank">
85:             <span>&lt;/&gt; with ❤️ by</span> Nolt
86:         </a>
87:     </div>
88: 
89:     @* Rendered OUTSIDE .container on purpose: .container has backdrop-filter, which makes it the   *@
90:     @* containing block for position:fixed children. Overlays (e.g. the armory item tooltip) must    *@
91:     @* live here so they position against the viewport, not the panel.                               *@
92:     @await RenderSectionAsync("BodyEnd", required: false)
93: 
94:     @await RenderSectionAsync("Scripts", required: false)
95: </body>
96: 
97: </html>
````

## File: web/wwwroot/content.js
````javascript
 1: // Server-wide settings shared across pages (not language-specific).
 2: window.muConfig = {
 3:     // Reset cap of the server. Characters who reached it get a glowing reset badge
 4:     // in the ranking. Set to your server's real cap; 0 disables the highlight.
 5:     maxResets: 10,
 6: 
 7:     // Download targets shown on the home page. Add/remove an entry here — no markup
 8:     // edits. `recommended` highlights it as the preferred option; `soon` shows it as
 9:     // an upcoming, non-clickable target.
10:     downloads: [
11:         { id: "launcher", icon: "🚀", name: "Web Launcher", url: "http://192.168.0.172:4173/", recommended: true, target: "_blank" },
12:         { id: "windows", icon: "🪟", name: "Windows", url: "#", soon: true },
13:         { id: "linux", icon: "🐧", name: "Linux", url: "#", soon: true },
14:     ],
15: };
16: 
17: window.muContent = {
18:     en: {
19:         welcomeTitle: "Welcome to OpenMU",
20:         welcomeText: `OpenMU is a free and open-source server emulator for MU Online.
21: Experience the game with custom features, active development, and a friendly community.`,
22:         rows: [
23:             [
24:                 { label: "Experience", value: "x50" },
25:                 { label: "Master XP", value: "x30" },
26:                 { label: "Drop Rate", value: "70%" },
27:             ],
28:             [
29:                 { label: "Max Level", value: "400" },
30:                 { label: "Max Master Level", value: "200" },
31:             ],
32:             [
33:                 { label: "Max Resets", value: "10" },
34:                 { label: "Points per Reset", value: "400" },
35:             ],
36:             [
37:                 { label: "Version", value: "Season 6 Ep 3" },
38:             ],
39:             [
40:                 { label: "Discord", value: "Join our Discord", url: "https://discord.gg/your-invite" },
41:             ],
42:         ],
43:     },
44:     es: {
45:         welcomeTitle: "Bienvenido a OpenMU",
46:         welcomeText: `OpenMU es un emulador de servidor gratuito y de código abierto para MU Online.
47: Disfruta del juego con características personalizadas, desarrollo activo y una comunidad amigable.`,
48:         rows: [
49:             [
50:                 { label: "Experiencia", value: "x50" },
51:                 { label: "Master XP", value: "x30" },
52:                 { label: "Drop Rate", value: "70%" },
53:             ],
54:             [
55:                 { label: "Nivel Máximo", value: "400" },
56:                 { label: "Nivel Master Máx", value: "200" },
57:             ],
58:             [
59:                 { label: "Max Resets", value: "10" },
60:                 { label: "Puntos por Reset", value: "400" },
61:             ],
62:             [
63:                 { label: "Versión", value: "Season 6 Ep 3" },
64:             ],
65:             [
66:                 { label: "Discord", value: "Únete a nuestro Discord", url: "https://discord.gg/your-invite" },
67:             ],
68:         ],
69:     }
70: };
````

## File: web/appsettings.json
````json
 1: {
 2:   "ConnectionStrings": {
 3:     "DefaultConnection": "Host=localhost;Database=openmu;Username=postgres;Password=TwojeHaslo"
 4:   },
 5:   "ServerCheck": {
 6:     "Host": "openmu-server",
 7:     "Port": 44406
 8:   },
 9:   "Downloads": {
10:     "LauncherUrl": "http://192.168.0.172:4173/"
11:   },
12:   "Site": {
13:     "Languages": [ "es", "en" ],
14:     "DefaultLanguage": "es"
15:   },
16:   "Logging": {
17:     "LogLevel": {
18:       "Default": "Information",
19:       "Microsoft.AspNetCore": "Warning"
20:     }
21:   },
22:   "AllowedHosts": "*"
23: }
````

## File: docker-compose.yml
````yaml
  1: services:
  2:   openmu-startup:
  3:     image: munique/openmu
  4:     container_name: openmu-startup
  5:     env_file:
  6:       - .env
  7:     networks:
  8:       - openmu-network
  9:     ports:
 10:       - "${ADMIN_PANEL_PORT}:8080"
 11:       - "55901:55901"
 12:       - "55902:55902"
 13:       - "55903:55903"
 14:       - "55904:55904"
 15:       - "55905:55905"
 16:       - "55906:55906"
 17:       - "44405:44405"
 18:       - "55980:55980"
 19:     environment:
 20:       RESOLVE_IP: ${RESOLVE_IP}
 21:       ASPNETCORE_URLS: http://+:8080
 22:       DB_HOST: openmu-database
 23:       # Optional bootstrap admin panel user. Without it, the admin panel is reachable
 24:       # without a login until the first user has been created within the panel itself.
 25:       OPENMU_ADMIN_USER: ${OPENMU_ADMIN_USER}
 26:       OPENMU_ADMIN_PASSWORD: ${OPENMU_ADMIN_PASSWORD}
 27:       # Optional base32 TOTP secret, if the bootstrap user should require a second factor.
 28:       OPENMU_ADMIN_TOTP_SECRET: ${OPENMU_ADMIN_TOTP_SECRET}
 29:       # website authenticates itself at the public API under /api.
 30:       DB_ADMIN_USER: ${POSTGRES_USER}
 31:       DB_ADMIN_PW: ${POSTGRES_PASSWORD}
 32:       # IMPORTANT: Comentar la primera vez que levantes los servicios
 33:       Database__AssumeExternallyProvisioned: true
 34:     volumes:
 35:       - ${OPENMU_DATA_PATH}:/app/data-protection-keys
 36:     working_dir: /app/
 37:     depends_on:
 38:       - openmu-database
 39: 
 40:   openmu-database:
 41:     image: postgres:16-bookworm
 42:     container_name: openmu-database
 43:     env_file:
 44:       - .env
 45:     environment:
 46:       POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
 47:       POSTGRES_DB: ${POSTGRES_DB}
 48:       POSTGRES_USER: ${POSTGRES_USER}
 49:     networks:
 50:       - openmu-network
 51:     volumes:
 52:       - ${OPENMU_DB_PATH}:/var/lib/postgresql/data
 53:     healthcheck:
 54:       test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
 55:       interval: 10s
 56:       timeout: 5s
 57:       retries: 5
 58:       start_period: 10s
 59: 
 60:   openmu-db-backup:
 61:     build:
 62:       context: ./backup
 63:       dockerfile: Dockerfile
 64:     image: openmu-db-backup:latest
 65:     container_name: openmu-db-backup
 66:     restart: unless-stopped
 67:     networks:
 68:       - openmu-network
 69:     environment:
 70:       - PGHOST=openmu-database
 71:       - PGUSER=${POSTGRES_USER}
 72:       - PGPASSWORD=${POSTGRES_PASSWORD}
 73:       - PGDATABASE=${POSTGRES_DB}
 74:       - BACKUP_DIR=/backups
 75:       - BACKUP_CRON_SCHEDULE=${BACKUP_CRON_SCHEDULE}
 76:       - RETENTION_DAYS=${BACKUP_RETENTION_DAYS}
 77:       - RUN_ON_STARTUP=${BACKUP_RUN_ON_STARTUP}
 78:       - TZ=${TIMEZ}
 79:     volumes:
 80:       - ${OPENMU_BACKUP_PATH}:/backups
 81:     depends_on:
 82:       openmu-database:
 83:         condition: service_healthy
 84: 
 85:   openmu-web:
 86:     image: openmu-web:latest
 87:     container_name: openmu-website
 88:     env_file:
 89:       - .env
 90:     build:
 91:       context: ./web
 92:       dockerfile: Dockerfile 
 93:     ports:
 94:       - "${WEB_PORT}:8080"
 95:     environment:
 96:       - ASPNETCORE_URLS=http://0.0.0.0:8080
 97:       - ConnectionStrings__DefaultConnection=Host=${DB_HOST};Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD}
 98:       - ServerCheck__Host=openmu-startup
 99:       - ServerCheck__Port=44406
100:       - TZ=${TIMEZ}
101:     networks:
102:       - openmu-network
103:     restart: always
104:     depends_on:
105:       openmu-database:
106:         condition: service_healthy
107: 
108:   openmu-client:
109:     image: openmu-client:latest
110:     container_name: openmu-client
111:     network_mode: bridge
112:     env_file:
113:       - .env
114:     build:
115:       context: ./client
116:       dockerfile: Dockerfile
117:     ports:
118:       - "${CLIENT_VITE_PORT}:4173"   # Vite preview → http://localhost:<CLIENT_VITE_PORT>/online
119:       - "${CLIENT_PROXY_PORT}:3000"  # WS↔TCP proxy
120:     environment:
121:       - PORT=3000
122:       - CLIENT_VITE_PORT=4173
123:       - HOSTNAME=0.0.0.0
124:       # ALLOW_TARGETS vacío = acepta cualquier host (solo para dev local)
125:       - ALLOW_TARGETS=
126:       - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${DB_HOST}:5432/${POSTGRES_DB}
127:       - VITE_SERVER_LIST_URL=${VITE_SERVER_LIST_URL}
128:     volumes:
129:       - ${CLIENT_DIST_PATH}:/app/dist # Caché del build: persiste entre reinicios
130:     restart: unless-stopped
131: 
132: 
133: networks:
134:   openmu-network:
````
