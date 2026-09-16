#!/bin/bash
set -e

PREVIEW_PORT="${CLIENT_VITE_PORT:-4173}"
BUILD_MARKER="/app/dist/.build-done"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 Aplicando personalizaciones al cliente..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# 1. Poner Modo de Video Clásico por defecto (Preajuste Clásica exacto)
sed -i 's/lightingQuality: 1/lightingQuality: 0/' src/common/gameOptions.ts
sed -i 's/materialQuality: 1/materialQuality: 0/' src/common/gameOptions.ts
# 2. Desactivar la creación automática de "Local (OpenMU)" en serverConfig.ts
sed -i 's/function seedsDefaultProfile(): boolean {/function seedsDefaultProfile(): boolean { return false;/' src/common/serverConfig.ts
# 3. Zoom inicial más alejado (1700 en lugar de 1200)
sed -i 's/const PORTED_DEFAULT_DISTANCE = 1200;/const PORTED_DEFAULT_DISTANCE = 1700;/' src/camera/recipes.ts
# 4. Splash screen fijo de 2 segundos con fade-out suave
sed -i 's|<div id="root"></div>|<div id="root"></div><div id="splash" style="position:fixed;inset:0;background:#000000;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#e5c158;font-family:sans-serif;letter-spacing:2px;font-size:14px;z-index:99999;transition:opacity 0.6s ease-out;pointer-events:none;"><img src="./Data/Logo/logo.jpg" style="max-width:280px;width:60%;margin-bottom:18px;image-rendering:pixelated;" alt="MU Online"/><div>CARGANDO CLIENTE...</div></div><script>setTimeout(function(){var s=document.getElementById("splash");if(s){s.style.opacity="0";setTimeout(function(){s.remove()},600);}},3000);</script>|' index.html
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔨 Building OpenMu-Client-Babylon (prod)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bun run build
echo "✅ Build completado"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶ Starting WS↔TCP proxy on port ${PORT:-3000}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bun run proxy &
PROXY_PID=$!

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶ Starting preview server on port ${PREVIEW_PORT}..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bun run vite preview --host 0.0.0.0 --port "${PREVIEW_PORT}" --strictPort &
PREVIEW_PID=$!
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Client ready → http://localhost:${PREVIEW_PORT}/online"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Monitorear ambos procesos; si uno cae, matar el otro y salir
monitor() {
  while true; do
    for pid in $PROXY_PID $PREVIEW_PID; do
      if ! kill -0 "$pid" 2>/dev/null; then
        echo "Proceso $pid terminó — apagando contenedor"
        kill $PROXY_PID $PREVIEW_PID 2>/dev/null || true
        exit 1
      fi
    done
    sleep 2
  done
}

trap 'kill $PROXY_PID $PREVIEW_PID 2>/dev/null; exit 0' SIGTERM SIGINT

monitor
