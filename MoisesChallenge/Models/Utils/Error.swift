//
//  Error.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

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
