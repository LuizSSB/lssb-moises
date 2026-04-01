//
//  Collection.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
