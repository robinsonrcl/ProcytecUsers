import Vapor
import Smtp
import Fluent
import SotoSES
import SotoSNS

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
    
    let user = try await User.find(req.parameters.get("userID"), on: req.db)!
    let code = String(Int.random(in: 100000...999999))
    
    user.codigoconfirmacion = code
    
    try await user.save(on: req.db)
    
    let message = "Código confirmación CRM Conecta"
    
    let messageHTML = readTemplateEmail(tittle: "Código de confirmación",
                                        subtittle: "Gestión de usuarios",
                                        name: user.name,
                                        body: message,
                                        code: code)
    
    let emailData = EmailData(
      address: user.email,
      subject: message,
      message: messageHTML)
    
    let phone = ajustarPhone(phone: user.phone, phoneCountry: user.phonecountry)
    
    _ = try await sendSMS(message: message + ": " + code, phone: phone, req: req)
    _ = try await sendEmailWithSMTP(emailData: emailData, req: req)
    
    return HTTPStatus.ok
    
  }
  
  func getValidarEmail(_ req: Request) async throws ->  RespuestaBool {
    let correo = req.parameters.get("email")!
    
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
    let userNewPassword = try req.content.decode(newPassword.self)
    
    let updateUser = try await User.query(on: req.db).filter(\.$username == userNewPassword.email).first()
    
    if(updateUser != nil){
      if(updateUser!.password == userNewPassword.code){
        updateUser?.password = try Bcrypt.hash(userNewPassword.password)
        
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
      _ = user.save(on: req.db).map {
        user.$roles.load(on: req.db)
      }
    }
    
    let message = "Código confirmación CRM Conecta"
    let messageBody = "A continuación encuentra el código generado para la confirmación de su registro en nuestra plataforma."
    
    let messageHTML = readTemplateEmail(tittle: "Código de confirmación",
                                        subtittle: "Gestión de usuarios",
                                        name: user.name,
                                        body: messageBody,
                                        code: code)
    
    let emailData = EmailData(
      address: user.email,
      subject: message,
      message: messageHTML)
    
    let phone = ajustarPhone(phone: user.phone, phoneCountry: user.phonecountry)
    
    _ = try await sendSMS(message: message + ": " + code, phone: phone, req: req)
    _ = try await sendEmailWithSMTP(emailData: emailData, req: req)
    
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
      
      let message = "Código confirmación CRM Conecta"
      let messageBody = "A continuación el código de confirmación generado."
      
      let messageHTML = readTemplateEmail(tittle: "Código de confirmación",
                                          subtittle: "Gestión de usuarios",
                                          name: user!.name,
                                          body: messageBody,
                                          code: code)
      
      let emailData = EmailData(
        address: user!.email,
        subject: message,
        message: messageHTML)
      
      let phone = ajustarPhone(phone: user!.phone, phoneCountry: user!.phonecountry)
      
      _ = try await sendSMS(message: message + ": " + code, phone: phone, req: req)
      _ = try await sendEmailWithSMTP(emailData: emailData, req: req)
      
      return HTTPStatus.ok
      
    }
  
  func readTemplateEmail(tittle: String, subtittle: String, name: String, body: String, code: String) -> String {
    var plantilla: String
    
    plantilla = "<!doctype html>" +
    "<html>" +
    "  <head><title></title>" +
    "<style>" +
    "@import url('https://fonts.googleapis.com/css2?family=Arima:wght@100;400&family=Bebas+Neue&family=Edu+NSW+ACT+Foundation:wght@600&family=Edu+SA+Beginner&display=swap');" +
    ".titleCodigo {" +
    "  font-weight: 600;" +
    "  text-align: center;" +
    "}" +
    ".codigo {" +
    "  font-weight: 900;" +
    "  font-size: 2.5rem;" +
    "  text-align: center;" +
    "  border-radius: 5px;" +
    "  margin: 0px 50px 0px 50px;" +
    "}" +
    ".sub {" +
    "  padding: 20px;" +
    "  border: 1px;" +
    "  border-block-color: white;" +
    "  border-style: double;" +
    "  display: block;" +
    "}" +
    ".logo {" +
    "  width: 200px;" +
    "  height: 70px;" +
    "}" +
    ".footer1 {" +
    "  background: rgb(172, 192, 225);" +
    "  text-align: center;" +
    "  padding: 5px 0 5px 30px;" +
    "}" +
    ".footer2 {" +
    "  text-align: left;" +
    "  padding: 5px 0 5px 17px;" +
    "  display: inline-flex;" +
    "  font-size: small;" +
    "}" +
    ".texto {" +
    "  font-size: medium;" +
    "  text-align: justify;" +
    "  display: block;" +
    "  padding: 30px 0 30px 0;" +
    "}" +
    ".cuerpo {" +
    "  text-align: left;" +
    "  padding: 30px;" +
    "}" +
    ".name {" +
    "  font-weight: 700;" +
    "}" +
    ".tittle {" +
    "  font-size: 30px;" +
    "  background: rgb(172, 192, 225);" +
    "  width: -webkit-fill-available;" +
    "  border-radius: 20px 20px 0 0;" +
    "  padding: 40px 0 0 0;" +
    "  text-align: center;" +
    "}" +
    ".subtittle {" +
    "  font-size: 12px;" +
    "  background: rgb(172, 192, 225);" +
    "  padding: 0 0 40px 0;" +
    "  text-align: center;" +
    "}" +
    ".container {" +
    "  text-align: center;" +
    "  background-color: white;" +
    "  display: flow-root;" +
    "  position: absolute;" +
    "  top: 0px;" +
    "  width: auto;" +
    "  border-radius: 20px;" +
    "  height: auto;" +
    "  margin: 20px;" +
    "  padding: 0px;" +
    "}" +
    ".leyenda2 {" +
    "  font-size: small;" +
    "}" +
    ".leyenda1 {" +
    " font-size: 22px;" +
    "}" +
    "@media (max-width: 420px) and (orientation: portrait) {" +
    " .footer2 {" +
    "  text-align: center;" +
    "  padding: 5px 0 5px 30px;" +
    "  display: contents;" +
    "  font-size: small;" +
    " }" +
    " .sub {" +
    "  padding: 5px;" +
    "  border: 1px;" +
    "  border-block-color: white;" +
    "  border-style: double;" +
    "  text-align: left;" +
    " }" +
    " .logo {" +
    "  width: 200px;" +
    "  height: 70px;" +
    " }" +
    "}" +
    "</style>" +
    "  </head>" +
    "  <body>" +
    "    <div class='container'>" +
    "      <div class='tittle'>\(tittle)</div>" +
    "      <div class='subtittle'>\(subtittle)</div>" +
    "      <div class='cuerpo'>" +
    "        <span class='name'>Sr(a) \(name)</span" +
    "        ><span class='texto'>\(body)</span>" +
    "        <div class='titleCodigo'>Código</div>" +
    "        <div class='codigo'>\(code)</div>" +
    "      </div>" +
    "      <div class='footer1'>" +
    "        <img id='imglogo' src='https://procytec.s3.amazonaws.com/procyteclogo.png' style='width: 154px;height: 42px;' alt='Logo' /><br>" +
    "      <span class='leyenda1'>EXCELENCIA EN EL SERVICIO</span><br/>" +
    "      <span class='leyenda2'>Somos el mejor aliado estratégico en soluciones integrales de ITO</span>" +
    "      </div>" +
    "      <div class='footer2'>" +
    "        <div class='sub'>" +
    "          Sede Medellin<br>Calle 34B #66A-44 Oficina 202" +
    "        </div>" +
    "        <div class='sub'>Sede Cali<br>Carrera 103 #11-40</div>" +
    "        <div class='sub'>" +
    "          <div>PBX 604 2079773 / 313 7182291</div>" +
    "          <div><a href='www.procytec.com.co'>www.procytec.com.co</a></div>" +
    "      </div>" +
    "      </div>" +
    "    </div>" +
    "  </body>" +
    "</html>"
    
    plantilla = plantilla.trimmingCharacters(in: .whitespaces)
    
    return plantilla
  }
  

  
  func codeRestorePWD(_ req: Request) async throws -> HTTPStatus {
    
    let correo = req.parameters.get("email")
    
    let user = try await User.query(on: req.db).filter(\.$email == correo!).first()
    
    if(user == nil){
      return HTTPStatus.notFound
    }
    let code = String(Int.random(in: 100000...999999))
    
    user!.password = code
    
    try await user!.save(on: req.db)
    
    let message = "Código para asignación de nueva contraseña en CRM Conecta"
    let messageText = "Por favor utilice este código para confirmar la asignación de una nueva contraseña en nuestro CRM Conecta:"
    
    let messageHTML = readTemplateEmail(tittle: "Recuperar Contraseña",
                                        subtittle: "Gestión de usuarios",
                                        name: user!.name,
                                        body: messageText,
                                        code: code)
    
    let emailData = EmailData(
      address: user!.email,
      subject: message,
      message: messageHTML)
    
    let phone = ajustarPhone(phone: user!.phone, phoneCountry: user!.phonecountry)
    
    _ = try await sendSMS(message: message + ": " + code, phone: phone, req: req)
    _ = try await sendEmailWithSMTP(emailData: emailData, req: req)
    
    
    return HTTPStatus.ok
    
  }
  
  func ajustarPhone(phone: String, phoneCountry: String) -> String {
    var phoneC = phoneCountry.replacingOccurrences(of: "(", with: "")
    phoneC = (phoneC.replacingOccurrences(of: ")", with: ""))
    let newPhone =  phone.replacingOccurrences(of: "-", with: "")
    return "\(String(describing: phoneC))\(String(describing: newPhone))"
  }
  
  func sendEmailWithSMTP(emailData: EmailData, req: Request) async throws {
    let emailFrom = Environment.get("EMAIL_FROM")
    let emailFromName = Environment.get("EMAIL_FROM_NAME")
    
    let email = try! Email(from: EmailAddress(address: emailFrom!, name: emailFromName),
                           to: [EmailAddress(address: emailData.address , name: emailData.address)],
                           subject: emailData.subject,
                           body: emailData.message,
                          isBodyHtml: true)

    try await req.smtp.send(email)
  }
  
  func sendEmailWithSES(emailData: EmailData, req: Request) async throws {
    let emailFrom = Environment.get("EMAIL_FROM")
    
    let destination = SES.Destination(toAddresses: [emailData.address])
    let message = SES.Message(body: .init(text: SES.Content(data: emailData.message)),
                              subject: .init(data: emailData.subject))
    let sendEmailRequest = SES.SendEmailRequest(destination: destination,
                                                message: message,
                                                source: emailFrom!)
    
    let client = req.aws.client
    let ses = SES(client: client)
    
    _ = try await ses.sendEmail(sendEmailRequest)
    
  }
  
  func sendSMS(message: String, phone: String, req: Request) async throws -> String {
    let enviar = SNS(client: req.aws.client)
    let input = SNS.PublishInput(message: message, phoneNumber: phone)
    let result = try await enviar.publish(input)
    
    return result.messageId ?? ""
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

