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
        
        let basicMiddleware = User.authenticator()
        let basicAuthGroup = authGroup.grouped(basicMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        authGroup.post("authenticate", use: authenticate)
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return req.redis.set(RedisKey(token.tokenString), toJSON: token).transform(to: token)
    }
    
    func authenticate(_ req: Request) throws -> EventLoopFuture<User.Public> {
        
        let data = try req.content.decode(AuthenticateData.self)
        
        return req.redis.get(RedisKey(data.token), asJSON: Token.self).flatMap { token in
            
            guard let token = token else {
                return req.eventLoop.future(error: Abort(.unauthorized))
            }
            
            return User.query(on: req.db)
                .filter(\.$id == token.userID)
                .first()
                .unwrap(or: Abort(.internalServerError))
                .convertToPublic()
        }
    }
}

struct AuthenticateData: Content {
  let token: String
}
