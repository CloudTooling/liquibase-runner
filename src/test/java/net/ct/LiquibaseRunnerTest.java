package net.ct;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class LiquibaseRunnerTest {

    @Test
    void run_withTooFewArgs_returnsExitCode1_andPrintsUsageToErr() throws Exception {
        ByteArrayOutputStream outBuf = new ByteArrayOutputStream();
        ByteArrayOutputStream errBuf = new ByteArrayOutputStream();

        int code = LiquibaseRunner.run(
                new String[]{},
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
        PrintWriter propFile = new PrintWriter(tempDir.toString() + File.separator + "defaults.properties");
        propFile.write("url");
        int code = LiquibaseRunner.run(
                new String[]{
                        ".",
                        "missing-changelog.xml",
                },
                new PrintStream(outBuf),
                new PrintStream(errBuf)
        );

        assertEquals(2, code);
        assertTrue(errBuf.toString().contains("Read defaultsFile error: . (Is a directory)"), "Expected missing error for defaultsFile");
    }
}
