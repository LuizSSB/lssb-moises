//
//  Error.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

import Alamofire
import Foundation

struct NotFoundError: Error {
}

struct InvalidDataError: Error {
}

struct UserFacingError: Equatable, Hashable {
    enum AppErrorKind {
        case noInternetConnection,
             notFound,
             invalidData,
             generic
    }
    
    let kind: AppErrorKind
    let title: String
    let message: String
}

extension Error {
    var userFacingError: UserFacingError {
        if isNoInternetConnectionError {
            return .init(
                kind: .noInternetConnection,
                title: String(localized: .errorNoInternetTitle),
                message: String(localized: .errorNoInternetMessage)
            )
        }
        
        if self is NotFoundError {
            return .init(
                kind: .notFound,
                title: String(localized: .errorNotFoundTitle),
                message: String(localized: .errorNotFoundMessage)
            )
        }
        
        if self is InvalidDataError {
            return .init(
                kind: .invalidData,
                title: String(localized: .errorInvalidDataTitle),
                message: String(localized: .errorInvalidDataMessage)
            )
        }

        return .init(
            kind: .generic,
            title: String(localized: .errorGenericTitle),
            message: String(localized: .errorGenericMessage)
        )
    }

    private var isNoInternetConnectionError: Bool {
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain,
           nsError.code == URLError.notConnectedToInternet.rawValue {
            return true
        }

        return false
    }
}
