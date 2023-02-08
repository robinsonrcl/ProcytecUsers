//
//  File.swift
//  
//
//  Created by Robinson Cartagena on 3/02/23.
//

import Vapor
import Smtp
import Fluent
import SotoSES
import SotoSNS

struct CustomersController: RouteCollection {
  let customerServiceURL: String
  
  init(customerServiceHostname: String) {
    customerServiceURL = "http://\(customerServiceHostname):8082"
  }
  
  func boot(routes: RoutesBuilder) throws {
    
    let customersGroup = routes.grouped("api","customers")
    
    //-------
    let customers = routes.grouped("api","customers")
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let customerProtected = customers.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    
    customerProtected.get("get",":page", ":size",use: getAllCustomers)
    customerProtected.get(":id", use: getCustomer)
    //-------
    
//    customersGroup.get(use: getAllCustomers)
    
  }
  
  func getAllCustomers(_ req: Request) async throws -> ClientResponse {
    let page = req.parameters.get("page", as: String.self)!
    let size = req.parameters.get("size", as: String.self)!
    
      return try await req.client.get("\(customerServiceURL)/customers/get/\(page)/\(size)")
  }
  
  func getCustomer(_ req: Request) async throws -> ClientResponse {
      let id = try req.parameters.require("id", as: UUID.self)
      return try await req.client.get("\(customerServiceURL)/customers/\(id)")
  }
  
}
