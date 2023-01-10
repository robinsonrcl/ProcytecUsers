//
//  File.swift
//
//
//  Created by Robinson Cartagena
//

import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws -> Void {
        try await database.schema(User.v20220519.schemaName)
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
    
    func revert(on database: Database) async throws -> Void {
        try await database.schema(User.v20220519.schemaName).delete()
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

extension User {
  enum v20221220 {
    static let rol = FieldKey(stringLiteral: "rol")
    static let phone = FieldKey(stringLiteral: "phone")
    static let terminosdelservicio = FieldKey(stringLiteral: "terminosdelservicio")
    static let codigoconfirmacion = FieldKey(stringLiteral: "codigoconfirmacion")
    static let phonecountry = FieldKey(stringLiteral: "phonecountry")
  }
}

extension User {
  enum v20221226 {
    static let birthday = FieldKey(stringLiteral: "birthday")
    static let gustos = FieldKey(stringLiteral: "gustos")
    static let address = FieldKey(stringLiteral: "address")
    static let landline = FieldKey(stringLiteral: "landline")
  }
}

extension User {
  enum v20230107 {
    static let rolID = FieldKey(stringLiteral: "rolID")
  }
}
