package net.ct;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;

class LiquibaseCompatibilityIT {

    @ParameterizedTest(name = "{0}")
    @MethodSource("databases")
    void runsMigrationSuccessfully(String name, String url, String username, String password) throws Exception {
        Path tempDir = Files.createTempDirectory("compat-" + name + "-");
        try {
            try (InputStream is = getClass().getResourceAsStream("/db/changelog.xml")) {
                Files.copy(is, tempDir.resolve("changelog.xml"));
            }

            Path defaults = tempDir.resolve("defaults.properties");
            try (PrintWriter w = new PrintWriter(defaults.toFile())) {
                w.println("url=" + url);
                if (username != null) w.println("username=" + username);
                if (password != null) w.println("password=" + password);
                w.println("changeLogFile=changelog.xml");
                w.println("searchPath=" + tempDir.toAbsolutePath());
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ByteArrayOutputStream err = new ByteArrayOutputStream();
            int code = LiquibaseRunner.run(
                    new String[]{defaults.toAbsolutePath().toString()},
                    new PrintStream(out),
                    new PrintStream(err)
            );

            if (code != 0) {
                System.err.println("[" + name + "] stdout: " + out);
                System.err.println("[" + name + "] stderr: " + err);
            }
            assertEquals(0, code, "Migration failed for " + name + ": " + err);
        } finally {
            try (var stream = Files.walk(tempDir)) {
                stream.sorted(Comparator.reverseOrder())
                        .map(Path::toFile)
                        .forEach(File::delete);
            }
        }
    }

    static Stream<Arguments> databases() {
        List<Arguments> args = new ArrayList<>();

        String h2Url = "jdbc:h2:mem:" + UUID.randomUUID().toString().replace("-", "") + ";DB_CLOSE_DELAY=-1";
        args.add(Arguments.of("H2", h2Url, "sa", ""));

        String pgUrl = System.getenv("PG_URL");
        if (pgUrl != null) {
            args.add(Arguments.of("PostgreSQL", pgUrl, System.getenv("PG_USER"), System.getenv("PG_PASS")));
        }

        String mysqlUrl = System.getenv("MYSQL_URL");
        if (mysqlUrl != null) {
            args.add(Arguments.of("MySQL", mysqlUrl, System.getenv("MYSQL_USER"), System.getenv("MYSQL_PASS")));
        }

        return args.stream();
    }
}
