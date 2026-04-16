//
//  Auth.middleware.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 16.07.2024.
//

import Foundation

class AuthMiddleware {
    let keychain = KeychainToolbox()
    
    func signInWithGoogleToken(idToken: String, completion: @escaping (UserAuthTokensFromServer?, Error?) -> Void) {
        AlamofireService.sharedSession.request(AuthRouter.google(token: SignInGooglePayload(idToken: idToken))).validate().responseDecodable(of: UserAuthTokensFromServer.self) { response in
            switch response.result {
            case let .success(authTokens):
                completion(authTokens, nil)
            case let .failure(error):
                debugPrint(error)
                completion(nil, error)
            }
        }
    }
}
