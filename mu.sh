#!/usr/bin/env bash
# =============================================================================
# mu.sh — Administrador de servicios OpenMU
# Uso: ./mu.sh [comando] [servicio...]
#      ./mu.sh            (modo interactivo)
# =============================================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Directorio del script ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
DC="docker compose -f $COMPOSE_FILE"

# ── Servicios disponibles ─────────────────────────────────────────────────────
SERVICES=(
  "openmu-database"
  "openmu-startup"
  "openmu-web"
  "openmu-client"
)

SERVICE_LABELS=(
  "🗄️  Base de datos  (PostgreSQL)"
  "⚙️  Servidor OpenMU"
  "🌐  Sitio web      (ASP.NET)"
  "🎮  Cliente web    (BabylonJS · Vite + Proxy)"
)

# =============================================================================
# Helpers
# =============================================================================

print_banner() {
  echo -e ""
  echo -e "${BOLD}${MAGENTA}  ╔═══════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${MAGENTA}  ║      🧙  OpenMU Service Manager       ║${RESET}"
  echo -e "${BOLD}${MAGENTA}  ╚═══════════════════════════════════════╝${RESET}"
  echo -e ""
}

print_status() {
  echo -e "${BOLD}${CYAN}  ► Estado actual de los contenedores${RESET}"
  echo -e "${DIM}  ──────────────────────────────────────────────────${RESET}"
  $DC ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | \
    awk 'NR==1 {print "  "$0} NR>1 {
      if ($0 ~ /Up/) printf "  \033[0;32m✔\033[0m %s\n", $0
      else if ($0 ~ /Exit|Exited/) printf "  \033[0;31m✘\033[0m %s\n", $0
      else printf "  \033[1;33m●\033[0m %s\n", $0
    }' || echo -e "${DIM}  (sin contenedores corriendo)${RESET}"
  echo ""
}

print_menu() {
  echo -e "${BOLD}  Comandos disponibles:${RESET}"
  echo -e "  ${GREEN}[1]${RESET} up       — Levantar servicios"
  echo -e "  ${RED}[2]${RESET} down     — Detener y remover servicios"
  echo -e "  ${YELLOW}[3]${RESET} restart  — Reiniciar servicios"
  echo -e "  ${BLUE}[4]${RESET} build    — Rebuild de imágenes + up"
  echo -e "  ${CYAN}[5]${RESET} logs     — Ver logs en tiempo real"
  echo -e "  ${MAGENTA}[6]${RESET} status   — Ver estado (ps)"
  echo -e "  ${DIM}[0]${RESET} exit     — Salir"
  echo ""
}

print_service_selector() {
  echo -e "${BOLD}  Selecciona servicios ${DIM}(Enter = todos)${RESET}${BOLD}:${RESET}"
  for i in "${!SERVICES[@]}"; do
    echo -e "  ${CYAN}[$((i+1))]${RESET} ${SERVICE_LABELS[$i]}"
  done
  echo -e "  ${DIM}[a]${RESET} Todos los servicios"
  echo ""
}

# Retorna lista de servicios seleccionados en $SELECTED
select_services() {
  print_service_selector
  echo -ne "${BOLD}  Opción(es) ${DIM}[ej: 1 3 4 | a | Enter para todos]${RESET}${BOLD}: ${RESET}"
  read -r raw

  SELECTED=()
  if [[ -z "$raw" || "$raw" == "a" ]]; then
    # todos
    return
  fi

  for token in $raw; do
    if [[ "$token" =~ ^[0-9]+$ ]]; then
      idx=$((token - 1))
      if [[ $idx -ge 0 && $idx -lt ${#SERVICES[@]} ]]; then
        SELECTED+=("${SERVICES[$idx]}")
      else
        echo -e "${YELLOW}  ⚠ Índice '$token' inválido, ignorado.${RESET}"
      fi
    fi
  done
}

log_action() {
  local verb="$1"; shift
  echo -e "\n${BOLD}${BLUE}  ┌─ $verb ${DIM}$(date '+%H:%M:%S')${RESET}"
  if [[ ${#@} -gt 0 ]]; then
    echo -e "${BLUE}  │  Servicios: ${CYAN}$*${RESET}"
  else
    echo -e "${BLUE}  │  Servicios: ${CYAN}todos${RESET}"
  fi
  echo -e "${BLUE}  └──────────────────────────────────────────${RESET}\n"
}

# =============================================================================
# Acciones
# =============================================================================

do_up() {
  log_action "▲  UP" "$@"
  $DC up -d "$@"
  echo -e "\n${GREEN}  ✔ Servicios levantados.${RESET}"
  print_status
}

do_down() {
  log_action "▼  DOWN" "$@"
  if [[ ${#@} -eq 0 ]]; then
    $DC down
  else
    $DC stop "$@"
    $DC rm -f "$@"
  fi
  echo -e "\n${RED}  ✔ Servicios detenidos.${RESET}"
}

do_restart() {
  log_action "↺  RESTART" "$@"
  if [[ ${#@} -eq 0 ]]; then
    $DC restart
  else
    $DC restart "$@"
  fi
  echo -e "\n${YELLOW}  ✔ Servicios reiniciados.${RESET}"
  print_status
}

do_build() {
  log_action "🔨 BUILD + UP" "$@"
  $DC up -d --build "$@"
  echo -e "\n${BLUE}  ✔ Build completado y servicios levantados.${RESET}"
  print_status
}

do_logs() {
  log_action "📋 LOGS" "$@"
  echo -e "${DIM}  (Ctrl+C para salir de los logs)${RESET}\n"
  $DC logs -f --tail=100 "$@"
}

do_status() {
  print_status
}

# =============================================================================
# Modo no interactivo: ./mu.sh <comando> [servicio...]
# =============================================================================

run_command() {
  local cmd="$1"; shift
  local svcs=("$@")

  case "$cmd" in
    up)      do_up      "${svcs[@]}" ;;
    down)    do_down    "${svcs[@]}" ;;
    restart) do_restart "${svcs[@]}" ;;
    build)   do_build   "${svcs[@]}" ;;
    logs)    do_logs    "${svcs[@]}" ;;
    status|ps) do_status ;;
    *)
      echo -e "${RED}  ✘ Comando desconocido: '$cmd'${RESET}"
      echo -e "  Uso: $0 {up|down|restart|build|logs|status} [servicio...]"
      exit 1
      ;;
  esac
}

# =============================================================================
# Modo interactivo
# =============================================================================

interactive() {
  while true; do
    clear
    print_banner
    print_status
    print_menu

    echo -ne "${BOLD}  Comando [0-6]: ${RESET}"
    read -r choice
    echo ""

    case "$choice" in
      0) echo -e "${DIM}  Hasta luego.${RESET}\n"; exit 0 ;;
      6) do_status; read -rp "  Presiona Enter para continuar..." ;;
      1|2|3|4|5)
        SELECTED=()
        select_services
        case "$choice" in
          1) do_up      "${SELECTED[@]}" ;;
          2) do_down    "${SELECTED[@]}" ;;
          3) do_restart "${SELECTED[@]}" ;;
          4) do_build   "${SELECTED[@]}" ;;
          5) do_logs    "${SELECTED[@]}" ;;
        esac
        echo ""
        read -rp "  Presiona Enter para continuar..." ;;
      *)
        echo -e "${YELLOW}  ⚠ Opción inválida.${RESET}"
        sleep 1 ;;
    esac
  done
}

# =============================================================================
# Entry point
# =============================================================================

if [[ $# -ge 1 ]]; then
  # Modo CLI: ./mu.sh up openmu-client
  run_command "$@"
else
  # Modo interactivo
  interactive
fi
