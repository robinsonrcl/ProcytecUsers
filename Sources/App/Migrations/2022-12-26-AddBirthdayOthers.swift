//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 26/12/22.
//

import Foundation
import Fluent

struct AddBirthDayAndOthers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
        .field(User.v20221226.birthday, .date)
        .field(User.v20221226.address, .string)
        .field(User.v20221226.gustos, .string)
        .field(User.v20221226.landline, .string)
        .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(User.v20220519.schemaName)
        .deleteField(User.v20221226.birthday)
        .deleteField(User.v20221226.landline)
        .deleteField(User.v20221226.gustos)
        .deleteField(User.v20221226.address)
        .update()
    }
}
