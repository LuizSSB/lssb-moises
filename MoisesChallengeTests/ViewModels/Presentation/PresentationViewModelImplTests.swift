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
        // ARRANGE
        let viewModel = PresentationViewModelImpl<Int>()

        // ACT

        // ASSERT
        #expect(viewModel.presented == nil)
    }

    @Test func present_setsPresentedValue() {
        // ARRANGE
        let viewModel = PresentationViewModelImpl<Int>()

        // ACT
        viewModel.present(42)

        // ASSERT
        #expect(viewModel.presented == 42)
    }

    @Test func present_replacesPreviouslyPresentedValue() {
        // ARRANGE
        let viewModel = PresentationViewModelImpl<Int>()
        viewModel.present(1)

        // ACT
        viewModel.present(2)

        // ASSERT
        #expect(viewModel.presented == 2)
    }

    @Test func dismiss_clearsPresentedValue() {
        // ARRANGE
        let viewModel = PresentationViewModelImpl<Int>()
        viewModel.present(42)

        // ACT
        viewModel.dismiss()

        // ASSERT
        #expect(viewModel.presented == nil)
    }
}
