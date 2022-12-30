import Fluent
import FluentPostgresDriver
import Vapor
import Redis
import GraphQLKit
import GraphiQLVapor
import SotoS3

public func configure(_ app: Application) throws {
  
  app.aws.client = AWSClient(
                          credentialProvider:
                              .static( accessKeyId: Environment.get("BUCKET_ACCKEY")!,
                                       secretAccessKey: Environment.get("BUCKET_SECKEY")!),
                          httpClientProvider:
                              .shared(app.http.client.shared))

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
    app.migrations.add(AddTwitterURLToUser())
    app.migrations.add(AddRolAndOthers())
    app.migrations.add(AddBirthDayAndOthers())

    let redisHostname: String
    if let redisEnvironmentHostname = Environment.get("REDIS_HOSTNAME") {
      redisHostname = redisEnvironmentHostname
    } else {
      redisHostname = "localhost"
    }
    app.redis.configuration = try RedisConfiguration(hostname: redisHostname)
    
    try routes(app)

    try app.autoMigrate().wait()
    
    app.register(graphQLSchema: schema, withResolver: Resolver())
    
    if !app.environment.isRelease {
        app.enableGraphiQL()
    }
}
