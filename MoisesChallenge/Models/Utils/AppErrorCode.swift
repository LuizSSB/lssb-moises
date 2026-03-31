//
//  ErrorCode.swift
//  SFR3
//
//  Created by Luiz SSB on 20/04/25.
//

enum AppErrorCode: Int, Codable, Error {
    case unknown = -1
    
    case invalidFormat = 100
}
