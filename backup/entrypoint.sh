#!/bin/bash
set -euo pipefail

# Exportar variables de entorno para que cron las reconozca al ejecutarse
printenv | grep -E '^(PG|BACKUP_|RETENTION_|TZ|PATH)' > /etc/environment

CRON_SCHEDULE="${BACKUP_CRON_SCHEDULE:-0 3 * * *}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

echo "=========================================================="
echo " OpenMU PostgreSQL Backup Service (Cron Scheduler)"
echo " Base de datos objetivo: ${PGDATABASE:-openmu}@${PGHOST:-openmu-database}"
echo " Horario Cron: ${CRON_SCHEDULE}"
echo " Retención: ${RETENTION_DAYS} días"
echo " Carpeta de Backups: ${BACKUP_DIR}"
echo "=========================================================="

# Configurar crontab de sistema en Debian (/etc/cron.d/)
CRON_FILE="/etc/cron.d/openmu-backup"
cat <<EOF > "$CRON_FILE"
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${CRON_SCHEDULE} root /usr/local/bin/backup.sh >> /proc/1/fd/1 2>> /proc/1/fd/2
EOF

# Permisos estrictos requeridos por cron en Debian
chmod 0644 "$CRON_FILE"

# Backup inicial al arrancar el contenedor
if [ "${RUN_ON_STARTUP:-true}" = "true" ]; then
    echo "[STARTUP] Ejecutando backup inicial de verificación..."
    /usr/local/bin/backup.sh || echo "[STARTUP] Advertencia: Falló el backup inicial, el demonio cron continuará en espera."
fi

echo "[CRON] Demonio cron activo y escuchando..."
exec cron -f
