package net.ct;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

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
}