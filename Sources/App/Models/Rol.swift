//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Fluent
import Vapor
import PostgresNIO

final class Rol: Model, Content {
  static let schema = Rol.v20230107.schemaName
    
  @ID
  var id: UUID?
    
  @Field(key: Rol.v20230107.name)
  var name: String
    
  @Field(key: Rol.v20230107.status)
  var status: Bool
  
  @Siblings(
    through: RolPermissionPivot.self,
    from: \.$rol,
    to: \.$permission)
  var permissions: [Permission]
    
    init() {}
    
    init(id: UUID? = nil,
         name: String,
         status: Bool = true) {
      self.name = name
      self.status = status
    }
    
}


