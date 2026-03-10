# CLAUDE.md — Learnings: liquibase-runner.sh

Lessons captured from developing and debugging `liquibase-runner.sh` and its BATS test suite.

---

## Shell Script

### `set -e` kills the script before `PIPESTATUS` can be read

When `set -euo pipefail` is active and a piped command exits non-zero, bash aborts
immediately after the pipe — before any subsequent line runs. This means:

```bash
# BROKEN: set -e aborts here if java exits non-zero
java ... | while ...; done
JAVA_EXIT="${PIPESTATUS[0]}"   # never reached
```

**Fix:** bracket the pipe with `set +e` / `set -e`:

```bash
set +e
java ... | while ...; done
JAVA_EXIT="${PIPESTATUS[0]}"   # always reached, holds real java exit code
set -e
```

### `|| true` destroys `PIPESTATUS`

Appending `|| true` to suppress a non-zero exit looks like a quick fix but resets
`PIPESTATUS` to `(0)` — the exit code of `true` — so the original java exit code is lost.
Always use `set +e` / `set -e` when you need both error suppression and `PIPESTATUS`.

### `PIPESTATUS` must be read as the very next statement

Any command between the pipe and the `PIPESTATUS` read overwrites the array:

```bash
java ... | while ...; done
echo "done"                    # overwrites PIPESTATUS!
JAVA_EXIT="${PIPESTATUS[0]}"   # always 0 now
```

### `${var,,}` is bash 4+ only — macOS ships bash 3.2

The lowercase expansion `${1,,}` does not exist in bash 3.2 (the version Apple ships
due to GPLv2 licensing). Use `tr` instead:

```bash
# BROKEN on macOS
local line="${1,,}"

# Works everywhere
local line
line="$(echo "$1" | tr "[:upper:]" "[:lower:]")"
```

### `wc -l` pads output with spaces on macOS

On macOS, `wc -l` right-aligns its output with leading spaces (e.g. `"       3"`).
Interpolating this directly into a string produces broken JSON or unexpected values.
Use `awk` for a clean integer on all platforms:

```bash
# BROKEN on macOS — produces "       3"
count=$(echo "$str" | tr ':' '\n' | wc -l | tr -d ' ')

# Works everywhere — produces "3"
count=$(echo "$str" | tr ':' '\n' | awk 'END{print NR}')
```

---

## BATS Tests

### Source only functions, not the full script

Sourcing the whole script for unit tests triggers the main logic (input validation,
java execution). Extract just the function definitions:

```bash
source_functions() {
    eval "$(sed -n '/^json_log()/,/^}/p; /^detect_level()/,/^}/p; /^emit_line()/,/^}/p' "$SCRIPT")"
}
```

### `$output` in BATS is a multiline string — iterate it line by line

Piping `$output` directly into `jq select(...)` fails when there are multiple JSON
lines, because `jq` receives them as one blob. Always iterate line by line:

```bash
# BROKEN — jq receives all lines as one blob, fails on line 2+
echo "$output" | jq -r 'select(.log.level == "ERROR") | .log.level'

# Correct
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    level="$(echo "$line" | jq -r '.log.level' 2>/dev/null)" || continue
    [[ "$level" == "ERROR" ]] && found=1
done <<< "$output"
```

### Stub `java` via a fake binary on `$PATH`

Integration tests that need to control java's output and exit code should inject a
fake binary rather than mocking at the shell-function level:

```bash
mkdir -p "$TEST_DIR/bin"
printf '#!/usr/bin/env bash\necho "liquibase failed"; exit 2\n' > "$TEST_DIR/bin/java"
chmod +x "$TEST_DIR/bin/java"
export PATH="$TEST_DIR/bin:$PATH"
```

This works because the script resolves `java` from `$PATH` at runtime.

### Always isolate tests with a `setup()`/`teardown()` temp directory

Each test gets a fresh `$TEST_DIR` via `mktemp -d` in `setup()`, torn down in
`teardown()`. This prevents JAR files, fake binaries, and env vars from leaking
between tests.

---

## GitHub Actions

### `action-junit-report` requires `checks: write` permission

The default `permissions: contents: read` is not enough. Add:

```yaml
permissions:
  contents: read
  checks: write
```

Without `checks: write`, the action fails with:
`Resource not accessible by integration (HttpError)`

### Gate `build-results` on all jobs, not just `build`

When adding new jobs (e.g. `shell-tests`), always add them to the `needs` list of
the sentinel job, otherwise a BATS failure does not block the merge:

```yaml
build-results:
  needs:
    - build
    - shell-tests
```

### Install platform-specific dependencies explicitly

BATS and `jq` are not pre-installed on all runners. Install them per OS:

```yaml
- name: Install dependencies (Ubuntu)
  if: runner.os == 'Linux'
  run: sudo apt-get install -y bats jq

- name: Install dependencies (macOS)
  if: runner.os == 'macOS'
  run: brew install bats-core jq
```

Note: the Ubuntu package is `bats`, the Homebrew formula is `bats-core`.

---

## Oracle JDBC Driver

### `ServiceLoader` auto-registration fails with custom classloaders

`ojdbc11` registers itself as a JDBC driver via `ServiceLoader` — this only works
when the JAR is on the **system classloader's** classpath. When Liquibase (or any
framework) uses its own internal classloader to load dependencies, `ServiceLoader`
for `java.sql.Driver` never runs, and `DriverManager.getConnection()` throws:

```
No suitable driver found for jdbc:oracle:thin:@//host:1521/SERVICE
```

This happens even when:
- The JAR is present and valid (correct size ~7MB)
- JDK version is compatible (11+)
- The URL format is correct (`@//host:port/service`)
- The JAR appears on the `-cp` classpath

**Fix:** force driver registration via the JDBC spec's built-in system property:

```bash
java -cp "$LIQUIBASE_CP" \
  -Djdbc.drivers=oracle.jdbc.OracleDriver \
  net.ct.LiquibaseRunner "$@"
```

`DriverManager` reads `-Djdbc.drivers` at initialisation and calls `Class.forName()`
directly, bypassing `ServiceLoader` entirely. This works regardless of classloader
structure.

### `ojdbc8` vs `ojdbc11` URL format

- `ojdbc8` requires the explicit `//` form: `jdbc:oracle:thin:@//host:1521/SERVICE`
- `ojdbc11` accepts both `@//host:1521/SERVICE` and `@host:1521/SERVICE`
- The error `No suitable driver found` from `ojdbc8` with `@host:1521/SERVICE` is
  misleading — the driver is present, it just rejects the URL as unrecognisable

### Dockerfile: verify downloaded JARs are valid

`curl -fsSL url > file.jar` writes error pages silently if the download fails.
Always use `-o` and verify size/type:

```dockerfile
RUN curl -fsSL https://nexus.example.com/.../ojdbc11-${VERSION}.jar \
      -o /opt/jboss/liquibase/bin/internal/lib/ojdbc11.jar && \
    ls -lh /opt/jboss/liquibase/bin/internal/lib/ojdbc11.jar
```

A valid `ojdbc11.jar` is ~7MB. An HTML error page will be a few KB.
