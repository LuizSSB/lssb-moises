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
