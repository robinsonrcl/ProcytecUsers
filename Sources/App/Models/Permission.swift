//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Fluent
import Vapor
import PostgresNIO

final class Permission: Model, Content {
  static let schema = Permission.v20230107.schemaName
    
  @ID
  var id: UUID?
    
  @Field(key: Permission.v20230107.name)
  var name: String
    
  @Field(key: Permission.v20230107.status)
  var status: Bool
  
  @Siblings(
    through: RolPermissionPivot.self,
    from: \.$permission,
    to: \.$rol)
  var rols: [Rol]
    
    init() {}
    
    init(id: UUID? = nil,
         name: String,
         status: Bool = true) {
      self.name = name
      self.status = status
    }
}
