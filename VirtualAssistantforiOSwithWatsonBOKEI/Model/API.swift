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
    case delete = "delete"
}

protocol Update: class {
    func authUser(with completion: @escaping Completion<Result>)
    func updateUser()
    func send(message: String)
}

typealias Completion<T> = (T) -> Void
typealias Result = (success:Bool, error: Error?)

class API {

    weak var delegate: Update?

    var latestTransaction: Transaction?

    func fetch(with data: [String : AssistantV1.JSON]?) {
        // Check action
        guard let data = data,
            let key = data.keys.first,
            let json = data[key],
            let action = Action(rawValue: key) else { return }
        switch action {
        case .account:
            switch json {
            case let .string(v):
                if v != "" {
                    lastTransaction(for: v)
                }
            default: return
            }
        case .data:

            switch json {
            case let .string(v):
                if v == "show" {
                    getUserData(with: "12345678901234")
                } else if v == "edit" {
                    DispatchQueue.main.async {
                        self.delegate?.updateUser()
                    }
                }
            default: return
            }
        case .delete:
            if let transaction = latestTransaction {
                switch json {
                case let .string(v):
                    if v == "yes" {
                        delegate?.authUser(with: { [weak self] (result) in
                            if result.success {
                                self?.delete(latestTransaction: transaction)
                            } else {
                                self?.delegate?.send(message: "Authentification failed transaction will not be deleted!")
                            }
                        })
                    }
                default: return
                }
            }

        }
    }

    // MARK: - Private

    private func lastTransaction(for account: String) {
        Alamofire.request("https://bankjenny.eu-de.mybluemix.net/api/bank/jenny/iban", method: .post, parameters: ["iban": account])
            .responseJSON { [weak self] (data) in
                switch data.result {
                case let .success(v):
                    guard let result = v as? [String: Any] else { return }
                    if let key = result.keys.first, key == "failure", let error = result[key] as? String {
                        self?.delegate?.send(message: error)
                    } else {
                        let transaction = Transaction(data: result)
                        self?.latestTransaction = transaction
                        self?.delegate?.send(message: transaction.transactionMessage() + "\n Please approve deleting this transaction !")
                    }
                case let .failure(error):
                    print("Some error !\(error)")
                }
        }
    }

    private func delete(latestTransaction: Transaction) {
        Alamofire.request("https://bankjenny.eu-de.mybluemix.net/api/bank", method: .delete, parameters: ["transactionNb": latestTransaction.transactionNumber ?? ""])
            .responseData(completionHandler: { [weak self] (data) in
                if let error = data.error {
                    print("Some error !\(error)")
                } else {
                    self?.delegate?.send(message: "Successfully deleted latest transacation!")
                }
            })
    }

    private func getUserData(with indetificationNumber: String) {
        Alamofire.request("https://bankjenny.eu-de.mybluemix.net/api/bank/jenny", method: .get, parameters: ["nin": indetificationNumber])
            .responseJSON { [weak self] (data) in
                switch data.result {
                case let .success(v):
                    guard let result = v as? [String: Any] else { return }
                    let userData = User(data: result)
                    self?.delegate?.send(message: userData.message())
                case let .failure(error):
                    print("Some error !\(error)")
                }
        }
    }

    // MARK: - Internal

    func upload(data: String) {
        Alamofire.request("https://bankjenny.eu-de.mybluemix.net/api/bank/jenny?nin=12345678901234&fn=DanielWMihai&ln=Mandea", method: .put, parameters: ["nin":"12345678901234", "fn": "Daniel Mihai", "ln": "Mandea"])
            .responseJSON { [weak self] (data) in
                switch data.result {
                case let .success(v):
                    guard let result = v as? [String: Any] else { return }
                    let userData = User(data: result)
                    self?.delegate?.send(message: "Successfully updated your data!\n" + userData.message())
                case let .failure(error):
                    print("Some error !\(error)")
                }
        }
    }
}
