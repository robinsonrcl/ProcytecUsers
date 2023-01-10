//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 8/01/23.
//

import Fluent
import Foundation

// 1
final class RolPermissionPivot: Model {
  static let schema = "rol-permission-pivot"
  
  // 2
  @ID
  var id: UUID?
  
  // 3
  @Parent(key: "rolID")
  var rol: Rol
  
  @Parent(key: "permissionID")
  var permission: Permission
  
  // 4
  init() {}
  
  // 5
  init(
    id: UUID? = nil,
    rol: Rol,
    permission: Permission
  ) throws {
    self.id = id
    self.$rol.id = try rol.requireID()
    self.$permission.id = try permission.requireID()
  }
}
