import Vapor

final class HSTSMiddleware: Middleware, Service {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        guard request.environment == Environment.production else {
            return try next.respond(to: request)
        }

        let proto = request.http.headers.firstValue(name: HTTPHeaderName("X-Forwarded-Proto"))
            ?? request.http.url.scheme
            ?? "http"

        guard proto == "https" else {
            guard let host = request.http.headers.firstValue(name: .host) else {
                throw Abort(.badRequest)
            }

            let httpsURL = "https://" + host + request.http.urlString
            return request.future(request.redirect(to: httpsURL, type: .permanent))
        }

        return try next.respond(to: request)
            .map { resp in
                resp.http.headers.add(
                    name: "Strict-Transport-Security",
                    value: "max-age=31536000; includeSubDomains; preload")
                return resp
            }
    }
}
