//
//  Generator.router.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 18.07.2024.
//

import Foundation
import Alamofire

enum GeneratorRouter: URLRequestConvertible {
    case ls, getById(id: String), delete(id: String), patch(id: String, updatedGenerator: GeneratorHttpPayload), create(newGenerator: GeneratorHttpPayload)

    var path: String {
        let routeBaseUrl = "generator"

        switch self {
        case .ls:
            return "\(routeBaseUrl)/ls"
        case .getById(id: let id),
                .delete(id: let id),
                .patch(let id, _):
            return "\(routeBaseUrl)/\(id)"
        case .create:
            return "\(routeBaseUrl)/new"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .ls:
            return .get
        case .getById(id: _):
            return .get
        case .delete(id: _):
            return .delete
        case .patch(id: _):
            return .patch
        case .create:
            return .post
        }
    }

    private var userToken: String {
        KeychainService.shared.getUserApiToken() ?? ""
    }

    var headers: HTTPHeaders {
        var headers = HTTPHeaders()

        switch self {
        case .ls,
                .create,
                .delete,
                .patch,
                .getById:
            if !userToken.isEmpty {
                headers.add(.authorization(bearerToken: userToken))
            }
        }

        return headers
    }


    func asURLRequest() throws -> URLRequest {
        let apiBaseUrl = try Api.baseApiUrl.asURL()
        var request = URLRequest(url: apiBaseUrl.appendingPathComponent(path))
        request.method = method
        request.headers = headers

        switch self {
        case .create(let newGeneratorPayload):
            request = try JSONParameterEncoder().encode(newGeneratorPayload, into: request)
        case .patch(_, let updatedGeneratorPayload):
            request = try JSONParameterEncoder().encode(updatedGeneratorPayload, into: request)
        case .delete,
                .getById,
                .ls:
            break
        }

        return request
    }
}
