# StoreKit 2 Demo App with iaptic Integration

This demo project showcases how to integrate and implement Apple's StoreKit 2 framework with [iaptic](https://www.iaptic.com/) (formerly Fovea.Billing) for secure server-side validation of in-app purchases in iOS applications.

This uses the [iaptic-storekit2](https://github.com/iaptic/iaptic-storekit2) package.

## Overview

StoreKit 2 is Apple's latest framework for handling in-app purchases, providing a modern Swift API with async/await support. This demo app demonstrates how to:

- Load and display products from the App Store
- Handle purchases with StoreKit 2
- Validate transactions using iaptic's server-side validation service
- Observe transaction updates
- Restore purchases
- Manage user entitlements

## Features

- ✅ Modern SwiftUI interface
- ✅ StoreKit 2 integration with async/await API
- ✅ Server-side transaction validation with iaptic
- ✅ Transaction verification using JWS (JSON Web Signatures)
- ✅ Subscription management
- ✅ Entitlement tracking
- ✅ Comprehensive logging for debugging

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- An iaptic account (for server-side validation)

## Project Structure

- **SubscriptionsManager**: Handles product fetching, purchases, and transaction validation
- **EntitlementManager**: Manages user access to premium features
- **ContentView**: UI for displaying products and purchase options

## Setting Up

1. Clone this repository
2. Open the project in Xcode
3. Update the iaptic configuration in `SubscriptionsManager.swift` with your own details:
   ```swift
   self.iaptic = Iaptic(
       appName: "YOUR_APP_NAME",
       publicKey: "YOUR_PUBLIC_KEY"
   )
   ```
4. Configure your StoreKit products in App Store Connect
5. For testing, you can use StoreKit testing configuration

## Using iaptic for Validation

This demo uses iaptic to handle server-side validation of StoreKit transactions. Key benefits include:

- Secure validation without complex server implementation
- Cross-platform support for your purchase system
- Protection against common hacking attempts
- Dashboard for monitoring purchases
- Subscription status management

## StoreKit 2 vs StoreKit 1

StoreKit 2 offers significant improvements over the original StoreKit:

- Async/await API for simpler code
- Built-in receipt validation
- JWS transaction verification
- Automatic transaction syncing across devices
- More reliable transaction handling
- Entitlement status information on-device

## Implementation Details

The app demonstrates:

1. **Product Loading**:
   ```swift
   func loadProducts() async {
       do {
           self.products = try await Product.products(for: productIDs)
               .sorted(by: { $0.price > $1.price })
       } catch {
           print("❌ Failed to fetch products!")
       }
   }
   ```

2. **Purchase Handling**:
   ```swift
   func buyProduct(_ product: Product) async {
       // Purchase implementation using StoreKit 2
   }
   ```

3. **Transaction Verification**:
   ```swift
   func verifyWithIaptic(jwsRepresentation: String, productID: String) async {
       // Server-side validation with iaptic
   }
   ```

4. **Transaction Observation**:
   ```swift
   func observeTransactionUpdates() -> Task<Void, Never> {
       // Observing transaction updates with StoreKit 2
   }
   ```

5. **Restoring Purchases**:
   ```swift
   func restorePurchases() async {
       // Restore implementation
   }
   ```

## Debug Logging

The application includes extensive debug logging to help you understand the StoreKit 2 workflow:

- 🚀 Initialization logs
- 📦 Purchase process logs
- ✅ Verification logs
- 🔄 Restoration logs

## Additional Resources

- [iaptic Documentation](https://www.iaptic.com/documentation)
- [Apple's StoreKit Documentation](https://developer.apple.com/documentation/storekit)

## License

This demo project is available under the MIT license. 