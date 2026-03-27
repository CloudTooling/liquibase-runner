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

```text
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

---

## Liquibase Version Compatibility

### `FileSystemResourceAccessor` was deprecated in v4.17, removed in v5

Use `DirectoryResourceAccessor(Path)` instead — it exists in Liquibase 4.13+ and v5
with the same constructor signature, giving a single JAR that works with both:

```java
// Before (broken on v5)
new FileSystemResourceAccessor(searchPath)   // String constructor
new FileSystemResourceAccessor()             // no-arg

// After (works on v4.13+ and v5)
new DirectoryResourceAccessor(new File(searchPath).toPath())
new DirectoryResourceAccessor(new File(".").toPath())
```

### Liquibase 5 requires Java 17 as a minimum runtime

Compiling with `maven.compiler.target=11` produces class files that Liquibase 5 itself
cannot load (it ships Java-17-compiled classes). Set `source`/`target` to 17 when
targeting v5 compatibility.

### Test against multiple Liquibase versions via `-Dliquibase.version=X.Y.Z`

Because `liquibase-core` is `provided`, overriding the property at build time
recompiles and reruns tests against a different runtime without any code changes:

```bash
mvn verify -Dliquibase.version=4.27.0
mvn verify -Dliquibase.version=5.0.2
```

---

## Shaded JAR

### Include ALL transitives of embedded libraries explicitly

The Maven shade plugin `<artifactSet><includes>` list is not transitive — you must
list every JAR you want bundled, including the transitive dependencies of your direct
includes. Missing one causes `ClassNotFoundException` at runtime only when the JAR is
executed standalone (Maven's test classpath fills the gap during `mvn test`, hiding
the problem).

Example: `logback-ecs-encoder` requires `ecs-logging-core`:

```xml
<includes>
    <include>co.elastic.logging:logback-ecs-encoder</include>
    <include>co.elastic.logging:ecs-logging-core</include>  <!-- must be explicit -->
</includes>
```

### `shadedArtifactAttached=true` + `finalName` produces two output files

- `target/liquibase-runner.jar` — the shaded JAR, named by `finalName`
- `target/liquibase-runner-{version}-with-logging.jar` — the same JAR, attached as a
  secondary Maven artifact with the classifier for install/deploy

The file used by the shell wrapper and shipped in releases is `target/liquibase-runner.jar`.

### `System.exit` must not be called inside `run()` — only in `main()`

Calling `System.exit(0)` inside the static `run()` method kills the JVM when tests
invoke `run()` directly, aborting the entire Maven process. Move all `System.exit`
calls to `main()`:

```java
// main() — always call System.exit for clean JVM shutdown (prevents JDBC threads
// from keeping the process alive)
public static void main(String[] args) throws Exception {
    int exitCode = run(args, System.out, System.err);
    System.exit(exitCode);
}

// run() — never calls System.exit; just returns an int
```

---

## Integration Tests (Java)

### Use `maven-failsafe-plugin` for `*IT.java` classes

Surefire skips `*IT.java` by default; Failsafe picks them up during `integration-test`
and `verify`. Add both goals so a test failure actually fails the build:

```xml
<plugin>
    <artifactId>maven-failsafe-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
                <goal>verify</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Inject DB connection details via env vars for optional databases

H2 always runs (in-memory, no service needed). PostgreSQL and MySQL are skipped
locally but active in CI, controlled purely by env vars — no test annotations needed:

```java
static Stream<Arguments> databases() {
    List<Arguments> args = new ArrayList<>();
    args.add(Arguments.of("H2", "jdbc:h2:mem:" + UUID.randomUUID() + "...", "sa", ""));
    String pgUrl = System.getenv("PG_URL");
    if (pgUrl != null) args.add(Arguments.of("PostgreSQL", pgUrl, ...));
    String mysqlUrl = System.getenv("MYSQL_URL");
    if (mysqlUrl != null) args.add(Arguments.of("MySQL", mysqlUrl, ...));
    return args.stream();
}
```

---

## GitHub Actions (Compatibility Workflow)

### Inline heredoc POMs are corrupted by YAML indentation

Writing a Maven POM inside a `run: |` block via heredoc is fragile: YAML strips the
common indentation from all lines, which can mis-format or corrupt the XML. Commit the
POM as a file and reference it directly:

```yaml
# Fragile — YAML indentation mangling
- run: |
    cat > /tmp/pom.xml << 'EOF'
    <project>
      ...
    EOF
    mvn -f /tmp/pom.xml ...

# Correct — file committed to .github/
- run: |
    mvn -f .github/liq-compat-deps.xml \
      -Dliquibase.compat.version=${{ matrix.liquibase-version }} \
      dependency:copy-dependencies -DoutputDirectory=liquibase-home/lib
```

### `output=$(failing_command)` silently aborts the step under `set -e`

GitHub Actions runs bash with `-eo pipefail`. If a command captured in `$()` exits
non-zero, the step exits immediately — before printing `$output` — so the error
message is never shown. Use `set +e` / `tee` to a file instead:

```bash
# Broken — error output is swallowed on failure
output=$(./wrapper.sh ... 2>&1)
echo "$output"   # never reached if wrapper exits non-zero

# Correct — output is always visible in real time; exit code captured separately
local jar_exit
set +e
./wrapper.sh ... 2>&1 | tee output.log
jar_exit="${PIPESTATUS[0]}"
set -e
```

### `dependency:copy-dependencies -DincludeArtifactIds=X` does NOT follow transitives

The `includeArtifactIds` filter applies to the already-resolved flat dependency set,
not the tree. Specifying `liquibase-core` only copies `liquibase-core.jar`, not
`snakeyaml` or other transitives. To get the full runtime set for a single artifact,
use a dedicated minimal POM where it is `compile`-scoped and run
`dependency:copy-dependencies` without filters.
