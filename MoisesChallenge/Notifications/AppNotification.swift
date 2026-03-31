//
//  AppNotification.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 21/04/25.
//

import Foundation

protocol AppNotification: Equatable, Codable, Sendable {
}

extension AppNotification {
    static var notificationName: Notification.Name {
        .init(String(describing: Self.self))
    }
}
