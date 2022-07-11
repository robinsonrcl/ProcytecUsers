import Fluent
import FluentPostgresDriver
import Vapor
import Redis

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let port: Int
    if let environmentPort = Environment.get("PORT") {
      port = Int(environmentPort) ?? 8081
    } else {
      port = 8081
    }
    app.http.server.configuration.port = port
    
    app.databases.use(.postgres(
      hostname: Environment.get("DATABASE_HOST") ?? "localhost",
      port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
      username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
      password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
      database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)

    app.migrations.add(CreateUser())

    let redisHostname: String
    if let redisEnvironmentHostname = Environment.get("REDIS_HOSTNAME") {
      redisHostname = redisEnvironmentHostname
    } else {
      redisHostname = "localhost"
    }
    app.redis.configuration = try RedisConfiguration(hostname: redisHostname)
    
    // register routes
    try routes(app)

    try app.autoMigrate().wait()
}
