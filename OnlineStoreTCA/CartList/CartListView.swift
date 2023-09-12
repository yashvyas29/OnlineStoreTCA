//
//  CartListView.swift
//  OnlineStoreTCA
//
//  Created by Pedro Rojas on 18/08/22.
//

import SwiftUI
import ComposableArchitecture

struct CartListView: View {
    let store: StoreOf<CartListDomain>
    @ObservedObject var viewStore: ViewStoreOf<CartListDomain>
    
    init(store: StoreOf<CartListDomain>) {
        self.store = store
        self.viewStore = ViewStore(self.store, observe: {$0})
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                List {
                    ForEachStore(
                        self.store.scope(
                            state: \.cartItems,
                            action: CartListDomain.Action.cartItem
                        )
                    ) {
                        CartCell(store: $0)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            viewStore.send(.didPressCloseButton)
                        } label: {
                            Text("Close")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        viewStore.send(.didPressPayButton)
                    } label: {
                        HStack(alignment: .center) {
                            Spacer()
                            Text("Pay \(viewStore.totalPriceString)")
                                .font(.custom("AmericanTypewriter", size: 30))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(.blue)
                    .cornerRadius(10)
                    .padding()
                    .opacity(viewStore.isPayButtonHidden ? 0 : 1)
                }
                .onAppear {
                    viewStore.send(.getTotalPrice)
                }
                .navigationTitle("Cart")
                .alert(store: store.scope(
                    state: \.$confirmationAlert,
                    action: { _ in .didCancelConfirmation }))
                .alert(store: store.scope(
                    state: \.$successAlert,
                    action: { _ in .dismissSuccessAlert }))
                .alert(store: store.scope(
                    state: \.$errorAlert,
                    action: { _ in .dismissErrorAlert }))
            }
            if viewStore.isRequestInProcess {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView()
            } else if viewStore.cartItems.isEmpty {
                Text("Oops, your cart is empty! \n")
                    .font(.custom("AmericanTypewriter", size: 25))
            }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartListView(
            store: Store(
                initialState: CartListDomain.State(
                    cartItems: IdentifiedArrayOf(
                        uniqueElements: CartItem.sample
                            .compactMap {
                                CartItemDomain.State(
                                    id: UUID(),
                                    cartItem: $0
                                )
                            }
                    )
                ),
                reducer: CartListDomain.init
            )
        )
    }
}
