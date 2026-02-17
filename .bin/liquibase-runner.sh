#!/usr/bin/env bash
set -e

# ------------------------------------------
# ECS JSON logger function
# ------------------------------------------
json_log() {
  local log_level="$1"
  # clean message
  local message=$(echo "$2" | sed -E 's/^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} \|-[A-Z]+ in [^ ]+ - //')
  jq -cn \
    --arg timestamp "$(date +'%Y-%m-%dT%H:%M:%S%z')" \
    --arg level "$log_level" \
    --arg msg "$message" \
    --arg ecs_version "1.12.0" \
    --arg service_name "${SERVICE_NAME:-liquibase}" \
    '{
      "@timestamp": $timestamp,
      "log": {"level": $level},
      "message": $msg,
      "ecs.version": $ecs_version,
      "service.name": $service_name
    }'
}

# ------------------------------------------
# Check input
# ------------------------------------------
if [ -z "$1" ]; then
    json_log "ERROR" "Usage: $0 <runner-jar> [args...]"
    exit 1
fi

RUNNER_JAR="$1"
shift  # remove first argument, pass remaining args to LiquibaseRunner

# ------------------------------------------
# Ensure LIQUIBASE_HOME is set
# ------------------------------------------
if [ -z "$LIQUIBASE_HOME" ]; then
    json_log "ERROR" "LIQUIBASE_HOME not set"
    exit 1
fi

# Build classpath: your runner + liquibase jars
LIQUIBASE_CP=$(find "$LIQUIBASE_HOME" -name "*.jar" | tr '\n' ':')

# Run the Java runner and pipe through ECS logger
java -cp "$LIQUIBASE_CP:$RUNNER_JAR" net.ct.LiquibaseRunner "$@" \
  2>&1 | while IFS= read -r line; do
      [[ -z "$line" ]] && continue

      # Already JSON? Pass through
      if [[ "$line" =~ ^[[:space:]]*\{.*\}[[:space:]]*$ ]]; then
          echo "$line"
      else
          # Detect error heuristically
          level="INFO"
          if [[ "${line,,}" =~ error ]]; then
              level="ERROR"
          fi
          json_log "$level" "$line"
      fi
  done

# ------------------------------------------
# Forward LiquibaseRunner exit code
# ------------------------------------------
exit ${PIPESTATUS[0]}
