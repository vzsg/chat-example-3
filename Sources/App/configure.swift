import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register routes to the router
    let router = EngineRouter.default()

    router.get { req -> Future<Response> in
        let indexPath = try req.make(DirectoryConfig.self).workDir + "Public/index.html"
        return try req.streamFile(at: indexPath)
    }
    
    services.register(router, as: Router.self)
    services.register(HSTSMiddleware())

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(HSTSMiddleware.self)
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    let chatController = ChatController()
    services.register(chatController)

    let websocket = NIOWebSocketServer.default()
    websocket.get("chat", use: chatController.onUpgrade)
    services.register(websocket, as: WebSocketServer.self)
}
