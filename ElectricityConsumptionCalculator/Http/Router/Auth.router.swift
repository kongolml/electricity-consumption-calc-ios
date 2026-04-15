//
//  Auth.router.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 16.07.2024.
//

import Foundation
import Alamofire

enum AuthRouter: URLRequestConvertible {
    case google(token: SignInGooglePayload)

    var path: String {
        let routeBaseUrl = "auth"

        switch self {
        case .google:
            return "\(routeBaseUrl)/google"
        }
    }
        
    var method: HTTPMethod {
        switch self {
        case .google:
            return .post
        }
    }
            
    var headers: HTTPHeaders {
        var headers = HTTPHeaders()

        switch self {
        case .google: break
        }

        return headers
    }
    
    
    func asURLRequest() throws -> URLRequest {
        let apiBaseUrl = try Api.baseApiUrl.asURL()
        var request = URLRequest(url: apiBaseUrl.appendingPathComponent(path))
        request.method = method
        request.headers = headers
        
        switch self {
        case .google(let token):
            request = try JSONParameterEncoder().encode(token, into: request)
        }
        
        return request
    }
}
