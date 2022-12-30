//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 5/10/22.
//

import Fluent

struct AddTwitterURLToUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20220519.schemaName)
            .field(User.v20220520.twitterURL, .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20220519.schemaName)
            .deleteField(User.v20220520.twitterURL)
            .update()
    }
}
