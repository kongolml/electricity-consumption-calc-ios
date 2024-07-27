//
//  Generator.middleware.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 27.07.2024.
//

import Foundation

extension DateFormatter {
    static let custom: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // Adjust this format as needed
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

class GeneratorMiddleware {
    let keychain = KeychainToolbox()
    
    func getGeneratorById(generatorId: String, completion: @escaping (GeneratorFromServer?, Error?) -> Void) {
        AlamofireService.sharedSession.request(GeneratorRouter.getById(generatorId: generatorId)).validate().responseDecodable(of: GeneratorFromServer.self) { response in
            switch response.result {
            case .success(let consumer):
                debugPrint(consumer)
                completion(consumer, nil)
            case .failure(let error):
                debugPrint(error)
                completion(nil, error)
            }
        }
    }
    
    func getUserGenerators(completion: @escaping ([GeneratorFromServer]?, Error?) -> Void) {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter.custom
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        AlamofireService.sharedSession.request(GeneratorRouter.getUserGenerators).validate().responseDecodable(of: [GeneratorFromServer].self, decoder: decoder) { response in
            switch response.result {
            case .success(let generatorsList):
                debugPrint(generatorsList)
                completion(generatorsList, nil)
            case .failure(let error):
                debugPrint(error)
                completion(nil, error)
            }
        }
    }
    
//    func createGeneratorConsumer() {
//        AlamofireService.sharedSession.request(GeneratorRouter.getById(id: <#T##String#>))
//    }
    
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
