//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 7/01/23.
//

import Vapor
import Fluent
import SotoSES

struct RolsController: RouteCollection {
  
  func boot(routes: RoutesBuilder) throws {

    let permissions = routes.grouped("permissions")
    let roles = routes.grouped("roles")
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let permissionsProtected = permissions.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    let rolesProtected = roles.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    
    //-----------
    permissions.get("getAll", use: getAllPermissions)
    
    permissionsProtected.post(use: createPermission)
    permissionsProtected.post("addpermissionstorol", use: addPermissionToRol)
    permissionsProtected.get("delete", ":permissionID", use: deletePermission)
    
    //-----------
    roles.get("getAll", use: getAllRols)
    
    rolesProtected.post(use: createRol)
    rolesProtected.get("delete",":rolID", use: deleteRol)
    rolesProtected.post("deletepermission", use: deletePermissionRol)
  }
  
  struct PermissionToRol: Content {
    var rol: UUID
    var permissions: [UUID]
  }
  
  func deletePermissionRol(_ req: Request) async throws -> Rol {
    let permissions = try req.content.decode(PermissionToRol.self)
    
    let arregloPermissions = try await Permission.query(on: req.db)
      .filter(\.$id ~~ permissions.permissions).all()
    
    let rol = (try await Rol.find(permissions.rol, on: req.db))!
    try await rol.$permissions.detach(arregloPermissions, on: req.db)
    
    try await rol.$permissions.load(on: req.db)
    
    return  rol
  }
  
  func deletePermission(_ req: Request) async throws -> HTTPStatus {
    let id = req.parameters.get("permissionID")
    
    let result: ()? = try await Permission.find(UUID(id!), on: req.db)?.delete(on: req.db)
    
    if(result != nil){
      return HTTPStatus.ok
    }
    return HTTPStatus.notFound
    
  }
  
  func deleteRol(_ req: Request) async throws -> HTTPStatus {
    let id = req.parameters.get("rolID")
    
    try await Rol.find(UUID(id!), on: req.db)?.delete(on: req.db)
    
    return HTTPStatus.ok
  }
  
  func addPermissionToRol(_ req: Request) async throws -> Rol {
    let permissions = try req.content.decode(PermissionToRol.self)
    
    let arregloPermissions = try await Permission.query(on: req.db)
      .filter(\.$id ~~ permissions.permissions).all()
    
    let rol = (try await Rol.find(permissions.rol, on: req.db))!
    
    try await rol.$permissions.attach(arregloPermissions, on: req.db)
    
    try await rol.$permissions.load(on: req.db)
    
    return  rol
  }
  
  func createPermission(_ req: Request) async throws -> Permission {
    let permission = try req.content.decode(Permission.self)
    
    try await permission.save(on: req.db)
    
    return permission
    
  }
  
  func createRol(_ req: Request) async throws -> Rol {
    let rol = try req.content.decode(Rol.self)
    
    try await rol.save(on: req.db)
    
    return rol
  }
  
  struct RolSinUUID: Content {
    var name: String
    var status: Bool
    var permissionID: String
  }
  
  func getAllRols(_ req: Request) async throws -> [Rol] {
    let roles = try await Rol.query(on: req.db).with(\.$permissions).all()
    
    return roles
  }
  
  func getAllPermissions(_ req: Request) async throws -> [Permission] {
    return try await Permission.query(on: req.db).sort(\.$name).all()
  }
}
