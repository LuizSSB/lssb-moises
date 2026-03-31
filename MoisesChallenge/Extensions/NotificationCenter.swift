//
//  NotificationCenter.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 21/04/25.
//

import Foundation

extension NotificationCenter {
    func post<TNotification: AppNotification>(_ notification: TNotification) {
        NotificationCenter.default.post(
            name: TNotification.notificationName,
            object: notification
        )
    }
    
    func addObserver<TNotification: AppNotification>(
        _ handler: @escaping @Sendable (TNotification) -> Void
    ) -> Any {
        return NotificationCenter.default.addObserver(
            forName: TNotification.notificationName,
            object: nil,
            queue: .main
        ) { notification in
            guard let notification = notification.object as? TNotification else { return }
            handler(notification)
        }
    }
}
