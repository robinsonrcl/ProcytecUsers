//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 8/01/23.
//

import Fluent

// 1
struct CreateRolPermissionPivot: AsyncMigration {
  func prepare(on database: Database) async throws -> Void {
    try await database.schema(CreateRolPermissionPivot.v20230108.schemaName)
      .id()
      .field(CreateRolPermissionPivot.v20230108.rolID, .uuid, .required, .references("rols", "id", onDelete: .cascade))
      .field(CreateRolPermissionPivot.v20230108.permissionID, .uuid, .required, .references("permissions", "id", onDelete: .cascade))
      .create()
  }
  
  // 7
  func revert(on database: Database) async throws -> Void {
    try await database.schema(CreateRolPermissionPivot.v20230108.schemaName).delete()
  }
}

extension CreateRolPermissionPivot {
    enum v20230108 {
        static let schemaName = "rol-permission-pivot"
        
        static let id = FieldKey(stringLiteral: "id")
        static let rolID = FieldKey(stringLiteral: "rolID")
        static let permissionID = FieldKey(stringLiteral: "permissionID")
    }
}
