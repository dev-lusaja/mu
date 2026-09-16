#!/bin/bash
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
PGDATABASE="${PGDATABASE:-openmu}"
PGHOST="${PGHOST:-openmu-database}"
PGUSER="${PGUSER:-postgres}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST="${BACKUP_DIR}/${PGDATABASE}_${TIMESTAMP}.dump"
TEMP_DEST="${DEST}.tmp"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [BACKUP] $*"; }

log "Iniciando respaldo de: ${PGDATABASE}@${PGHOST}..."

# 1. Volcado con formato personalizado de Postgres (-Fc) y compresión máxima nativa (-Z 9)
if ! pg_dump -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" -Fc -Z 9 -f "$TEMP_DEST"; then
    log "ERROR: pg_dump falló. Eliminando archivo temporal incompleto."
    rm -f "$TEMP_DEST"
    exit 1
fi

# 2. Verificación de integridad: pg_restore examina la tabla de contenidos (TOC)
if ! pg_restore --list "$TEMP_DEST" >/dev/null 2>&1; then
    log "ERROR: El volcado no superó la prueba de integridad de pg_restore. Eliminando."
    rm -f "$TEMP_DEST"
    exit 1
fi

mv "$TEMP_DEST" "$DEST"
SIZE=$(du -h "$DEST" | cut -f1)
log "Respaldo completado exitosamente: ${DEST} (${SIZE})"

# 3. Política de retención: limpiar dumps más antiguos que RETENTION_DAYS
DELETED=$(find "$BACKUP_DIR" -type f \( -name "${PGDATABASE}_*.dump" -o -name "${PGDATABASE}_*.dump.tmp" \) -mtime "+${RETENTION_DAYS}" -print -delete | wc -l)
if [ "$DELETED" -gt 0 ]; then
    log "Retención: Eliminado(s) ${DELETED} archivo(s) con más de ${RETENTION_DAYS} días de antigüedad."
fi
