package net.ct;

import liquibase.Liquibase;
import liquibase.database.Database;
import liquibase.database.DatabaseFactory;
import liquibase.database.jvm.JdbcConnection;
import liquibase.resource.FileSystemResourceAccessor;
import org.slf4j.bridge.SLF4JBridgeHandler;

import java.io.File;
import java.io.PrintStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
        // -------------------------------
        // 1) JUL -> SLF4J bridge for JSON logging
        java.util.logging.LogManager.getLogManager().reset();
        SLF4JBridgeHandler.install();

        // -------------------------------
        // 2) CLI arguments
        if (args.length < 1) {
            err.println("Usage: java -jar liquibase-json-demo.jar <changelog-file> [searchPath] [liquibase.properties]");
            return 1;
        }

        String changeLogFile = args[0];
        String searchPath = args.length >= 2 ? args[1] : null;
        String propertiesFile = args.length >= 3 ? args[2] : null;

        // Remove trailing slash
        if (searchPath != null && searchPath.endsWith("/")) {
            searchPath = searchPath.substring(0, searchPath.length() - 1);
        }

        // -------------------------------
        // 3) Optionally load liquibase.properties
        Properties props = new Properties();
        if (propertiesFile != null) {
            Path propsPath = Paths.get(propertiesFile);
            if (Files.exists(propsPath) && Files.isReadable(propsPath)) {
                props.load(Files.newInputStream(propsPath));
                out.println("Loaded properties from: " + propertiesFile);
            }
        }

        // CLI args override properties
        String dbUrl = props.getProperty("url");
        String dbUser = props.getProperty("username");
        String  dbPass = props.getProperty("password");

        // -------------------------------
        // 4) Does the changelog file exist? (check before DB connection to keep this testable)
        File f = (searchPath != null) ? new File(searchPath, changeLogFile) : new File(changeLogFile);
        if (!f.exists() || !f.canRead()) {
            err.println("ERROR: Changelog file does not exist or cannot be read: " + f.getAbsolutePath());
            return 2;
        }

        // -------------------------------
        // 5) Connect to the DB
        Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        Database database = DatabaseFactory.getInstance()
                .findCorrectDatabaseImplementation(new JdbcConnection(conn));

        // -------------------------------
        // 6) FileSystemResourceAccessor
        FileSystemResourceAccessor resourceAccessor = (searchPath != null)
                ? new FileSystemResourceAccessor(searchPath)
                : new FileSystemResourceAccessor();

        // -------------------------------
        // 7) Run Liquibase
        Liquibase liquibase = new Liquibase(changeLogFile, resourceAccessor, database);
        liquibase.update("");

        out.println("Liquibase update finished successfully.");
        return 0;
    }
}