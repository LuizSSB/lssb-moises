//
//  Alamofire.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

import Alamofire
import Foundation

func parseAF(error: Error) -> Error {
    if let afError = error as? AFError,
       case let .sessionTaskFailed(underlyingError) = afError
    {
        return underlyingError
    }

    return error
}
