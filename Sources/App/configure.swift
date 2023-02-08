import Fluent
import FluentPostgresDriver
import Vapor
import Redis
import GraphQLKit
import GraphiQLVapor
import SotoS3

public func configure(_ app: Application) throws {
  app.aws.client = AWSClient(
                        credentialProvider: .static( accessKeyId: Environment.get("USERAWS_ACCKEY")!,
                                                          secretAccessKey: Environment.get("USERAWS_SECKEY")!),
                        httpClientProvider: .shared(app.http.client.shared))
  
  app.routes.defaultMaxBodySize = "2mb"
  let corsConfiguration = CORSMiddleware.Configuration(
      
      allowedOrigin:.any(["http://localhost:5173",
                          "https://conecta.procytec.com.co"]),
      allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
      allowedHeaders: [.accept,
                       .authorization,
                       .contentType,
                       .origin,
                       .xRequestedWith,
                       .userAgent,
                       .accessControlAllowOrigin,
                       .accessControlAllowHeaders],
      allowCredentials: true
  )
  let cors = CORSMiddleware(configuration: corsConfiguration)
  // cors middleware should come before default error middleware using `at: .beginning`
  app.middleware.use(cors, at: .beginning)

  let port: Int
  if let environmentPort = Environment.get("PORT") {
    port = Int(environmentPort) ?? 8083
  } else {
    port = 8083
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
  app.migrations.add(CreateRol())
  app.migrations.add(AddParentRol())
  app.migrations.add(CreatePermission())
  app.migrations.add(AddParentPermission())
  app.migrations.add(CreateToken())
  app.migrations.add(CreateRolPermissionPivot())

  app.databases.middleware.use(UserMiddleware(), on: .psql)
  app.logger.logLevel = .debug

  try app.autoMigrate().wait()
  
  try routes(app)
}
