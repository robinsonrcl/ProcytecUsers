import Fluent
import Vapor

func routes(_ app: Application) throws {
  let customersHostname: String
  
  if let customers = Environment.get("CUSTOMERS_HOSTNAME") {
      customersHostname = customers
  } else {
      customersHostname = "localhost"
  }
  
  try app.register(collection: RolsController())
  try app.register(collection: UsersController())
  try app.register(collection: AuthController())
  try app.register(collection: CustomersController(customerServiceHostname: customersHostname))
}
