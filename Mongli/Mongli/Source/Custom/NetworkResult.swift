//
//  NetworkResult.swift
//  Mongli
//
//  Created by DaEun Kim on 2020/03/18.
//  Copyright © 2020 DaEun Kim. All rights reserved.
//

import Foundation

enum NetworkResult {
  case success
  case error(NetworkError)
}

enum NetworkResultWithValue<T: Codable> {
  case success(T)
  case error(NetworkError)
}

enum NetworkError: Int, Error {
  case unknown = 0
  case ok = 200
  case noContent = 204
  case badRequest = 400
  case unauthorized = 401
  case notFound = 404
  case conflict = 409
  case serverError = 500

  init?(_ error: Error) {
    guard let error = error.asAFError,
      let code = error.responseCode,
      let networkError = NetworkError(rawValue: code) else { return nil }
    self = networkError
  }

  var message: LocalizedString? {
    switch self {
    case .noContent: return .noContent
    case .badRequest: return .badRequestErrorMsg
    case .unauthorized: return .unauthorizedErrorMsg
    case .notFound: return .notFoundErrorMsg
    case .serverError: return .serverErrorMsg
    default: return .unknownErrorMsg
    }
  }
}