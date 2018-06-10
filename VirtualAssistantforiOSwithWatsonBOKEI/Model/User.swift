
//
//  User.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/10/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

struct User {

    var firstName: String?
    var lastName: String?
    var accounts: Array<String>?
    var nin: String?

    init(data: [String: Any]) {
        firstName = data["firstName"] as? String
        lastName = data["lastName"] as? String
        accounts = [String]()
        if let accountsData = data["accounts"] as? [String: Any], let ibans = accountsData["ibans"] as? [[String: Any]] {
            for account in ibans {
                if let iban = account["iban"] as? String {
                    accounts?.append(iban)
                }
            }
        }
        if let ninData = data["niN"] as? [String: Any] {
            nin = ninData["nin"] as? String
        }
    }

    func message() -> String {
        return "User with first name \(firstName ?? ""), last name \(lastName ?? "") main account \(accounts?.first ?? "No account") and identification number \(nin ?? "")"
    }
}
