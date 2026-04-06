//
//  ErrorPresentation.swift
//  MoisesChallenge
//
//  Created by Codex on 03/04/26.
//

import Foundation

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
        return nsError.domain == NSURLErrorDomain
            && nsError.code == URLError.notConnectedToInternet.rawValue
    }
}
