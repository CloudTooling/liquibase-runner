package net.ct;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.OutputStreamAppender;
import ch.qos.logback.core.read.ListAppender;
import co.elastic.logging.logback.EcsEncoder;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;

import static org.junit.jupiter.api.Assertions.*;

class LogbackJsonTest {

    @Test
    void logShouldProduceValidEcsJson() throws Exception {

        // Prepare output stream to capture encoded JSON
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

        EcsEncoder encoder = new EcsEncoder();
        encoder.start();

        OutputStreamAppender appender = new OutputStreamAppender();
        appender.setEncoder(encoder);
        appender.setOutputStream(outputStream);
        appender.start();

        Logger logger = (Logger) LoggerFactory.getLogger("test");
        logger.addAppender(appender);

        // Log message
        String testMessage = "Hello ECS JSON";
        logger.info(testMessage);

        // Get actual JSON output
        String jsonString = outputStream.toString().trim();

        assertFalse(jsonString.isEmpty(), "No JSON output captured");

        // Parse JSON
        ObjectMapper mapper = new ObjectMapper();
        JsonNode json = mapper.readTree(jsonString);

        // ECS uses flattened fields
        assertTrue(json.has("@timestamp"));
        assertTrue(json.has("log.level"));
        assertEquals("INFO", json.get("log.level").asText());
        assertEquals(testMessage, json.get("message").asText());
        assertTrue(json.has("ecs.version"));
    }
}