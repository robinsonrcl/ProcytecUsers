//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 20/12/22.
//

import Foundation
import Fluent

struct AddRolAndOthers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
        .field(User.v20221220.codigoconfirmacion, .string)
        .field(User.v20221220.phone, .string)
        .field(User.v20221220.phonecountry, .string)
        .field(User.v20221220.rol, .string)
        .field(User.v20221220.terminosdelservicio, .bool)
        .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
            .deleteField(User.v20221220.codigoconfirmacion)
            .deleteField(User.v20221220.phone)
            .deleteField(User.v20221220.phonecountry)
            .deleteField(User.v20221220.rol)
            .deleteField(User.v20221220.terminosdelservicio)
            .update()
    }
}
