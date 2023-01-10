import Graphiti
import Vapor
import Redis

struct PaginationArguments: Codable {
    let limit: Int
    let offset: Int
}

struct User2: Codable {
    let username: String
    let password: String
}

final class Resolver {
    
    func getAllUsers(request: Request, arguments: PaginationArguments) throws -> EventLoopFuture<[User]> {
        User.query(on: request.db)
            .limit(arguments.limit)
            .offset(arguments.offset)
            .all()
    }
    
    func loginHandler(req: Request, arguments: User2) throws -> EventLoopFuture<Token> {
        
        
//        let user2 = User(id: UUID("838E8808-59C4-4B0D-A3D2-E1841EA3B5DC"),
//                        name: "xx",
//                        username: arguments.username,
//                        password: arguments.password,
//                        email: "xxx")
        
        let user = try req.auth.require(User.self)
        
        let token = try Token.generate(for: user)
        
        return req.redis.set(RedisKey(token.value), toJSON: token).transform(to: token)
    }
    
}

