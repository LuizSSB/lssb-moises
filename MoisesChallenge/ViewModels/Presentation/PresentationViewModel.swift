//
//  PresentationViewModel.swift
//  MoisesChallenge
//
//  Created by Luiz SSB on 03/04/26.
//

@MainActor
protocol PresentationViewModel<Value>: AnyObject {
    associatedtype Value
    
    var presented: Value? { get }
    
    func present(_ value: Value)
    func onDismiss()
}
