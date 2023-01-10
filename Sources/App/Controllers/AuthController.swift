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
      
//        authGroup.post("authenticate", use: authenticate)
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
//      _ = try await req.redis.set(RedisKey(token!.tokenString), toJSON: token)
    }else{
      token = Token(value: "NOCONFIRMADO", userID: UUID.generateRandom())
    }
      
    //return req.redis.set(RedisKey(token.tokenString), toJSON: token).transform(to: token)
//    return token!
      try await token?.save(on: req.db)
    
    return token!
    }
    
//    func authenticate(_ req: Request) throws -> EventLoopFuture<User.Public> {
//
//        let data = try req.content.decode(AuthenticateData.self)
//
//        return req.redis.get(RedisKey(data.token), asJSON: Token.self).flatMap { token in
//
//            guard let token = token else {
//                return req.eventLoop.future(error: Abort(.unauthorized))
//            }
//
//            return User.query(on: req.db)
//                .filter(\.$id == token.userID)
//                .first()
//                .unwrap(or: Abort(.internalServerError))
//                .convertToPublic()
//        }
//    }
}

struct AuthenticateData: Content {
  let token: String
}
