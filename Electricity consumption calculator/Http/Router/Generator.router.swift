//
//  Generator.router.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 18.07.2024.
//

import Foundation
import Alamofire

enum GeneratorRouter: URLRequestConvertible {
    case getUserGenerators, getById(generatorId: String), delete(id: String), patch(id: String, updatedGenerator: GeneratorHttpPayload), create(newGenerator: GeneratorHttpPayload)
    
    var path: String {
        let routeBaseUrl = "generator"
        
        switch self {
        case .getUserGenerators:
            return "\(routeBaseUrl)/ls"
        case .getById(let generatorId),
                .delete(let generatorId),
                .patch(let generatorId, _):
            return "\(routeBaseUrl)/\(generatorId)"
        case .create:
            return "\(routeBaseUrl)/new"
        }
    }
        
    var method: HTTPMethod {
        switch self {
        case .getUserGenerators:
            return .get
        case .getById(generatorId: _):
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
        let keychain = KeychainToolbox()

        guard let userAccessToken = keychain.getUserApiToken() else {return "NO_TOKEN_FROM_USER_ROUTER"}

        return userAccessToken
    }
    
    var headers: HTTPHeaders {
        var headers = HTTPHeaders()
        
        switch self {
        case .getUserGenerators,
                .create,
                .delete,
                .patch,
                .getById:
            headers.add(.authorization(bearerToken: userToken))
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
                .getUserGenerators:
            break
        }
        
        return request
    }
}
