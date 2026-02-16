Liquibase Runner

This adds JSON logging around liquibase OSS.

Needs [liquibase](https://www.liquibase.com/) to run, it's not packaged into the runner!

Wraps liquibase logging into JSON, e.g.

```bash
{"@timestamp":"2026-02-16T10:34:45+0100","log":{"level":"INFO"},"message":"Using defaultsFile: liquibase.properties","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:45+0100","log":{"level":"INFO"},"message":"Using changeLogFile: changelog.yaml","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"SLF4J(W): Class path contains multiple SLF4J providers.","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"SLF4J(W): Found provider [ch.qos.logback.classic.spi.LogbackServiceProvider@26275bef]","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"SLF4J(W): Found provider [org.slf4j.nop.NOPServiceProvider@7690781]","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"SLF4J(W): See https://www.slf4j.org/codes.html#multiple_bindings for an explanation.","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"Found logback-core version 1.5.31","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:46+0100","log":{"level":"INFO"},"message":"No custom configurators were discovered as a service.","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Trying to configure with ch.qos.logback.classic.util.DefaultJoranConfigurator","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Constructed configurator of type class ch.qos.logback.classic.util.DefaultJoranConfigurator","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Could NOT find resource [logback-test.xml]","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Found resource [logback.xml] at [jar:file:/opt/jboss/liquibase/bin/liquibase-runner.jar!/logback.xml]","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Scan attribute not set or set to unrecognized value.","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"Processing appender named [STDOUT]","ecs.version":"1.12.0","service.name":"liquibase"}
{"@timestamp":"2026-02-16T10:34:47+0100","log":{"level":"INFO"},"message":"About to instantiate appender of type [ch.qos.logback.core.ConsoleAppender]","ecs.version":"1.12.0","service.name":"liquibase"}
```

## Usage

1. Download liquibase and set `LIQUIBASE_HOME` environment variable to the folder
2. Download Wrapper Runner JAR from releases
3. Run `.bin/liquibase-runner.sh liquibase-runner.jar`
