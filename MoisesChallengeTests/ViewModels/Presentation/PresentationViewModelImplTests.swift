//
//  PresentationViewModelImplTests.swift
//  MoisesChallengeTests
//
//  Created by Codex on 04/04/26.
//

import Testing
@testable import MoisesChallenge

@MainActor
struct PresentationViewModelImplTests {

    @Test func init_startsWithNilPresentedValue() {
        let viewModel = PresentationViewModelImpl<Int>()

        #expect(viewModel.presented == nil)
    }

    @Test func present_setsPresentedValue() {
        let viewModel = PresentationViewModelImpl<Int>()

        viewModel.present(42)

        #expect(viewModel.presented == 42)
    }

    @Test func present_replacesPreviouslyPresentedValue() {
        let viewModel = PresentationViewModelImpl<Int>()
        viewModel.present(1)

        viewModel.present(2)

        #expect(viewModel.presented == 2)
    }

    @Test func dismiss_clearsPresentedValue() {
        let viewModel = PresentationViewModelImpl<Int>()
        viewModel.present(42)

        viewModel.dismiss()

        #expect(viewModel.presented == nil)
    }
}
