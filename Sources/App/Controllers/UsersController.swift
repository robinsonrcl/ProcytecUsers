import Vapor
import Fluent
import SotoSES

struct UsersController: RouteCollection {
  
  let imageFolder = "ProfilePictures/"
  
  func boot(routes: RoutesBuilder) throws {
      
    let usersGroup = routes.grouped("users")
    
    usersGroup.post("update",  use: updateUser)
    usersGroup.get(use: getAllHandler)
    usersGroup.get(":userID", use: getHandler)
    usersGroup.get("getuser",":username", use: getUser)
    usersGroup.post(use: createHandler)
    usersGroup.get("validaremail",":email", use: getValidarEmail)
    usersGroup.get("resendcode", ":userID", use: resendCode)
    usersGroup.get("confirmregister", ":userID", ":codigo", use: confirmRegister)
    
    let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
    let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/"))
//    let protectedRoutesCursos = protectedRoutes.grouped("api", "cursos")
    
//    protectedRoutes.post("users","upload", use: addProfilePicture)
//    protectedRoutes.on(.POST, "users", ":userID", "addProfilePicture", body: .collect(maxSize: "10mb"), use: addProfilePicture)
  }
  
//  func addProfilePicture(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
//        let data = try req.content.decode(ImageUploadData.self)
//        return User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
//          let userID: UUID
//          do {
//            userID = try user.requireID()
//          } catch {
//            return req.eventLoop.future(error: error)
//          }
//          let name = "\(userID)-\(UUID()).jpg"
//          let path = req.application.directory.workingDirectory + imageFolder + name
//          user.profilePicture = name
//
//          return req.fileio.writeFile(.init(data: data.picture), at: path).flatMap {
//
//            return req.content.
//          }
//        }
//      }
  
  struct RespuestaBool: Content {
    var respuesta: Bool = false
  }
  
  func confirmRegister(_ req: Request) async throws -> RespuestaBool {
    let id = try UUID(req.parameters.require("userID"))!
    let codigo = try req.parameters.require("codigo")
    
    let user = try await User.query(on: req.db)
      .filter(\.$id == id)
      .filter(\.$codigoconfirmacion == codigo)
      .first()
    
    var respuesta = RespuestaBool()
    
    if(user != nil){
      
      user?.codigoconfirmacion = "Confirmado"
      _ = try await user?.save(on: req.db)
      
      respuesta.respuesta = true
    }else{
      respuesta.respuesta = false
    }
    
    return respuesta
    
  }
  
  func resendCode(_ req: Request) async throws -> HTTPStatus {
    
    let id = req.parameters.get("userID")
    
    let user = try await User.find(req.parameters.get("userID"), on: req.db)!
    let code = String(Int.random(in: 100000...999999))
    
    user.codigoconfirmacion = code
    
    try await user.save(on: req.db)
    
    let emailData = EmailData(
      address: user.email,
      subject: "Código confirmación Bitacora Fluvial: \(code)",
      message: "Por favor utilice este código para confirmar su registro en nuestra plataforma Bitacora Fluvial: \(code) ")
    
    _ = try await sendEmail(emailData: emailData, req: req)
    
    return HTTPStatus.ok
    
  }
  
  func getValidarEmail(_ req: Request) async throws ->  RespuestaBool {
    var correo = req.parameters.get("email")!
    
    let usuario = try await User.query(on: req.db)
      .filter(\.$email == correo)
      .first()
    
    var result = RespuestaBool()
    
    if(usuario != nil){
      result = RespuestaBool(respuesta: true)
    }else{
      result = RespuestaBool(respuesta: false)
    }
      
    return result
  }

  func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
    User.query(on: req.db).all().convertToPublic()
  }

  func getUser(_ req: Request) async throws -> User.Public {
    let username = req.parameters.get("username", as: String.self)!
    
    let user = try await User.query(on: req.db).filter(\.$username == username).first()
    
    if(user != nil){
      return (user?.convertToPublic())!
    }else{
      let idTmp = UUID.generateRandom()
      let user = User.Public(id: idTmp,
                             name: "NA",
                             username: "",
                             phone: "",
                             phonecountry: "",
                             rol: "",
                             twitterURL: "",
                             birthday: "",
                             gustos: "",
                             address: "",
                             landline: "",
                             terminosdelservicio: false)
      return user
    }
  }
  
  func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
    User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).convertToPublic()
  }
  
  func updateUser(_ req: Request) async throws -> User.Public {
    let user = try req.content.decode(CreateUserData.self)
    
    let updateUser = try await User.find(UUID(user.id), on: req.db)!
    
    var fechaBirthDay = Date()
    
    let isoDate = user.birthday
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: isoDate) {
      fechaBirthDay = date
    }
    
    updateUser.name = user.name
    updateUser.phone = user.phone
    updateUser.phonecountry = user.phonecountry
    updateUser.twitterURL = user.twitterURL
    updateUser.rol = user.rol
    updateUser.birthday = fechaBirthDay
    updateUser.gustos = user.gustos
    updateUser.address = user.address
    updateUser.landline = user.landline
    
    _ = try await updateUser.save(on: req.db)
    
    return updateUser.convertToPublic()
  }

  func createHandler(_ req: Request) async throws -> User.Public {
    let newUser = try req.content.decode(CreateUserData.self)
            
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
                  name: newUser.name,
                  username: newUser.username,
                  password: try Bcrypt.hash(newUser.password),
                  email: newUser.email,
                  twitterURL: newUser.twitterURL,
                  terminosdelservicio: true,
                  rol: newUser.rol,
                  phonecountry: newUser.phonecountry,
                  phone: newUser.phone,
                  codigoconfirmacion: "",
                  birthday: fechaBirthday)
      
    let code = String(Int.random(in: 100000...999999))
    
    user.codigoconfirmacion = code
    
    let result = user.save(on: req.db).map { user.convertToPublic() }
    
    let emailData = EmailData(
      address: user.email,
      subject: "Código confirmación Bitacora Fluvial: \(code)",
      message: "Por favor utilice este código para confirmar su registro en nuestra plataforma Bitacora Fluvial: \(code) ")
    
    _ = try await sendEmail(emailData: emailData, req: req)
    
    return user.convertToPublic()
    
  }
  
  struct EmailData {
      var address: String
      var subject: String
      var message: String
  }
  
  func sendEmail(emailData: EmailData, req: Request) async throws {
    let destination = SES.Destination(toAddresses: [emailData.address])
    let message = SES.Message(body: .init(text: SES.Content(data: emailData.message)), subject: .init(data: emailData.subject))
    let sendEmailRequest = SES.SendEmailRequest(destination: destination, message: message, source: "comunicaciones@bitacorafluvial.com")
    
    let client = req.aws.client
    let ses = SES(client: client)
    
    _ = try await ses.sendEmail(sendEmailRequest)
    
  }
}

struct CreateUserData: Content {
  let id: String
    let name: String
    let username: String
    let password: String
    let email: String
    let siwaIdentifier: String
    let profilePicture: String
    let twitterURL: String
    let rol: String
    let phone: String
    let phonecountry: String
    let terminosdelservicio: Bool
    let codigoconfirmacion: String
  let birthday: String
  let address: String
  let gustos: String
  let  landline: String
}
struct ImageUploadData: Content {
  var picture: Data
}
