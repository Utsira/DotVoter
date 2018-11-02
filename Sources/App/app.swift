import Vapor

private var application: Application?

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()
    try configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try boot(app)
	application = app
    return app
}

func shutdown(callback: @escaping (Error?) -> Void) {
	application?.shutdownGracefully(callback)
}
