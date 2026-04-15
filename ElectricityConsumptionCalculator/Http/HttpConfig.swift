//
//  HttpConfig.swift
//  Electricity consumption calculator
//
//  Created by Kostiatyn Golosov on 16.07.2024.
//

import Foundation
import Alamofire
import os

// Notification name for authentication state changes
extension Notification.Name {
    static let authenticationFailed = Notification.Name("com.electricitycalculator.authenticationFailed")
}

struct Api {
    private static let infoDictionary: [String: Any]? = {
        Bundle.main.infoDictionary
    }()

    static let hostUrl: String = {
        if let url = infoDictionary?["ApiHostUrl"] as? String, !url.isEmpty {
            return url
        }
        // Fallback to compile-time defaults
        #if targetEnvironment(simulator)
        return "https://electricity-consumptions.localbackend:8888"
        #else
        return "https://nfc.vn.ua"
        #endif
    }()

    static let baseApiUrl = "\(hostUrl)/api"
}

class AlamofireService {
    static let sharedSession: Session = {
        let configuration = URLSessionConfiguration.af.default
        let interceptor = AFRequestInterceptor()

        return Session(
            configuration: configuration,
            interceptor: interceptor,
             eventMonitors: [
                AlamofireLogger()
             ])
    }()
}

final class AlamofireLogger: EventMonitor {
    func requestDidResume(_ request: Request) {
        let body = request.request.flatMap { $0.httpBody.map { String(decoding: $0, as: UTF8.self) } } ?? "None"
        let message = """
        ⚡️ Request Started: \(request)
        ⚡️ Body Data: \(body)
        """
        NSLog(message)
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        print("⚡️ Response Received: \(response.debugDescription)")
    }
}

class AFRequestInterceptor: RequestInterceptor {
    private let refreshQueue = DispatchQueue(label: "com.electricitycalculator.requestinterceptor.refresh")
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        if let token = KeychainService.shared.getUserApiToken(), !token.isEmpty {
            urlRequest.headers.add(.authorization(bearerToken: token))
        }
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        refreshQueue.async {
            guard let response = request.task?.response as? HTTPURLResponse,
                  response.statusCode == 401 else {
                completion(.doNotRetry)
                return
            }

            // Don't retry auth endpoints to avoid infinite loops
            guard let url = request.request?.url else {
                completion(.doNotRetry)
                return
            }
            let path = url.path
            guard !path.hasPrefix("/api/auth/") else {
                completion(.doNotRetry)
                return
            }

            // Don't retry more than once
            guard request.retryCount == 0 else {
                completion(.doNotRetry)
                return
            }

            // Check if we have a refresh token
            guard let refreshToken = KeychainService.shared.getRefreshToken() else {
                // No refresh token available, clear tokens and don't retry
                KeychainService.shared.clearAllTokens()
                completion(.doNotRetry)
                return
            }

            // Queue this request's completion for retry after refresh
            self.requestsToRetry.append(completion)

            guard !self.isRefreshing else { return }
            self.isRefreshing = true

            AuthenticationService.shared.refreshToken(refreshToken: refreshToken) { [weak self] tokens, error in
                guard let self = self else { return }

                self.refreshQueue.async {
                    defer {
                        self.isRefreshing = false
                        self.requestsToRetry.removeAll()
                    }

                    if let tokens = tokens {
                        // Save new tokens
                        KeychainService.shared.setUserApiToken(newToken: tokens.accessToken)
                        if let newRefreshToken = tokens.refreshToken {
                            KeychainService.shared.setRefreshToken(value: newRefreshToken)
                        }

                        // Update token expiration if provided, default to 1 hour
                        let expiresIn = tokens.expiresIn ?? 3600
                        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                        KeychainService.shared.setTokenExpiration(expirationDate: expirationDate)

                        AppLogger.auth.info("Token refreshed successfully, expires at: \(expirationDate)")

                        // Retry all queued requests
                        self.requestsToRetry.forEach { $0(.retry) }
                    } else {
                        // Refresh failed - clear tokens, notify UI, and don't retry
                        AppLogger.auth.error("Token refresh failed: \(error?.localizedDescription ?? "unknown error")")
                        KeychainService.shared.clearAllTokens()

                        // Notify UI to update authentication state
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .authenticationFailed, object: nil)
                        }

                        self.requestsToRetry.forEach { $0(.doNotRetry) }
                    }
                }
            }
        }
    }
}
