//
//  Task.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 02/04/26.
//

extension TaskGroup {
    mutating func allResults() async -> [ChildTaskResult] {
        return await reduce(into: [ChildTaskResult]()) { partialResult, name in
            partialResult.append(name)
        }
    }
}
