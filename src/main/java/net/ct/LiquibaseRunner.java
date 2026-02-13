package net.ct;

import liquibase.Contexts;
import liquibase.LabelExpression;
import liquibase.Liquibase;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.exception.LiquibaseException;
import liquibase.resource.FileSystemResourceAccessor;
import liquibase.resource.ResourceAccessor;
import org.slf4j.bridge.SLF4JBridgeHandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

public class LiquibaseRunner {

    public static void main(String[] args) throws Exception {
        int exitCode = run(args, System.out, System.err);
        if (exitCode != 0) {
            System.exit(exitCode);
        }
    }

    static int run(String[] args, PrintStream out, PrintStream err) throws Exception {
        int startArgs = 0;
        // -------------------------------
        // 1) JUL -> SLF4J bridge for JSON logging
        java.util.logging.LogManager.getLogManager().reset();
        SLF4JBridgeHandler.install();
        if (args.length >= 1 && args[0].contains(".jar")) {
            startArgs = 1;
        }

        // -------------------------------
        // 2) CLI arguments
        if (args.length < startArgs + 1) {
            err.println("Usage: java -jar liquibase-json-demo.jar <defaultsFile> [changeLogFile]");
            return 1;
        }

        String defaultsFile = args[startArgs];
        out.println("Using defaultsFile: " + defaultsFile);
        String changeLogFile = args.length >= startArgs + 2 ? args[startArgs + 1] : null;
        out.println("Using changeLogFile: " + changeLogFile);

        // -------------------------------
        // 3) load defaults

        File file = new File(defaultsFile);
        if (!file.exists()) {
            err.println("Defaults file not found: " + defaultsFile);
            System.exit(2);
        }
        try {
            // 1️⃣ Load properties
            Properties props = new Properties();
            try (FileInputStream fis = new FileInputStream(file)) {
                props.load(fis);
            }

            // 2️⃣ Resolve env variables in property values
            for (String key : props.stringPropertyNames()) {
                String value = props.getProperty(key);
                props.setProperty(key, resolveEnvVars(value));
            }

            // 3️⃣ Extract required props
            String url = props.getProperty("url");
            String username = props.getProperty("username");
            String password = props.getProperty("password");
            if (changeLogFile == null) {
                changeLogFile = props.getProperty("changeLogFile");
            }
            String searchPath = props.getProperty("searchPath");
            String contexts = props.getProperty("contexts", "");
            String labels = props.getProperty("labels", "");

            if (url == null || changeLogFile == null) {
                err.println("Properties 'url' and 'changeLogFile' are required");
                System.exit(3);
            }

            // 4️⃣ Open JDBC connection
            try (Connection conn = DriverManager.getConnection(url, username, password)) {

                Database database = DatabaseFactory.getInstance()
                        .findCorrectDatabaseImplementation(new JdbcConnection(conn));

                // Optional: table names
                String changelogTable = props.getProperty("databaseChangeLogTableName");
                String changelogLockTable = props.getProperty("databaseChangeLogLockTableName");
                if (changelogTable != null) database.setDatabaseChangeLogTableName(changelogTable);
                if (changelogLockTable != null) database.setDatabaseChangeLogLockTableName(changelogLockTable);

                // 5️⃣ ResourceAccessor (support searchPath)
                ResourceAccessor resourceAccessor;
                if (searchPath != null) {
                    resourceAccessor = new FileSystemResourceAccessor(searchPath);
                } else {
                    resourceAccessor = new FileSystemResourceAccessor();
                }

                // 6️⃣ Create Liquibase
                Liquibase liquibase = new Liquibase(changeLogFile, resourceAccessor, database);

                // 7️⃣ Run update with contexts/labels
                liquibase.update(new Contexts(contexts), new LabelExpression(labels));

                System.exit(0); // success
            }

        } catch (IOException e) {
            err.println("Failed to read defaultsFile: " + e.getMessage());
            System.exit(4);
        } catch (LiquibaseException e) {
            err.println("Liquibase error" + e.getMessage());
            System.exit(5);
        } catch (Exception e) {
            err.println("Unknown error" + e.getMessage());
            System.exit(6);
        }
        return 0;
    }

    /**
     * Resolve environment variables in the form ${VAR}
     */
    private static String resolveEnvVars(String value) {
        if (value == null) return null;
        StringBuilder sb = new StringBuilder();
        int i = 0;
        while (i < value.length()) {
            int start = value.indexOf("${", i);
            if (start == -1) {
                sb.append(value.substring(i));
                break;
            }
            sb.append(value, i, start);
            int end = value.indexOf("}", start);
            if (end == -1) {
                sb.append(value.substring(start));
                break;
            }
            String varName = value.substring(start + 2, end);
            String varValue = System.getenv(varName);
            if (varValue != null) {
                sb.append(varValue);
            } else {
                sb.append(""); // missing env var = empty
            }
            i = end + 1;
        }
        return sb.toString();
    }
}