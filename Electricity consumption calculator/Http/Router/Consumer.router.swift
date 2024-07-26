//
//  Consumer.router.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 27.07.2024.
//

import Foundation
import Alamofire

enum ConsumerRouter: URLRequestConvertible {
    case create(generatorId: String, newConsumerPayload: ConsumerHttpPayload), update(generatorId: String, consumerID: String, updatedConsumerPayload: ConsumerHttpPayload), delete(generatorId: String, consumerID: String)
    
    var path: String {
        let routeBaseUrl = "generator"
        
        switch self {
        case .create(let generatorId, _):
            return "\(routeBaseUrl)/\(generatorId)"
        case .update(let generatorId, let consumerID, _),
                .delete(let generatorId, let consumerID):
            return "\(routeBaseUrl)/\(generatorId)/consumer/\(consumerID)"
        }
    }
        
    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .update:
            return .patch
        case .delete:
            return .delete
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
        case .create,
                .update,
                .delete:
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
        case .create(_, let newConsumerPayload):
            request = try JSONParameterEncoder().encode(newConsumerPayload, into: request)
        case .update(_, _, let updatedConsumerPayload):
            request = try JSONParameterEncoder().encode(updatedConsumerPayload, into: request)
        case .delete:
            break
        }
        
        return request
    }
}
