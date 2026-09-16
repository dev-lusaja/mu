#!/bin/bash
set -euo pipefail

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "=========================================================="
    echo " USO: restore.sh /backups/<archivo>.dump"
    echo "=========================================================="
    echo "Archivos disponibles en /backups:"
    ls -lh /backups/*.dump 2>/dev/null || echo "No se encontraron archivos .dump en /backups"
    exit 1
fi

PGDATABASE="${PGDATABASE:-openmu}"
PGHOST="${PGHOST:-openmu-database}"
PGUSER="${PGUSER:-postgres}"

echo "=========================================================="
echo " ADVERTENCIA: Se restaurará la base de datos '$PGDATABASE'"
echo " Host: $PGHOST | Usuario: $PGUSER"
echo " Archivo a restaurar: $BACKUP_FILE"
echo "=========================================================="
echo "Iniciando restauración en 5 segundos (Presiona CTRL+C para cancelar)..."
sleep 5

echo "Restaurando base de datos..."
pg_restore -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" --clean --if-exists "$BACKUP_FILE"

echo "=========================================================="
echo " [OK] Restauración completada con éxito."
echo "=========================================================="
