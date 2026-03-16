#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# liquibase-runner.sh
# Wraps LiquibaseRunner with ECS JSON logging and correct exit code propagation
# =============================================================================

# -----------------------------------------------------------------------------
# ECS JSON logger
# -----------------------------------------------------------------------------
json_log() {
    local level="$1"
    local message="$2"

    # Strip common Liquibase log prefixes like "15:18:57,123 |-INFO in ... - "
    message=$(echo "$message" | sed -E 's/^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} \|-[A-Z]+ in [^ ]+ - //')

    jq -cn \
        --arg timestamp "$(date +'%Y-%m-%dT%H:%M:%S%z')" \
        --arg level    "$level" \
        --arg msg      "$message" \
        --arg ecs      "1.12.0" \
        --arg svc      "${SERVICE_NAME:-liquibase}" \
        '{
            "@timestamp":   $timestamp,
            "log":          { "level": $level },
            "message":      $msg,
            "ecs.version":  $ecs,
            "service.name": $svc
        }'
}

# -----------------------------------------------------------------------------
# Map a Liquibase level token (English or German locale) to an ECS level string
# -----------------------------------------------------------------------------
map_liq_level() {
    local lvl
    lvl="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
    case "$lvl" in
        error|fehler)         echo "ERROR" ;;
        warn|warning|warnung) echo "WARN"  ;;
        debug)                echo "DEBUG" ;;
        trace)                echo "TRACE" ;;
        *)                    echo "INFO"  ;;
    esac
}

# -----------------------------------------------------------------------------
# Detect log level from a plain-text line
# -----------------------------------------------------------------------------
detect_level() {
    local line
    line="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
    if [[ "$line" =~ error|exception|fatal ]]; then
        echo "ERROR"
    elif [[ "$line" =~ warn(ing)?|warnung ]]; then
        echo "WARN"
    elif [[ "$line" =~ debug|trace ]]; then
        echo "DEBUG"
    else
        echo "INFO"
    fi
}

# -----------------------------------------------------------------------------
# Route a single output line to ECS JSON
# -----------------------------------------------------------------------------
emit_line() {
    local line="$1"
    [[ -z "$line" ]] && return

    # Already ECS/JSON — pass straight through
    if [[ "$line" =~ ^[[:space:]]*\{.*\}[[:space:]]*$ ]]; then
        echo "$line"
        return
    fi

    # Liquibase prefixed format: [YYYY-MM-DD HH:MM:SS] LEVEL [logger] message
    # Lines tagged [liquibase.ui] are bare-text duplicates of UIService output — skip them.
    # Lines from other loggers carry unique info: extract the embedded level and strip the prefix.
    if [[ "$line" =~ ^\[([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2})\][[:space:]]([A-Z]+)[[:space:]]\[([^]]+)\][[:space:]](.*)$ ]]; then
        local liq_level="${BASH_REMATCH[2]}"
        local liq_logger="${BASH_REMATCH[3]}"
        local liq_msg="${BASH_REMATCH[4]}"
        if [[ "$liq_logger" == "liquibase.ui" ]]; then
            return  # UIService also emits the bare message — suppress the prefixed duplicate
        fi
        json_log "$(map_liq_level "$liq_level")" "$liq_msg"
        return
    fi

    json_log "$(detect_level "$line")" "$line"
}

# -----------------------------------------------------------------------------
# Validate inputs
# -----------------------------------------------------------------------------
if [[ -z "${1:-}" ]]; then
    json_log "ERROR" "Usage: $0 <runner-jar> [args...]"
    exit 1
fi

RUNNER_JAR="$1"
shift   # remaining args go to LiquibaseRunner

if [[ ! -f "$RUNNER_JAR" ]]; then
    json_log "ERROR" "Runner JAR not found: $RUNNER_JAR"
    exit 1
fi

if [[ -z "${LIQUIBASE_HOME:-}" ]]; then
    json_log "ERROR" "LIQUIBASE_HOME is not set"
    exit 1
fi

if [[ ! -d "$LIQUIBASE_HOME" ]]; then
    json_log "ERROR" "LIQUIBASE_HOME does not exist: $LIQUIBASE_HOME"
    exit 1
fi

# -----------------------------------------------------------------------------
# Build classpath: runner JAR + every *.jar found anywhere under LIQUIBASE_HOME
# -----------------------------------------------------------------------------
LIQUIBASE_CP="$RUNNER_JAR"

while IFS= read -r jar; do
    LIQUIBASE_CP="$LIQUIBASE_CP:$jar"
done < <(find "$LIQUIBASE_HOME" -name "*.jar" 2>/dev/null)

json_log "INFO" "Using classpath entries: $(echo "$LIQUIBASE_CP" | tr ':' '\n' | awk 'END{print NR}') JARs"

# -----------------------------------------------------------------------------
# Execute LiquibaseRunner, stream output through ECS formatter
# -----------------------------------------------------------------------------
# Temporarily disable set -e so a non-zero java exit does not abort the script
# before we can read PIPESTATUS. Re-enable immediately after.
set +e
java -cp "$LIQUIBASE_CP" -Djdbc.drivers=oracle.jdbc.OracleDriver net.ct.LiquibaseRunner "$@" 2>&1 \
    | while IFS= read -r line; do
          emit_line "$line"
      done
# Capture PIPESTATUS[0] (java exit code) before anything else can overwrite it.
JAVA_EXIT="${PIPESTATUS[0]}"
set -e

if [[ "$JAVA_EXIT" -ne 0 ]]; then
    json_log "ERROR" "LiquibaseRunner exited with code $JAVA_EXIT"
fi

exit "$JAVA_EXIT"
