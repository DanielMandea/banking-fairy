//
//  Transaction.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/10/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation


struct Transaction {

    var sender: String?
    var receiver: String?
    var currency: String?
    var amount: Int?
    var transactionNumber: String?

    init(data: [String: Any]) {
        amount = data["amount"] as? Int
        currency = data["currency"] as? String
        if let senderData = data["sender"] as? [String: Any] {
            sender = senderData["iban"] as? String
        }
        if let senderData = data["receiver"] as? [String: Any] {
            receiver = senderData["iban"] as? String
        }
        transactionNumber = data["transactionNb"] as? String
    }

    func transactionMessage() -> String {
        return "Transaction nr \(transactionNumber ?? "") from account \(sender ?? "") to account \(receiver ?? ""), currency \(currency ?? "") and amount \(amount ?? 0)."
    }
}
