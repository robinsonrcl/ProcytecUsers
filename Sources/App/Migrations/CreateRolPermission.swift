//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 11/01/23.
//

import Foundation
import Fluent
import Vapor

struct CreateAdminRolPermission: AsyncMigration {
  func prepare(on database: Database) async throws -> Void {
    var passwordHash = ""
    
    //--- Crear permissions y rol
    let permissionAll = Permission(name: "all-all", status: true)
    try await permissionAll.save(on: database)
    
    let permissionAccessCrmPrincipal = Permission(name: "access-crmprincipal", status: true)
    try await permissionAccessCrmPrincipal.save(on: database)
    
    let rolAdmin = Rol(name: "Admin", status: true)
    try await rolAdmin.save(on: database)
    
    let rolComercial = Rol(name: "Comercial", status: true)
    try await rolComercial.save(on: database)
    
    try await rolAdmin.$permissions.attach(permissionAll, on: database)
    try await rolAdmin.$permissions.attach(permissionAccessCrmPrincipal, on: database)
    try await rolComercial.$permissions.attach(permissionAccessCrmPrincipal, on: database)
    //---
    
    do {
      let pass = Environment.get("PASSWORD_TEMP")
      passwordHash = try Bcrypt.hash(pass!)
    }catch {
      
    }
    
    var fechaBirthday = Date()
    let isoDate = "1900-01-01"
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: isoDate) {
      fechaBirthday = date
    }
    
    let user = User(
                    name: "Admin",
                    username: "robinsonrcl@gmail.com",
                    password: passwordHash,
                    email: "robinsonrcl@gmail.com",
                    terminosdelservicio: true,
                    rol: "Comercial",
                    phonecountry: "(+57)",
                    phone: "318-599-0659",
                    codigoconfirmacion: "Confirmado",
                    birthday: fechaBirthday,
                    address: "",
                    landline: "",
                    gustos: "",
                    rolID: rolAdmin.id!)
    
    try await user.save(on: database)
    
  }

  func revert(on database: Database) async throws {
    try await User.query(on: database)
      .filter(\.$username == "admin")
      .delete()
    
    try await Rol.query(on: database)
      .filter(\.$name ~~ ["Comercial", "Admin"])
      .delete()
    
    try await Permission.query(on: database)
      .filter(\.$name ~~ ["all-all","access-crmprincipal"])
      .delete()
    

    
  }
}
