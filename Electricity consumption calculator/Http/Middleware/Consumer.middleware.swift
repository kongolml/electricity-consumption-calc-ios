//
//  Consumer.middleware.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 27.07.2024.
//

import Foundation

class ConsumerMiddleware {
    let keychain = KeychainToolbox()
    
//    func getGeneratorConsumers() {}
    
    func createGeneratorConsumer(for generatorDbId: String, with consumerEntity: ConsumerEntity, completion: @escaping (ConsumerHttpPayload?, Error?) -> Void) {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter.custom
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let consumerPayload = ConsumerHttpPayload(from: consumerEntity)
        
        AlamofireService.sharedSession.request(ConsumerRouter.create(generatorId: generatorDbId, newConsumerPayload: consumerPayload)).validate().responseDecodable(of: ConsumerHttpPayload.self, decoder: decoder) { response in
            switch response.result {
            case .success(let createdConsumer):
                completion(createdConsumer, nil)
            case .failure(let error):
                debugPrint(error)
                completion(nil, error)
            }
        }
    }
    
    func updateGeneratorConsumer() {}
    
    func deleteGeneratorConsumer() {}
    
//    func signInWithGoogleToken(idToken: String, completion: @escaping (UserAuthTokensFromServer?, Error?) -> Void) {
//        AlamofireService.sharedSession.request(AuthRouter.google(token: SignInGooglePayload(idToken: idToken))).validate().responseDecodable(of: UserAuthTokensFromServer.self) { response in
//            switch response.result {
//            case let .success(authTokens):
////                completion(.success(authTokens))
//                completion(authTokens, nil)
//            case let .failure(error):
//                debugPrint(error)
//                completion(nil, error)
//            }
//        }
//    }
}
