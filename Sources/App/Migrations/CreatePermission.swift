//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Fluent

struct CreatePermission: AsyncMigration {
    func prepare(on database: Database) async throws -> Void {
        try await database.schema(Permission.v20230107.schemaName)
            .id()
            .field(Permission.v20230107.name, .string, .required)
            .field(Permission.v20230107.status, .bool, .required)
            .create()
    }
    
    func revert(on database: Database) async throws -> Void {
        try await database.schema(Permission.v20230107.schemaName).delete()
    }
}

extension Permission {
    enum v20230107 {
        static let schemaName = "permissions"
        
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let status = FieldKey(stringLiteral: "status")
    }
}
