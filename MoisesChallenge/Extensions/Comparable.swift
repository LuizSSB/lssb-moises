//
//  Comparable.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
