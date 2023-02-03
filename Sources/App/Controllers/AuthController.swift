//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 26/05/22.
//

import Vapor
import Redis
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        
        let authGroup = routes.grouped("auth")
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = authGroup.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
    }
    
  func loginHandler(_ req: Request) async throws -> Token {
    let user = try req.auth.require(User.self)
    let id = user.id
    
    let usuario = try await User.query(on: req.db)
      .filter(\.$id == id!)
      .filter(\.$codigoconfirmacion == "Confirmado")
      .first()
      
    var token: Token? = nil
    
    if(usuario != nil){
      token = try Token.generate(for: user)
    }else{
      token = Token(value: "NOCONFIRMADO", userID: UUID.generateRandom())
    }
    try await token?.save(on: req.db)
    
    return token!
  }
}

struct AuthenticateData: Content {
  let token: String
}
