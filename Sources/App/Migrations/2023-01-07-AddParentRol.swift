//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Foundation
import Fluent

struct AddParentRol: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
        .field(User.v20230107.rolID, .uuid, .required, .references("rols", "id"))
        .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
        .deleteField(User.v20230107.rolID)
        .update()
    }
}
