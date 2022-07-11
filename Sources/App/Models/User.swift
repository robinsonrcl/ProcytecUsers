//
//  File.swift
//
//
//  Created by Robinson Cartagena on 12/05/22.
//

import Fluent
import Vapor
import PostgresNIO
import CloudKit

final class User: Model, Content {
    static let schema = User.v20220519.schemaName
    
    @ID
    var id: UUID?
    
    @Field(key: User.v20220519.name)
    var name: String
    
    @Field(key: User.v20220519.username)
    var username: String
    
    @Field(key: User.v20220519.password)
    var password: String
    
    @OptionalField(key: User.v20220519.siwaIdentifier)
    var siwaIdentifier: String?
    
    @Field(key: User.v20220519.email)
    var email: String
    
    @OptionalField(key: User.v20220519.profilePicture)
    var profilePicture: String?
    
    @OptionalField(key: User.v20220520.twitterURL)
    var twitterURL: String?
    
    init() {}
    
    init(id: UUID? = nil,
         name: String,
         username: String,
         password: String,
         siwaIdentifier: String? = nil,
         email: String,
         profilePicture: String? = nil,
         twitterURL: String? = nil) {
        self.name = name
        self.username = username
        self.password = password
        self.siwaIdentifier = siwaIdentifier
        self.email = email
        self.profilePicture = profilePicture
        self.twitterURL = twitterURL
    }

    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
    
    final class PublicV2: Content {
        var id: UUID?
        var name: String
        var username: String
        var twitterURL: String?
        
        init(id: UUID?,
             name: String,
             username: String,
             twitterURL: String? = nil) {
            self.id = id
            self.name = name
            self.username = username
            self.twitterURL = twitterURL
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
    
    func convertToPublicV2() -> User.PublicV2 {
      return User.PublicV2(
          id: id,
          name: name,
          username: username,
          twitterURL: twitterURL)
    }

}

extension EventLoopFuture where Value: User {
    func convertToPublic() -> EventLoopFuture<User.Public> {
        return self.map { user in
            return user.convertToPublic()
        }
    }
    
    func convertToPublicV2() -> EventLoopFuture<User.PublicV2> {
      return self.map { user in
        return user.convertToPublicV2()
      }
    }

}

extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
    
    func convertToPublicV2() -> [User.PublicV2] {
      return self.map { $0.convertToPublicV2() }
    }
}

extension EventLoopFuture where Value == Array<User> {
    func convertToPublic() -> EventLoopFuture<[User.Public]> {
        return self.map { $0.convertToPublic() }
    }
    
    func convertToPublicV2() -> EventLoopFuture<[User.PublicV2]> {
      return self.map { $0.convertToPublicV2() }
    }

}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

extension User: ModelSessionAuthenticatable {}

extension User: ModelCredentialsAuthenticatable {}
