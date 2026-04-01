//
//  ActionStatus.swift
//  SFR3
//
//  Created by Luiz SSB on 19/04/25.
//

enum ActionStatus<
    TResult: Equatable & Hashable,
    TError: Equatable & Hashable
>: Equatable, Hashable {
    case none,
         running,
         success(TResult),
         failure(TError)
}

extension ActionStatus {
    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }
    
    var result: TResult? {
        if case let .success(result) = self {
            return result
        }
        return nil
    }
}
