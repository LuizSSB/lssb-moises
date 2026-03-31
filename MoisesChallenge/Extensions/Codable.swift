//
//  Codable.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 20/04/25.
//

import Foundation

enum JSONCodingError: Error {
    case encoding(any Encodable & Sendable),
         decoding(String)
}

extension Encodable where Self: Sendable {
    func asJSON(encoder: JSONEncoder = .init()) throws -> String {
        let jsonData = try encoder.encode(self)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8)
        else { throw JSONCodingError.encoding(self) }
        
        return jsonString
    }
}


extension Decodable {
    init(jsonLikeObject: [String:Any], decoder: JSONDecoder = .init()) throws {
        let data = try JSONSerialization.data(
            withJSONObject: jsonLikeObject,
            options: []
        )
        let decoded = try decoder.decode(Self.self, from: data)
        self = decoded
    }
    
    init(jsonString: String, decoder: JSONDecoder = .init()) throws {
        guard let jsonData = jsonString.data(using: .utf8)
        else { throw JSONCodingError.decoding(jsonString) }
        
        let decoded = try decoder.decode(Self.self, from: jsonData)
        self = decoded
    }
}
