package net.ct;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LiquibaseRunnerTest {

    @Test
    void run_withTooFewArgs_returnsExitCode1_andPrintsUsageToErr() throws Exception {
        ByteArrayOutputStream outBuf = new ByteArrayOutputStream();
        ByteArrayOutputStream errBuf = new ByteArrayOutputStream();

        int code = LiquibaseRunner.run(
                new String[] { "only-one-arg" },
                new PrintStream(outBuf),
                new PrintStream(errBuf)
        );

        assertEquals(1, code);
        assertTrue(errBuf.toString().contains("Usage:"), "Expected usage message on stderr");
    }

    @Test
    void run_withMissingChangelog_returnsExitCode2(@TempDir Path tempDir) throws Exception {
        ByteArrayOutputStream outBuf = new ByteArrayOutputStream();
        ByteArrayOutputStream errBuf = new ByteArrayOutputStream();

        int code = LiquibaseRunner.run(
                new String[] {
                        "missing-changelog.xml",
                        "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1",
                        "sa",
                        "",
                        tempDir.toString()
                },
                new PrintStream(outBuf),
                new PrintStream(errBuf)
        );

        assertEquals(2, code);
        assertTrue(errBuf.toString().contains("Changelog file does not exist"), "Expected missing changelog error on stderr");
    }
}