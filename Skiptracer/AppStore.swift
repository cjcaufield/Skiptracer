//
//  AppStore.swift
//  Skiptracer
//
//  Created by Colin Caufield on 4/16/15.
//  Copyright (c) 2015 Secret Geometry, Inc. All rights reserved.
//

import UIKit
import StoreKit

private var _shared: AppStore? = nil

class AppStore: NSObject, SKRequestDelegate, SKProductsRequestDelegate {
    
    class var shared: AppStore {
        if _shared == nil {
            _shared = AppStore()
        }
        return _shared!
    }
    
    let proUpgradeProductID = "SkipTracerPro"
    
    func hasProUpgrade() -> Bool {
        return false
    }
    
    func purchaseProUpgrade() -> Bool {
        return self.purchase(self.proUpgradeProductID)
    }
    
    func canPurchase() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    func purchase(productID: String) -> Bool {
        return self.beginPurchase(productID)
    }
    
    func beginPurchase(productID: String) -> Bool {
        
        if !self.canPurchase() {
            return false
        }
        
        var productIDs = Set<NSObject>(arrayLiteral: [productID])
        var request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
        return true
    }
    
    func completePurchase(product: SKProduct) -> Bool {
    
        if !self.canPurchase() {
            return false
        }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
        return true
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        
        if response.products.count > 0 {
            
            var product = response.products[0] as! SKProduct
            
            if product.productIdentifier == self.proUpgradeProductID {
                
                let title = product.localizedTitle
                let description = product.localizedDescription
                let price = product.price
                
                completePurchase(product)
            }
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        
        for possibleTransaction in transactions {
            
            if let transaction = possibleTransaction as? SKPaymentTransaction {
                
                switch transaction.transactionState {
                        
                    case .Purchased:
                        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                        
                    case .Failed:
                        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                        
                    // case .Restored:
                    //     self.restoreTransaction(transaction)
                        
                    default:
                        break
                }
            }
        }
    }
    
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        // handle error
    }
}
