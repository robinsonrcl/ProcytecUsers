//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 9/09/22.
//

import Graphiti
import Vapor

struct claveValor: Codable {
    let username: String
    let password: String
}

let schema = try! Schema<Resolver, Request> {
    Scalar(UUID.self)
    
    Type(User.self) {
        Field("id", at: \.id)
        Field("name", at: \.name)
        Field("username", at: \.username)
        Field("email", at: \.email)
        Field("profilePicture", at: \.profilePicture)
        Field("twitterURL", at: \.twitterURL)
    }
    
    Type(Token.self) {
        Field("id", at: \.id)
        Field("tokenString", at: \.value)
        Field("userID", at: \.user)
    }
    
    Query {
        Field("users", at: Resolver.getAllUsers) {
            Argument("limit", at: \.limit)
            Argument("offset", at: \.offset)
        }
    }
    
    Mutation {
        Field("login", at: Resolver.loginHandler) {
            Argument("username", at: \.username)
            Argument("password", at: \.password)
        }
    }

//    Field("createShow", at: Resolver.createShow) {
//        Argument("title", at: \.title)
//        Argument("releaseYear", at: \.releaseYear)
//    }
//        Field("updateShow", at: Resolver.updateShow) {
//            Argument("id", at: \.id)
//            Argument("title", at: \.title)
//            Argument("releaseYear", at: \.releaseYear)
//        }
//
//        Field("deleteShow", at: Resolver.deleteShow) {
//            Argument("id", at: \.id)
//        }
//
//        Field("createReview", at: Resolver.createReview) {
//            Argument("showID", at: \.showID)
//            Argument("title", at: \.title)
//            Argument("text", at: \.text)
//        }
//
//        Field("updateReview", at: Resolver.updateReview) {
//            Argument("id", at: \.id)
//            Argument("title", at: \.title)
//            Argument("text", at: \.text)
//        }
//
//        Field("deleteReview", at: Resolver.deleteReview) {
//            Argument("id", at: \.id)
//        }
//    }
}


