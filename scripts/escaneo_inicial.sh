#!/bin/bash

# Directorios y configuración
CONFIG_FILE="/home/waidroc/Tools/periodicNetworkDiscovery/configs/redes_a_monitorizar.txt"
KNOWN_HOSTS_DIR="/home/waidroc/Tools/periodicNetworkDiscovery/output/known_hosts"
LOG_DIR="/home/waidroc/Tools/periodicNetworkDiscovery/output/logs"

# Crear directorios si no existen
mkdir -p $KNOWN_HOSTS_DIR $LOG_DIR

# Escaneo inicial
while read -r RED; do
    # Ignorar líneas vacías o comentarios
    [[ -z "$RED" || "$RED" =~ ^# ]] && continue

    echo "Iniciando escaneo inicial para la red: $RED"
    OUTPUT_FILE="$KNOWN_HOSTS_DIR/$(echo $RED | tr '/' '_').txt"

    # Configurar timeout de 2 minutos para el escaneo
    timeout 120 nmap -sn "$RED" -oG - | awk '/Up$/{print $2}' > "$OUTPUT_FILE"

    # Verificar si el escaneo produjo resultados
    if [[ -s "$OUTPUT_FILE" ]]; then
        echo "Resultados iniciales guardados en $OUTPUT_FILE"
    else
        echo "⚠️ No se encontraron hosts en la red: $RED. Verifica si está bien escrita." | tee -a "$LOG_DIR/error.log"
    fi
done < "$CONFIG_FILE"

echo "Escaneo inicial completado. Verifica los resultados en $KNOWN_HOSTS_DIR"
