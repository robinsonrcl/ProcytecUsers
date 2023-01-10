//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Foundation
import Fluent

struct AddParentPermission: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Rol.v20230107.schemaName)
        .field(Rol.v20230107_2.permissionID, .uuid, .required, .references("permissions", "id"))
        .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Rol.v20230107.schemaName)
        .deleteField(Rol.v20230107_2.permissionID)
        .update()
    }
}
