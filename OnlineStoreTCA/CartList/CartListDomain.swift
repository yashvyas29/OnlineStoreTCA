//
//  CartListDomain.swift
//  OnlineStoreTCA
//
//  Created by Pedro Rojas on 18/08/22.
//

import Foundation
import ComposableArchitecture

struct CartListDomain: Reducer {
    @Dependency(\.apiClient) var apiClient

    struct State: Equatable {
        var dataLoadingStatus = DataLoadingStatus.notStarted
        var cartItems: IdentifiedArrayOf<CartItemDomain.State> = []
        var totalPrice: Double = 0.0
        var isPayButtonHidden = false

        var totalPriceString: String {
            let roundedValue = round(totalPrice * 100) / 100.0
            return "$\(roundedValue)"
        }

        init(cartItems: IdentifiedArrayOf<CartItemDomain.State>) {
            self.cartItems = cartItems
        }

        var isRequestInProcess: Bool {
            dataLoadingStatus == .loading
        }

        @PresentationState var destination: Destination.State?
    }

    enum Action: Equatable {
        case didPressCloseButton
        case didReceivePurchaseResponse(TaskResult<String>)
        case getTotalPrice
        case didPressPayButton
        case dismissSuccessAlert
        case dismissErrorAlert
        case deleteCartItem(id: CartItemDomain.State.ID)
        case cartItem(id: CartItemDomain.State.ID, action: CartItemDomain.Action)
        case destination(PresentationAction<Destination.Action>)

        enum Alert: Equatable {
            case didConfirmPurchase
            case didCancelConfirmation
        }
    }

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .didPressCloseButton:
                return .none
            case .didReceivePurchaseResponse(.success(let message)):
                state.dataLoadingStatus = .success
                state.destination = .successAlert(
                    AlertState(
                        title: TextState("Thank you!"),
                        message: TextState("Your order is in process."),
                        buttons: [
                            .default(TextState("Done"), action: .send(.dismissSuccessAlert))
                        ]
                    )
                )
                print("Success: \(message)")
                return .none
            case .didReceivePurchaseResponse(.failure):
                state.dataLoadingStatus = .error
                print("Unable to send order")
                state.destination = .errorAlert(
                    AlertState(
                        title: TextState("Oops!"),
                        message: TextState("Unable to send order, try again later."),
                        buttons: [
                            .default(TextState("Done"), action: .send(.dismissErrorAlert))
                        ]
                    )
                )
                return .none
            case .getTotalPrice:
                let items = state.cartItems.map { $0.cartItem }
                state.totalPrice = items.reduce(0.0, {
                    $0 + ($1.product.price * Double($1.quantity))
                })
                return verifyPayButtonVisibility(state: &state)
            case .didPressPayButton:
                state.destination = .confirmationAlert(
                    AlertState(
                        title: TextState("Confirm your purchase"),
                        message: TextState("Do you want to proceed with your purchase of \(state.totalPriceString)?"),
                        buttons: [
                            .default(
                                TextState("Pay \(state.totalPriceString)"),
                                action: .send(.didConfirmPurchase)),
                            .cancel(TextState("Cancel"), action: .send(.didCancelConfirmation))
                        ]
                    )
                )
                return .none
            case .dismissSuccessAlert:
                state.destination = nil
                return .none
            case .dismissErrorAlert:
                state.destination = nil
                return .none
            case .cartItem(let id,let action):
                switch action {
                case .deleteCartItem:
                    return .send(.deleteCartItem(id: id))
                }
            case .deleteCartItem(let id):
                state.cartItems.remove(id: id)
                return .send(.getTotalPrice)
            case .destination(.presented(.confirmationAlert(.didConfirmPurchase))):
                state.dataLoadingStatus = .loading
                let items = state.cartItems.map { $0.cartItem }
                return .run { send in
                    let result = await TaskResult {
                        try await apiClient.sendOrder(items)
                    }
                    await send(.didReceivePurchaseResponse(result))
                }
            case .destination:
                state.destination = nil
                return .none
            }
        }
        .forEach(\.cartItems, action: /Action.cartItem) {
            CartItemDomain()
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }

    private func verifyPayButtonVisibility(
        state: inout State
    ) -> Effect<Action> {
        state.isPayButtonHidden = state.totalPrice == 0.0
        return .none
    }
}

extension CartListDomain {
    struct Destination: Reducer {
        enum State: Equatable {
            case confirmationAlert(AlertState<CartListDomain.Action.Alert>)
            case successAlert(AlertState<CartListDomain.Action>)
            case errorAlert(AlertState<CartListDomain.Action>)
        }
        enum Action: Equatable {
            case confirmationAlert(CartListDomain.Action.Alert)
            case successAlert(CartListDomain.Action)
            case errorAlert(CartListDomain.Action)
        }
        var body: some ReducerOf<Self> {
            Reduce<State, Action> { _, _ in
                return .none
            }
        }
    }
}
