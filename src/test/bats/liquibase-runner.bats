#!/usr/bin/env bats

# =============================================================================
# liquibase-runner.bats
# BATS tests for liquibase-runner.sh
# =============================================================================

SCRIPT="$BATS_TEST_DIRNAME/../../../.bin/liquibase-runner.sh"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
setup() {
    # Temp workspace isolated per test
    TEST_DIR="$(mktemp -d)"
    export LIQUIBASE_HOME="$TEST_DIR/liquibase"
    mkdir -p "$LIQUIBASE_HOME/lib"

    # Minimal fake runner JAR (just needs to exist as a file)
    RUNNER_JAR="$TEST_DIR/runner.jar"
    touch "$RUNNER_JAR"

    # Ensure script is executable
    chmod +x "$SCRIPT"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Emit a valid ECS JSON line to stdout so emit_line passes it through
fake_json_line() {
    echo '{"@timestamp":"2026-01-01T00:00:00+0000","log":{"level":"INFO"},"message":"ok","ecs.version":"1.12.0","service.name":"liquibase"}'
}

# Source only the pure functions (no main logic) for unit-level tests
source_functions() {
    # We source up to but not including the input-validation block
    # by extracting and eval-ing just the function definitions.
    eval "$(sed -n '/^json_log()/,/^}/p; /^detect_level()/,/^}/p; /^emit_line()/,/^}/p' "$SCRIPT")"
}

# =============================================================================
# detect_level — unit tests (no subprocess needed)
# =============================================================================

@test "detect_level: plain line → INFO" {
    source_functions
    result="$(detect_level "Running update for version 42")"
    [ "$result" = "INFO" ]
}

@test "detect_level: line containing 'error' → ERROR" {
    source_functions
    result="$(detect_level "Unknown error: No suitable driver found")"
    [ "$result" = "ERROR" ]
}

@test "detect_level: line containing 'Exception' → ERROR" {
    source_functions
    result="$(detect_level "java.lang.NullPointerException at Runner.java:10")"
    [ "$result" = "ERROR" ]
}

@test "detect_level: line containing 'fatal' → ERROR" {
    source_functions
    result="$(detect_level "fatal: could not open config")"
    [ "$result" = "ERROR" ]
}

@test "detect_level: line containing 'warn' → WARN" {
    source_functions
    result="$(detect_level "warn: deprecated option used")"
    [ "$result" = "WARN" ]
}

@test "detect_level: line containing 'warning' → WARN" {
    source_functions
    result="$(detect_level "WARNING: SSL cert not verified")"
    [ "$result" = "WARN" ]
}

@test "detect_level: line containing 'debug' → DEBUG" {
    source_functions
    result="$(detect_level "debug: entering main loop")"
    [ "$result" = "DEBUG" ]
}

@test "detect_level: line containing 'trace' → DEBUG" {
    source_functions
    result="$(detect_level "trace: method entry")"
    [ "$result" = "DEBUG" ]
}

# =============================================================================
# json_log — unit tests
# =============================================================================

@test "json_log: output is valid JSON" {
    source_functions
    output="$(json_log "INFO" "hello world")"
    echo "$output" | jq . > /dev/null
}

@test "json_log: output contains correct level" {
    source_functions
    level="$(json_log "ERROR" "something went wrong" | jq -r '.log.level')"
    [ "$level" = "ERROR" ]
}

@test "json_log: output contains correct message" {
    source_functions
    msg="$(json_log "INFO" "hello world" | jq -r '.message')"
    [ "$msg" = "hello world" ]
}

@test "json_log: output contains ecs.version 1.12.0" {
    source_functions
    ver="$(json_log "INFO" "x" | jq -r '."ecs.version"')"
    [ "$ver" = "1.12.0" ]
}

@test "json_log: service.name defaults to 'liquibase'" {
    source_functions
    unset SERVICE_NAME
    svc="$(json_log "INFO" "x" | jq -r '."service.name"')"
    [ "$svc" = "liquibase" ]
}

@test "json_log: service.name uses SERVICE_NAME env var" {
    source_functions
    SERVICE_NAME="my-service" \
    svc="$(json_log "INFO" "x" | jq -r '."service.name"')"
    [ "$svc" = "my-service" ]
}

@test "json_log: strips Liquibase timestamp prefix from message" {
    source_functions
    msg="$(json_log "INFO" "15:18:57,123 |-INFO in some.Class - actual message" | jq -r '.message')"
    [ "$msg" = "actual message" ]
}

@test "json_log: @timestamp field is present and non-empty" {
    source_functions
    ts="$(json_log "INFO" "x" | jq -r '."@timestamp"')"
    [ -n "$ts" ]
}

# =============================================================================
# emit_line — unit tests
# =============================================================================

@test "emit_line: passes through existing JSON unchanged" {
    source_functions
    input='{"@timestamp":"2026-01-01T00:00:00+0000","log":{"level":"INFO"},"message":"ok","ecs.version":"1.12.0","service.name":"liquibase"}'
    output="$(emit_line "$input")"
    [ "$output" = "$input" ]
}

@test "emit_line: wraps plain text as JSON" {
    source_functions
    output="$(emit_line "some plain log line")"
    echo "$output" | jq . > /dev/null
}

@test "emit_line: empty line produces no output" {
    source_functions
    output="$(emit_line "")"
    [ -z "$output" ]
}

# =============================================================================
# Script-level validation — input / environment checks
# =============================================================================

@test "script exits 1 with no arguments" {
    run "$SCRIPT"
    [ "$status" -eq 1 ]
}

@test "script exit-1 message is valid JSON" {
    run "$SCRIPT"
    echo "$output" | jq . > /dev/null
}

@test "script exits 1 when runner JAR does not exist" {
    run "$SCRIPT" "/nonexistent/runner.jar"
    [ "$status" -eq 1 ]
}

@test "script exits 1 when LIQUIBASE_HOME is not set" {
    unset LIQUIBASE_HOME
    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 1 ]
}

@test "script exits 1 when LIQUIBASE_HOME does not exist" {
    export LIQUIBASE_HOME="/nonexistent/path"
    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 1 ]
}

@test "script error output is valid JSON when LIQUIBASE_HOME missing" {
    unset LIQUIBASE_HOME
    run "$SCRIPT" "$RUNNER_JAR"
    echo "$output" | jq . > /dev/null
}

# =============================================================================
# Classpath construction
# =============================================================================

@test "classpath includes JARs from subdirectories of LIQUIBASE_HOME" {
    # Place fake JARs in nested dirs
    mkdir -p "$LIQUIBASE_HOME/lib" "$LIQUIBASE_HOME/internal/lib"
    touch "$LIQUIBASE_HOME/lib/liquibase-core.jar"
    touch "$LIQUIBASE_HOME/internal/lib/snakeyaml.jar"
    touch "$LIQUIBASE_HOME/lib/ojdbc11.jar"

    # Stub java to print the -cp value and exit 0
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/java" <<'EOF'
#!/usr/bin/env bash
# Print each -cp entry on its own line, then exit cleanly
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "-cp" ]]; then
        echo "$2" | tr ':' '\n'
        shift 2
    else
        shift
    fi
done
exit 0
EOF
    chmod +x "$TEST_DIR/bin/java"
    export PATH="$TEST_DIR/bin:$PATH"

    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "liquibase-core.jar"
    echo "$output" | grep -q "snakeyaml.jar"
    echo "$output" | grep -q "ojdbc11.jar"
}

# =============================================================================
# Exit code propagation
# =============================================================================

@test "script forwards exit code 0 from java" {
    mkdir -p "$TEST_DIR/bin"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_DIR/bin/java"
    chmod +x "$TEST_DIR/bin/java"
    export PATH="$TEST_DIR/bin:$PATH"

    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 0 ]
}

@test "script forwards non-zero exit code from java" {
    mkdir -p "$TEST_DIR/bin"
    printf '#!/usr/bin/env bash\necho "liquibase failed"; exit 2\n' > "$TEST_DIR/bin/java"
    chmod +x "$TEST_DIR/bin/java"
    export PATH="$TEST_DIR/bin:$PATH"

    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 2 ]
}

@test "script emits ERROR log when java exits non-zero" {
    mkdir -p "$TEST_DIR/bin"
    printf '#!/usr/bin/env bash\necho "something failed"; exit 1\n' > "$TEST_DIR/bin/java"
    chmod +x "$TEST_DIR/bin/java"
    export PATH="$TEST_DIR/bin:$PATH"

    run "$SCRIPT" "$RUNNER_JAR"
    # At least one output line must be JSON with level ERROR
    found_error=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        level="$(echo "$line" | jq -r '.log.level' 2>/dev/null)" || continue
        if [[ "$level" == "ERROR" ]]; then
            found_error=1
            break
        fi
    done <<< "$output"
    [ "$found_error" -eq 1 ]
}

@test "all output lines are valid JSON" {
    mkdir -p "$TEST_DIR/bin"
    cat > "$TEST_DIR/bin/java" <<'EOF'
#!/usr/bin/env bash
echo "15:18:57,123 |-INFO in some.Class - Running update"
echo "WARNING: deprecated flag"
echo "Unknown error: driver not found"
exit 0
EOF
    chmod +x "$TEST_DIR/bin/java"
    export PATH="$TEST_DIR/bin:$PATH"

    run "$SCRIPT" "$RUNNER_JAR"
    [ "$status" -eq 0 ]
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        echo "$line" | jq . > /dev/null
    done <<< "$output"
}
