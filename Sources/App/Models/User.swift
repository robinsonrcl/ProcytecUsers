//
//  File.swift
//
//
//  Created by Robinson Cartagena on 12/05/22.
//

import Fluent
import Vapor
import PostgresNIO

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
  
  @Field(key: User.v20221220.terminosdelservicio)
  var terminosdelservicio: Bool
  
  @Field(key: User.v20221220.rol)
  var rol: String
  
  @Field(key: User.v20221220.phonecountry)
  var phonecountry: String
  
  @Field(key: User.v20221220.phone)
  var phone: String
  
  @Field(key: User.v20221220.codigoconfirmacion)
  var codigoconfirmacion: String
  
  @Field(key: User.v20221226.address)
  var address: String
  
  @Field(key: User.v20221226.landline)
  var landline: String
  
  @Field(key: User.v20221226.gustos)
  var gustos: String
  
  @Field(key: User.v20221226.birthday)
  var birthday: Date
  
  @Parent(key: User.v20230107.rolID)
  var roles: Rol
    
    init() {}
    
    init(id: UUID? = nil,
         name: String,
         username: String,
         password: String,
         siwaIdentifier: String? = nil,
         email: String,
         profilePicture: String? = nil,
         twitterURL: String? = nil,
         terminosdelservicio: Bool = false,
         rol: String = "usuariofinal",
         phonecountry: String = "",
         phone: String = "",
         codigoconfirmacion: String = "",
         birthday: Date = Date(rfc1123: "01/01/1900")!,
         address: String = "",
         landline: String = "",
         gustos: String = "",
         rolID: Rol.IDValue) {
        self.name = name
        self.username = username
        self.password = password
        self.siwaIdentifier = siwaIdentifier
        self.email = email
        self.profilePicture = profilePicture
        self.twitterURL = twitterURL
      self.codigoconfirmacion = codigoconfirmacion
      self.terminosdelservicio = terminosdelservicio
      self.phone = phone
      self.phonecountry = phonecountry
      self.rol = rol
      self.gustos = gustos
      self.address = address
      self.birthday = birthday
      self.landline = landline
      self.$roles.id = rolID
    }

    final class Public: Content {
      var id: UUID?
      var name: String
      var username: String
      var phone: String
      var phonecountry: String
      var rol: String
      var twitterURL: String
      var birthday: String
      var gustos: String
      var address: String
      var landline: String
      var terminosdelservicio: Bool
      var roles: Rol
        
      init(id: UUID?,
           name: String,
           username: String,
           phone: String,
           phonecountry: String,
           rol: String,
           twitterURL: String,
           birthday: String,
           gustos: String,
           address: String,
           landline: String,
           terminosdelservicio: Bool,
           roles: Rol) {
            self.id = id
            self.name = name
            self.username = username
            self.phone = phone
            self.phonecountry = phonecountry
            self.rol = rol
            self.twitterURL = twitterURL
            self.birthday = birthday
            self.gustos = gustos
            self.address = address
            self.landline = landline
        self.terminosdelservicio = terminosdelservicio
        self.roles = roles
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
        return User.Public(
          id: id,
          name: name,
          username: username,
          phone: phone,
          phonecountry: phonecountry,
          rol: rol,
          twitterURL: twitterURL ?? "",
          birthday: birthday.rfc1123,
          gustos: gustos,
          address: address,
          landline: landline,
          terminosdelservicio: terminosdelservicio,
          roles: roles
        )
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
