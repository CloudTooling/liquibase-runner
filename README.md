Liquibase Runner

This adds JSON logging around liquibase OSS.

Needs [liquibase](https://www.liquibase.com/) to run, it's not packaged into the runner!

Wraps liquibase logging into JSON, e.g. 

```bash
{"@timestamp":"2026-02-12T17:12:59+0100","level":"ERROR","message":"ERROR: Exception Primary Source:  Oracle Oracle Database 23ai Free Release 23.0.0.0.0 - Develop, Learn, and Run for Free"}
{"@timestamp":"2026-02-12T17:12:59+0100","level":"INFO","message":"Version 23.7.0.25.01"}
{"@timestamp":"2026-02-12T17:12:58.271365+01:00","@version":"1","message":"Command execution complete","logger_name":"liquibase.command","thread_name":"main","level":"INFO","level_value":20000}
{"@timestamp":"2026-02-12T17:12:59.913867+01:00","@version":"1","message":"Logging exception.","logger_name":"liquibase.command","thread_name":"main","level":"INFO","level_value":20000}
{"@timestamp":"2026-02-12T17:12:59+0100","level":"ERROR","message":"ERROR: Exception Details"}
{"@timestamp":"2026-02-12T17:12:59+0100","level":"ERROR","message":"ERROR: Exception Primary Class:  OracleDatabaseException"}
```

## Usage

1. Download liquibase and set `LIQUIBASE_HOME` environment variable to the folder
2. Download Wrapper Runner JAR from releases
3. Run `.bin/liquibase-runner.sh liquibase-runner.jar`