//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 8/01/23.
//

import Fluent

struct CreateToken: AsyncMigration {
  func prepare(on database: Database) async throws -> Void {
    try await database.schema(Token.v20230108.schemaName)
      .id()
      .field(Token.v20230108.value, .string, .required)
      .field(Token.v20230108.userID, .uuid, .required, .references("users", "id", onDelete: .cascade))
      .create()
  }

  func revert(on database: Database) async throws -> Void {
    try await database.schema(Token.v20230108.schemaName).delete()
  }
}

extension Token {
    enum v20230108 {
        static let schemaName = "tokens"
        
        static let id = FieldKey(stringLiteral: "id")
        static let value = FieldKey(stringLiteral: "value")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
