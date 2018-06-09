//
//  API.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/9/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import Alamofire
import AssistantV1

enum Action: String {

    case account = "account"
    case data = "data"
}

protocol Update: class {

    func send(message: String)
}

class API {

    weak var delegate: Update?

    func fetch(with data: [String : AssistantV1.JSON]?) {
        // Check action
        guard let data = data, let key = data.keys.first, let json = data[key], let action = Action(rawValue: key) else { return }

        switch action {
        case .account:
            lastTransaction(for: json)
            DispatchQueue.main.async {
                self.delegate?.send(message: "Please wait fetching data ")
            }
        case .data:
            delegate?.send(message: "Helo World")
        }

    }


    private func lastTransaction(for account: JSON) {
        switch account {
        case let .string(v):
            Alamofire.request("https://bankjenny.eu-de.mybluemix.net/api/bank/jenny/iban", method: .post, parameters: ["iban": v])
                .responseJSON { (data) in

                    print(data)

            }
        default:
            return
        }
    }



}
