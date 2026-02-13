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

set -o pipefail

# Start wrapper runner
java -cp "$RUNNER_JAR:$LIQUIBASE_CP" net.ct.LiquibaseRunner "$@" 2>&1 | awk '
{
    line = $0

    # If line looks like JSON, pass through untouched
    if (line ~ /^[[:space:]]*\{.*\}[[:space:]]*$/) {
        print line
        next
    }

    # Escape quotes for non-JSON lines
    gsub(/"/, "\\\"", line)

    level = "INFO"
    if (tolower(line) ~ /error/) {
        level = "ERROR"
    }

    printf("{\"@timestamp\":\"%s\",\"level\":\"%s\",\"message\":\"%s\"}\n",
        strftime("%Y-%m-%dT%H:%M:%S%z"), level, line)
}'

exit $?