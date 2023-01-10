import Vapor
import Smtp
import Fluent
import SotoSES

struct UsersController: RouteCollection {
  
  let imageFolder = "ProfilePictures/"
  
  func boot(routes: RoutesBuilder) throws {
      
    let usersGroup = routes.grouped("users")
    
    //-------
    let users = routes.grouped("user")
    
    let tokenAuthMiddleware = Token.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let userProtected = users.grouped(tokenAuthMiddleware, guardAuthMiddleware)
    
    userProtected.get("check", ":nivel", ":userID", use: checkNivelAcess)
    //-------
    
    usersGroup.post("update",  use: updateUser)
    usersGroup.get(use: getAllHandler)
    usersGroup.get(":userID", use: getHandler)
    usersGroup.get("getuser",":username", use: getUser)
    usersGroup.post(use: createHandler)
    usersGroup.post("setnewpwd", use: setNewPwd)
    usersGroup.get("validaremail",":email", use: getValidarEmail)
    usersGroup.get("enviarcode",":email", use: reenviarCodigo)
    usersGroup.get("coderestorepwd",":email", use: codeRestorePWD)
    usersGroup.get("resendcode", ":userID", use: resendCode)
    usersGroup.get("confirmregister", ":userID", ":codigo", use: confirmRegister)
    
    let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
    let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/"))
    let protectedRoutesCursos = protectedRoutes.grouped("api", "cursos")
    
    protectedRoutesCursos.post("users","upload", use: addProfilePicture)
    protectedRoutes.on(.POST, "users", ":userID", "addProfilePicture", body: .collect(maxSize: "10mb"), use: addProfilePicture)
  }
  
  struct RptBool: Content {
    var hasAccess: Bool = false
  }
  
  func checkNivelAcess(_ req: Request) async throws -> RptBool {
    let permissionName = req.parameters.get("nivel")
    let userID  = req.parameters.get("userID")
    var check = false
    
    let user = try await User.find(UUID(userID!)!, on: req.db)
    
    try await user?.$roles.load(on: req.db)
    
    try  await user?.roles.$permissions.load(on: req.db)
      
    user!.roles.permissions.forEach({ permission in
      if(permission.name == permissionName){
        check = true
      }
    })
    
    var rpt = RptBool()
    if(check){
      rpt.hasAccess = true
    }else{
      rpt.hasAccess = false
    }
    
    return rpt
    
  }
  
  func addProfilePicture(_ req: Request) async throws -> HTTPStatus {
        let data = try req.content.decode(ImageUploadData.self)
    
    return HTTPStatus.ok
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
//            return req.content.contentType.
//          }
//        }
      }
  
  struct RespuestaBool: Content {
    var respuesta: String = ""
    var userID: String = ""
  }
  
  func confirmRegister(_ req: Request) async throws -> RespuestaBool {
    let id = try UUID(req.parameters.require("userID"))!
    let codigo = try req.parameters.require("codigo")
    
    let user = try await User.find(id, on: req.db)
    
    var respuesta = RespuestaBool()
    
    if(user != nil){
      if(user?.codigoconfirmacion == codigo){
        user?.codigoconfirmacion = "Confirmado"
        _ = try await user?.save(on: req.db)
        
        respuesta.respuesta = "CONFIRMADO"
      }else{
        respuesta.respuesta = "CODIGOERRONEO"
      }
    }else{
      respuesta.respuesta = "USUARIONOEXISTE"
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
      subject: "Código confirmación CRM Conecta: \(code)",
      message: "Por favor utilice este código para confirmar su registro en nuestro CRM Conecta: \(code) ")
    
    _ = try await enviarEmail(emailData: emailData, req: req)
    
    return HTTPStatus.ok
    
  }
  
  func getValidarEmail(_ req: Request) async throws ->  RespuestaBool {
    var correo = req.parameters.get("email")!
    
    let usuario = try await User.query(on: req.db)
      .filter(\.$email == correo)
      .first()
    
    var result = RespuestaBool()
    
    if(usuario != nil){
      if(usuario?.codigoconfirmacion != "Confirmado"){
        result = RespuestaBool(respuesta: "NOCONFIRMADO", userID: (usuario?.id?.uuidString)!)
      }else{
        result = RespuestaBool(respuesta: "CONFIRMADO", userID: (usuario?.id?.uuidString)!)
      }
      
    }else{
      result = RespuestaBool(respuesta: "USUARIONOEXISTE")
    }
      
    return result
  }

  func getAllHandler(_ req: Request) -> EventLoopFuture<[User.Public]> {
    User.query(on: req.db).all().convertToPublic()
  }

  func getUser(_ req: Request) async throws -> User.Public {
    let username = req.parameters.get("username", as: String.self)!
    
    let user = try await User.query(on: req.db).filter(\.$username == username).with(\.$roles).first()
    
    if(user != nil){
      return (user?.convertToPublic())!
    }else{
      let idTmp = UUID.generateRandom()
      let rol = Rol()
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
                             terminosdelservicio: false,
                            roles: rol)
      return user
    }
  }
  
  func getHandler(_ req: Request) -> EventLoopFuture<User.Public> {
    User.find(req.parameters.get("userID"), on: req.db)
      .unwrap(or: Abort(.notFound))
      .convertToPublic()
  }
  
  func updateUser(_ req: Request) async throws -> User.Public {
    let user = try req.content.decode(CreateUserData.self)
    
//    let updateUser = try await User.find(UUID(user.id), on: req.db).map {
//      user.$roles.load(on: req.db)
//    }
    
    let updateUser = try await User.query(on: req.db).filter(\.$id == UUID(user.id!)!).with(\.$roles).first()
    
    var fechaBirthDay = Date()
    
    let isoDate = user.birthday
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: isoDate!) {
      fechaBirthDay = date
    }
    
    updateUser!.name = user.name
    updateUser!.phone = user.phone!
    updateUser!.phonecountry = user.phonecountry!
    updateUser!.twitterURL = user.twitterURL
    updateUser!.rol = user.rol
    updateUser!.birthday = fechaBirthDay
    updateUser!.gustos = user.gustos!
    updateUser!.address = user.address!
    updateUser!.landline = user.landline!
    updateUser!.$roles.id = user.roles!
    
    _ = updateUser!.save(on: req.db).map {
      updateUser!.$roles.load(on: req.db)
    }
    
    return updateUser!.convertToPublic()
  }

  func setNewPwd(_ req: Request) async throws -> HTTPStatus {
    let newpassword = try req.content.decode(newPassword.self)
    
    let updateUser = try await User.query(on: req.db).first()
    
    if(updateUser != nil){
      if(updateUser!.password == newpassword.code){
        updateUser?.password = try Bcrypt.hash(newpassword.password)
        
        _ = try await updateUser?.save(on: req.db)
        
        return HTTPStatus.ok
      }else{
        return HTTPStatus.custom(code: 207, reasonPhrase: "Código de confirmación no corresponde")
      }
    }else{
      return HTTPStatus.custom(code: 208, reasonPhrase: "Usuario no encontrado")
    }
  }
  
  struct newPassword: Content {
    let email: String
    let password: String
    let code: String
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
    
    let rol = try await Rol.query(on: req.db).filter(\.$name == "Comercial").first()
    
    let user = User(
                  name: newUser.name,
                  username: newUser.username,
                  password: try Bcrypt.hash(newUser.password),
                  email: newUser.email,
                  twitterURL: newUser.twitterURL,
                  terminosdelservicio: true,
                  rol: newUser.rol,
                  phonecountry: newUser.phonecountry ?? "",
                  phone: newUser.phone ?? "",
                  codigoconfirmacion: "",
                  birthday: fechaBirthday,
                  rolID: rol!.id!)
      
    let code = String(Int.random(in: 100000...999999))
    
    user.codigoconfirmacion = code
    
    let userExist = try await User.query(on: req.db).filter(\.$email == newUser.email).first()
    
    if(userExist != nil){
      userExist?.codigoconfirmacion = code
      
      _ = try await userExist?.save(on: req.db)
    }else{
      let result = user.save(on: req.db).map {
        user.$roles.load(on: req.db)
      }
    }
    
    let emailData = EmailData(
      address: user.email,
      subject: "Código confirmación CRM Conecta: \(code)",
      message: "Por favor utilice este código para confirmar su registro en nuestro CRM Conecta: \(code) ")
    
    _ = try await enviarEmail(emailData: emailData, req: req)
    
    if(userExist != nil){
      try await userExist!.$roles.load(on: req.db)
      return userExist!.convertToPublic()
    }else{
      return user.convertToPublic()
    }
  }
  
  struct EmailData {
      var address: String
      var subject: String
      var message: String
  }
  
    func reenviarCodigo(_ req: Request) async throws -> HTTPStatus {
      
      let correo = req.parameters.get("email")
      
      let user = try await User.query(on: req.db).filter(\.$email == correo!).first()
      let code = String(Int.random(in: 100000...999999))
      
      user!.codigoconfirmacion = code
      
      try await user!.save(on: req.db)
      
      let emailData = EmailData(
        address: user!.email,
        subject: "Código confirmación CRM Conecta: \(code)",
        message: "Por favor utilice este código para confirmar su registro en nuestro CRM Conecta: \(code) ")
      
      _ = try await enviarEmail(emailData: emailData, req: req)
      
      return HTTPStatus.ok
      
    }
  
  func codeRestorePWD(_ req: Request) async throws -> HTTPStatus {
    
    let correo = req.parameters.get("email")
    
    let user = try await User.query(on: req.db).filter(\.$email == correo!).first()
    let code = String(Int.random(in: 100000...999999))
    
    user!.password = code
    
    try await user!.save(on: req.db)
    
    let emailData = EmailData(
      address: user!.email,
      subject: "Código para asignación de nueva contraseña en CRM Conecta: \(code)",
      message: "Por favor utilice este código para confirmar su asignación de una nueva contraseña en CRM Conecta: \(code) ")
    
    _ = try await enviarEmail(emailData: emailData, req: req)
    
    return HTTPStatus.ok
    
  }
  
  func enviarEmail(emailData: EmailData, req: Request) async throws {
    let email = try! Email(from: EmailAddress(address: "notificacion@procytec.com.co", name: "Notificaciones Procytec"),
                           to: [EmailAddress(address: emailData.address , name: emailData.address)],
                           subject: emailData.subject,
                           body: emailData.message)

    try await req.smtp.send(email)
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
  let id: String?
    let name: String
    let username: String
    let password: String
    let email: String
    let siwaIdentifier: String?
    let profilePicture: String?
    let twitterURL: String?
    let rol: String
    let phone: String?
    let phonecountry: String?
  var terminosdelservicio: Bool? = true
    let codigoconfirmacion: String?
  let birthday: String?
  let address: String?
  let gustos: String?
  let  landline: String?
  let roles: UUID?
}
struct ImageUploadData: Content {
  var picture: Data
}
