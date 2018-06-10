//
//  ConversationViewModel.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/9/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import AssistantV1
import MessageKit
import BMSCore

protocol ConversationView: MeesagesView {
    func showAlert(with error: AssistantError)
    func setMessage(with text: String)
    func animate(with message: String?)
    func failAssistantWithError(_ error: Error)
    func insertItemAtBottom()
    func authUser(with completion: @escaping Completion<Result>)
    func uploadData()
}

protocol MeesagesView: class {
    // Messages interaction
    func reloadData()
    func scrollToBottom()
    func stopAnimating()
}

class ConversationViewModel {

    weak var delegate: ConversationView?

    var messageList: [AssistantMessages] = []
    var now = Date()
    var assistant: Assistant?
    var context: Context?
    var workspaceID: String?
    var current: Sender!
    var watson: Sender!
    var api: API

    init(api: API) {
        current = Sender(id: "123456", displayName: "You")
        watson =  Sender(id: "654321", displayName: "Jane")
        self.api = api
        api.delegate = self
    }

    // MARK: - Setup Methods

    // Method to instantiate assistant service
    func instantiateAssistant() {
        // Start activity indicator
        delegate?.animate(with: "Connecting to Jane")
        // Create a configuration path for the BMSCredentials.plist file then read in the Watson credentials
        // from the plist configuration dictionary
        guard let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
            let configuration = NSDictionary(contentsOfFile: configurationPath) else {
                delegate?.showAlert(with: .missingCredentialsPlist)
                return
        }

        // Set the Watson credentials for Assistant service from the BMSCredentials.plist
        guard let password = configuration["conversationPassword"] as? String,
            let username = configuration["conversationUsername"] as? String,
            let url = configuration["conversationUrl"] as? String else {
                delegate?.showAlert(with: .missingAssistantCredentials)
                return
        }

        // API Version Date to initialize the Assistant API
        let date = "2018-02-01"

        // Initialize Watson Assistant object
        let assistant = Assistant(username: username, password: password, version: date)

        // Set the URL for the Assistant Service
        assistant.serviceURL = url

        self.assistant = assistant

        // Lets Handle the Workspace creation or selection from here.
        // If a workspace is found in the plist then use that WorkspaceID that is provided , otherwise
        // look up one from the service directly, Watson provides a sample so this should work directly
        if let workspaceID = configuration["workspaceID"] as? String {
            print("Workspace ID:", workspaceID)
            // Set the workspace ID Globally
            self.workspaceID = workspaceID
            // Ask Watson for its first message
            retrieveFirstMessage()
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) { [weak self] in
                self?.delegate?.setMessage(with: "Checking for Training...")
            }
            // Retrieve a list of Workspaces that have been trained and default to the first one
            // You can define your own WorkspaceID if you have a specific Assistant model you want to work with
            assistant.listWorkspaces(failure: failAssistantWithError,
                                     success: workspaceList)
        }
    }

    // Retrieves the first message from Watson
    func retrieveFirstMessage() {

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) { [weak self] in
            self?.delegate?.setMessage(with: "Talking to Jane ....")
        }
        guard let assistant = self.assistant else {
            delegate?.showAlert(with: .missingAssistantCredentials)
            return
        }
        guard let workspace = workspaceID else {
            delegate?.showAlert(with: .noWorkspaceId)
            return
        }
        // Initial assistant message from Watson
        assistant.message(workspaceID: workspace, failure: failAssistantWithError) { response in

            for watsonMessage in response.output.text {

                // Set current context
                self.context = response.context

                DispatchQueue.main.async {

                    // Add message to assistant message array
                    let uniqueID = UUID().uuidString
                    let date = self.dateAddingRandomTime()

                    let attributedText = NSAttributedString(string: watsonMessage,
                                                            attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                                         .foregroundColor: UIColor.blue])

                    // Create a Message for adding to the Message View
                    let message = AssistantMessages(attributedText: attributedText, sender: self.watson, messageId: uniqueID, date: date)

                    // Add the response to the Message View
                    self.messageList.insert(message, at: 0)
                    self.delegate?.reloadData()
                    self.delegate?.scrollToBottom()
                    self.delegate?.stopAnimating()
                }
            }
        }
    }


    func sendMessage(with text: String) {

        guard let assist = assistant else {
            delegate?.showAlert(with: .missingAssistantCredentials)
            return
        }
        guard let workspace = workspaceID else {
            delegate?.showAlert(with: .noWorkspaceId)
            return
        }

        let attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
        let id = UUID().uuidString
        let message = AssistantMessages(attributedText: attributedText, sender: current, messageId: id, date: Date())
        messageList.append(message)
        delegate?.insertItemAtBottom()
        // cleanup text that gets sent to Watson, which doesn't care about whitespace or newline characters
        let cleanText = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: ". ")
        // Lets pass the indent to Watson Assistant and see what the response is ?
        // Get response from Watson based on user text create a message Request first
        let messageRequest = MessageRequest(input: InputData(text:cleanText), context: self.context)
        // Call the Assistant API
        assist.message(workspaceID: workspace, request: messageRequest, failure: failAssistantWithError) { [weak self] response in
            self?.api.fetch(with: response.context.additionalProperties)
            for watsonMessage in response.output.text {
                guard !watsonMessage.isEmpty else {
                    continue
                }
                // Set current context
                self?.context = response.context
                DispatchQueue.main.async {

                    let attributedText = NSAttributedString(string: watsonMessage, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
                    let id = UUID().uuidString
                    let message = AssistantMessages(attributedText: attributedText, sender: (self?.watson)!, messageId: id, date: Date())
                    self?.messageList.append(message)
                    self?.delegate?.insertItemAtBottom()
                }
            }
        }
    }

    // Method to handle errors with Watson Assistant
    func failAssistantWithError(_ error: Error) {
        delegate?.showAlert(with:.error(error.localizedDescription))
    }

    // Method to start convesation from workspace list
    func workspaceList(_ list: WorkspaceCollection) {
        // Lets see if the service has any training model deployed
        guard let workspace = list.workspaces.first else {
            delegate?.showAlert(with: .noWorkspacesAvailable)
            return
        }
        // Check if we have a workspace ID
        guard !workspace.workspaceID.isEmpty else {
            delegate?.showAlert(with: .noWorkspaceId)
            return
        }
        // Now we have an WorkspaceID we can ask Watson Assisant for its first message
        self.workspaceID = workspace.workspaceID
        // Ask Watson for its first message
        retrieveFirstMessage()
    }

    // Method to create a random date
    private func dateAddingRandomTime() -> Date {
        let randomNumber = Int(arc4random_uniform(UInt32(10)))
        var date: Date?
        if randomNumber % 2 == 0 {
            date = Calendar.current.date(byAdding: .hour, value: randomNumber, to: now) ?? Date()
        } else {
            let randomMinute = Int(arc4random_uniform(UInt32(59)))
            date = Calendar.current.date(byAdding: .minute, value: randomMinute, to: now) ?? Date()
        }
        now = date ?? Date()
        return now
    }


    // MARK: - Actions

    func uploadScannedData(data: String) {
        delegate?.authUser(with: { (result) in
            if result.success {
                self.api.upload(data: data)
            }
        })
    }
}

// MARK: - Update

extension ConversationViewModel: Update {

    func updateUser() {
        delegate?.uploadData()
    }

    func authUser(with completion: @escaping Completion<Result>) {
        delegate?.authUser(with: completion)
    }

    func send(message: String) {
        let attributedText = NSAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.blue])
        let id = UUID().uuidString
        let message = AssistantMessages(attributedText: attributedText, sender: watson, messageId: id, date: Date())
        messageList.append(message)
        delegate?.insertItemAtBottom()
    }

}
