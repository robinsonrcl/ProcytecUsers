//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Fluent

struct CreateRol: AsyncMigration {
    func prepare(on database: Database) async throws -> Void {
        try await database.schema(Rol.v20230107.schemaName)
            .id()
            .field(Rol.v20230107.name, .string, .required)
            .field(Rol.v20230107.status, .bool, .required)
            .create()
    }
    
    func revert(on database: Database) async throws -> Void {
        try await database.schema(Rol.v20230107.schemaName).delete()
    }
}

extension Rol {
    enum v20230107 {
        static let schemaName = "rols"
        
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let status = FieldKey(stringLiteral: "status")
    }
}

extension Rol {
    enum v20230107_2 {
        static let permissionID = FieldKey(stringLiteral: "permissionID")
    }
}
