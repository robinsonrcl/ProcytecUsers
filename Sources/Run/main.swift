import App
import Vapor
import Smtp

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

app.smtp.configuration.hostname = "smtp.hostinger.com"
app.smtp.configuration.signInMethod = .credentials(username: "notificacion@procytec.com.co", password: "Procyt3c$")
app.smtp.configuration.secure = .ssl

try configure(app)
try app.run()
