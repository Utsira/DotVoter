import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get("/") { req in
        return try req.view().render("index.html")
    }

    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

	router.get("shutdown") { req -> Future<String> in
		let promise = req.eventLoop.newPromise(String.self)
		shutdown { error in
			if let error = error {
				promise.fail(error: error)
				return
			}
			promise.succeed(result: "shut down")
		}
		return promise.futureResult
	}
	
	router.get("resetWithTests") { req -> HTTPResponseStatus in
		Room.shared.cardManager.addTestCards()
		return .ok
	}
	
}
