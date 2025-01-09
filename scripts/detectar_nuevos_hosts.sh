#!/bin/bash

# Directorios y configuración
CONFIG_FILE="../configs/redes_a_monitorizar.txt"
KNOWN_HOSTS_DIR="../output/known_hosts"
KNOWN_DEVICES_FILE="../output/dispositivos_conocidos.txt"
LOG_DIR="../output/logs"
BOT_TOKEN="TU_BOT_TOKEN"
CHAT_ID="TU_CHAT_ID"

# Crear directorios y archivo de dispositivos conocidos si no existen
mkdir -p $KNOWN_HOSTS_DIR $LOG_DIR
touch $KNOWN_DEVICES_FILE

# Función para enviar notificaciones a Telegram
send_notification() {
    NUEVOS_HOSTS=$1
    MESSAGE="🚨 *Nuevos hosts detectados:*\n\n$NUEVOS_HOSTS"
    if [[ -z "$NUEVOS_HOSTS" ]]; then
        echo "No hay nuevos hosts para notificar."
    else
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$MESSAGE" \
            -d parse_mode="Markdown"
        echo "Notificación enviada a Telegram."
    fi
}

# Escaneo periódico
while read -r RED; do
    echo "Iniciando escaneo para la red: $RED"
    OUTPUT_FILE="$KNOWN_HOSTS_DIR/$(echo $RED | tr '/' '_').txt"
    TEMP_FILE="$OUTPUT_FILE.tmp"

    # Realizar escaneo rápido con Nmap
    nmap -sn "$RED" -oG - | awk '/Up$/{print $2}' > "$TEMP_FILE"

    # Comparar resultados con el histórico
    if [[ -f "$OUTPUT_FILE" ]]; then
        NUEVOS_HOSTS=$(comm -13 <(sort "$OUTPUT_FILE") <(sort "$TEMP_FILE"))
        if [[ -n "$NUEVOS_HOSTS" ]]; then
            # Notificar nuevos hosts
            send_notification "$NUEVOS_HOSTS"

            # Añadir los nuevos hosts al historial
            echo "$NUEVOS_HOSTS" >> "$OUTPUT_FILE"

            # Contar ocurrencias de cada host y añadir a dispositivos conocidos si aparecen 3+ veces
            for HOST in $NUEVOS_HOSTS; do
                COUNT=$(grep -c "$HOST" "$OUTPUT_FILE")
                if [[ $COUNT -ge 3 ]]; then
                    if ! grep -q "$HOST" "$KNOWN_DEVICES_FILE"; then
                        echo "$HOST" >> "$KNOWN_DEVICES_FILE"
                        echo "Dispositivo conocido añadido: $HOST"
                    fi
                fi
            done
        fi
    fi

    # Actualizar archivo histórico
    mv "$TEMP_FILE" "$OUTPUT_FILE"
done < "$CONFIG_FILE"

echo "Escaneo completado. Revisa los logs y resultados."
