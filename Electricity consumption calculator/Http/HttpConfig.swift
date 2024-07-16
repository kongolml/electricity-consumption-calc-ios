//
//  HttpConfig.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 16.07.2024.
//

import Foundation
import Alamofire

struct Api {
    #if targetEnvironment(simulator)
        static let hostUrl = "https://electriciy-consumptions.localbackend:8888"
    #else
        static let hostUrl = "https://nfc.vn.ua"
    #endif
    
    static let baseApiUrl = "\(hostUrl)/api"
}

class AlamofireService {
    static let sharedSession: Session = {
        let configuration = URLSessionConfiguration.af.default
//        let interceptor = AFRequestInterceptor()
        
        return Session(
            configuration: configuration,
//            interceptor: interceptor,
             eventMonitors: [
//            AlamofireLogger()
             ])
    }()
}

//final class AlamofireLogger: EventMonitor {
//    func requestDidResume(_ request: Request) {
//        let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
//        let message = """
//        ⚡️ Request Started: \(request)
//        ⚡️ Body Data: \(body)
//        """
//        NSLog(message)
//    }
//
//    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
//        print("⚡️ Response Received: \(response.debugDescription)")
//    }
//}

//class AFRequestInterceptor: RequestInterceptor {
//    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
//        let keychain = KeychainToolbox()
//        let userAccessToken = keychain.getUserTokenFromKeychain() ?? "no token in interceptor"
//
//        var urlRequest = urlRequest
//        urlRequest.headers.add(.authorization(bearerToken: userAccessToken))
//
//        completion(.success(urlRequest))
//    }
//}
