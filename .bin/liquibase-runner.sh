#!/usr/bin/env bash
# Usage: ./run-liquibase-json.sh <jar-file> [args...]

RUNNER_JAR="$1"

# Prüfen, ob LIQUIBASE_HOME gesetzt ist
if [ -z "$LIQUIBASE_HOME" ]; then
    # JSON-Fehler ausgeben und Skript beenden
    TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
    echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"ERROR\",\"message\":\"LIQUIBASE_HOME is not set. Please set it to your Liquibase installation.\"}"
    exit 1
fi

# Prüfen, ob das Verzeichnis existiert
if [ ! -d "$LIQUIBASE_HOME" ]; then
    TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")
    echo "{\"timestamp\":\"$TIMESTAMP\",\"level\":\"ERROR\",\"message\":\"LIQUIBASE_HOME directory '$LIQUIBASE_HOME' does not exist.\"}"
    exit 1
fi

# Alle JARs im Liquibase-Home sammeln
LIQUIBASE_CP=$(find "$LIQUIBASE_HOME" -name "*.jar" | tr '\n' ':')

# Runner starten
java -cp "$RUNNER_JAR:$LIQUIBASE_CP" net.ct.LiquibaseRunner "$@" 2>&1 | awk '
{
    # Escape quotes
    gsub(/"/, "\\\"", $0)
    level = ($0 ~ /ERROR|Exception/) ? "ERROR" : "INFO"
    printf("{\"timestamp\":\"%s\",\"level\":\"%s\",\"message\":\"%s\"}\n", strftime("%Y-%m-%dT%H:%M:%S%z"), level, $0)
}'
