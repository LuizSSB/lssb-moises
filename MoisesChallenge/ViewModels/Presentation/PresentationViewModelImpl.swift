//
//  PresentationViewModelImpl.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 01/04/26.
//

import Observation

@Observable
class PresentationViewModelImpl<T>: PresentationViewModel {
    private(set) var presented: T?
    
    func present(_ value: T) {
        presented = value
    }
    
    func onDismiss() {
        presented = nil
    }
}
