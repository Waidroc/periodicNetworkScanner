#!/bin/bash

# Directorios y configuración
CONFIG_FILE="../configs/redes_a_monitorizar.txt"
KNOWN_HOSTS_DIR="../output/known_hosts"
LOG_DIR="../output/logs"

# Crear directorios si no existen
mkdir -p $KNOWN_HOSTS_DIR $LOG_DIR

# Escaneo inicial
while read -r RED; do
    echo "Iniciando escaneo inicial para la red: $RED"
    OUTPUT_FILE="$KNOWN_HOSTS_DIR/$(echo $RED | tr '/' '_').txt"

    # Escaneo rápido con Nmap en modo ping-only
    nmap -sn "$RED" -oG - | awk '/Up$/{print $2}' > "$OUTPUT_FILE"

    echo "Resultados iniciales guardados en $OUTPUT_FILE"
done < "$CONFIG_FILE"

echo "Escaneo inicial completado. Verifica los resultados en $KNOWN_HOSTS_DIR"