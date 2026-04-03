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

struct UserFacingError: Equatable {
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
                title: "No internet connection",
                message: "Please check your connection and try again."
            )
        }
        
        if self is NotFoundError {
            return .init(
                kind: .notFound,
                title: "Item not found",
                message: "We couldn't find what you were looking for. Please try again."
            )
        }
        
        if self is InvalidDataError {
            return .init(
                kind: .invalidData,
                title: "Invalid data",
                message: "Remote data couldn't be parsed. Please try again later."
            )
        }

        return .init(
            kind: .generic,
            title: "Something went wrong",
            message: "Please try again. If the problem continues, cancel and try later."
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
