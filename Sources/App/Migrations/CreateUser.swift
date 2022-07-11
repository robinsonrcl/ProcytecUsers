//
//  File.swift
//
//
//  Created by Robinson Cartagena on 12/05/22.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20220519.schemaName)
            .id()
            .field(User.v20220519.name, .string, .required)
            .field(User.v20220519.username, .string, .required)
            .field(User.v20220519.password, .string, .required)
            .field(User.v20220519.siwaIdentifier, .string)
            .field(User.v20220519.email, .string, .required)
                .field(User.v20220519.profilePicture, .string)
                .unique(on: User.v20220519.email)
                .unique(on: User.v20220519.username)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.v20220519.schemaName).delete()
    }
}

extension User {
    enum v20220519 {
        static let schemaName = "users"
        
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
        static let siwaIdentifier = FieldKey(stringLiteral: "siwaIdentifier")
        static let email = FieldKey(stringLiteral: "email")
        static let profilePicture = FieldKey(stringLiteral: "profilePicture")
    }
}

extension User {
    enum v20220520 {
        static let twitterURL = FieldKey(stringLiteral: "twitterURL")
    }
}
