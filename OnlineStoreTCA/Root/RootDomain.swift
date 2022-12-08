//
//  RootDomain.swift
//  OnlineStoreTCA
//
//  Created by Pedro Rojas on 24/08/22.
//

import Foundation
import ComposableArchitecture

struct RootDomain: ReducerProtocol {
    struct State: Equatable {
        var selectedTab = Tab.products
        var productListState = ProductListDomain.State()
        var profileState = ProfileDomain.State()
    }
    
    enum Tab {
        case products
        case profile
    }
    
    enum Action: Equatable {
        case tabSelected(Tab)
        case productList(ProductListDomain.Action)
        case profile(ProfileDomain.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.productListState, action: /Action.productList) {
            ProductListDomain()
        }
        Scope(state: \.profileState, action: /Action.profile) {
            ProfileDomain()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .productList:
                return .none
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
            case .profile:
                return .none
            }
        }
    }
}
