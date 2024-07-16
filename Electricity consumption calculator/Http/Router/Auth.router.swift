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
            
            //        case .signup:
            //            return "\(routeBaseUrl)/signup"
        }
    }
        
    var method: HTTPMethod {
        switch self {
        case .google:
            return .post
        }
    }
            
//    private var userToken: String {
//        let keychain = KeychainToolbox()
//
//        guard let userAccessToken = keychain.getUserTokenFromKeychain() else {return "NO_TOKEN_FROM_USER_ROUTER"}
//
//        return userAccessToken
//    }
    
    var headers: HTTPHeaders {
        var headers = HTTPHeaders()
        
        switch self {
        case .google: break
            //        case .signup: break
            //        case .getCurrent:
            //            debugPrint("UserRouter is using access token: \(userToken)")
            //            headers.add(.authorization(bearerToken: userToken))
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
            print("the toekn is \(token)")
            request = try JSONParameterEncoder().encode(token, into: request)
            //        case let .login(loginCredentials):
            //            request = try JSONParameterEncoder().encode(loginCredentials, into: request)
            //
            //        case let .signup(newUserData):
            //            request = try JSONParameterEncoder().encode(newUserData, into: request)
            //
            //        case .getCurrent:
            //            break
        }
        
        return request
    }
}
