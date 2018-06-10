/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import NVActivityIndicatorView
import AssistantV1
import MessageKit
import MapKit
import BMSCore
import LocalAuthentication

class ConversationViewController: MessagesViewController, NVActivityIndicatorViewable {

    // UIButton to initiate login
    @IBOutlet weak var logoutButton: UIButton!

    fileprivate let kCollectionViewCellHeight: CGFloat = 12.5
    var viewModel: ConversationViewModel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Instantiate Assistant Instance
        viewModel.delegate = self
        viewModel.instantiateAssistant()
        // Instantiate activity indicator
        self.instantiateActivityIndicator()
        // Registers data sources and delegates + setup views
        self.setupMessagesKit()
        // Register observer
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func didBecomeActive(_ notification: Notification) {
        
        
    }

    // Method to set up the activity progress indicator view
    func instantiateActivityIndicator() {
        let size: CGFloat = 50
        let x = self.view.frame.width/2 - size
        let y = self.view.frame.height/2 - size

        let frame = CGRect(x: x, y: y, width: size, height: size)

        _ = NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballScaleRipple)
    }

    // Method to set up messages kit data sources and delegates + configure
    func setupMessagesKit() {

        // Register datasources and delegates
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self

        // Configure views
        messageInputBar.sendButton.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        scrollsToBottomOnKeybordBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
    }

    // Method to retrieve assistant avatar
    func getAvatarFor(sender: Sender) -> Avatar {
        switch sender {
        case viewModel.current:
            return Avatar(image: UIImage(named: "avatar_small"), initials: "GR")
        case viewModel.watson:
            return Avatar(image: UIImage(named: "watson_avatar"), initials: "WAT")
        default:
            return Avatar()
        }
    }

    // MARK: - IBActions

    @IBAction func gatherUserData(_ sender: UIBarButtonItem) {
        uploadData()
    }


    @IBAction func showLocation(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showMap", sender: nil)
    }

    @IBAction func saveUnwindToChat(segue: UIStoryboardSegue) {
        if let destination = segue.source as? ViewController, let text = destination.detectedText.text {
            viewModel.uploadScannedData(data: text)
        }
    }
}

// MARK: - MessagesDataSource
extension ConversationViewController: MessagesDataSource {

    func currentSender() -> Sender {
        return viewModel.current
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messageList[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {

        struct AssistantDateFormatter {
            static let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter
            }()
        }
        let formatter = AssistantDateFormatter.formatter
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }

}

// MARK: - MessagesDisplayDelegate
extension ConversationViewController: MessagesDisplayDelegate {

    // MARK: - Text Messages

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }

    // MARK: - All Messages

    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {

        let avatar = getAvatarFor(sender: message.sender)
        avatarView.set(avatar: avatar)
    }

    // MARK: - Location Messages
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        let annotationView = MKAnnotationView(annotation: nil, reuseIdentifier: nil)
        let pinImage = #imageLiteral(resourceName: "pin")
        annotationView.image = pinImage
        annotationView.centerOffset = CGPoint(x: 0, y: -pinImage.size.height / 2)
        return annotationView
    }

    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(0, 0, 0)
            view.alpha = 0.0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1.0
            }, completion: nil)
        }
    }
}

// MARK: - MessagesLayoutDelegate
extension ConversationViewController: MessagesLayoutDelegate {

    func avatarPosition(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> AvatarPosition {
        return AvatarPosition(horizontal: .natural, vertical: .messageBottom)
    }

    func messagePadding(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
        } else {
            return UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
        }
    }

    func cellTopLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        } else {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        }
    }

    func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
        if isFromCurrentSender(message: message) {
            return .messageLeading(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0))
        } else {
            return .messageTrailing(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }

    func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {

        return CGSize(width: messagesCollectionView.bounds.width, height: 10)
    }

    // MARK: - Location Messages

    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }

}

// MARK: - MessageCellDelegate

extension ConversationViewController: MessageCellDelegate {

    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }

    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }

    func didTapTopLabel(in cell: MessageCollectionViewCell) {
        print("Top label tapped")
    }

    func didTapBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

}

// MARK: - MessageLabelDelegate

extension ConversationViewController: MessageLabelDelegate {

    func didSelectAddress(_ addressComponents: [String : String]) {
        print("Address Selected: \(addressComponents)")
        performSegue(withIdentifier: "showMap", sender: addressComponents)
    }

    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }

    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }

    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }

}

// MARK: - MessageInputBarDelegate

extension ConversationViewController: MessageInputBarDelegate {

    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        viewModel.sendMessage(with: text)
        inputBar.inputTextView.text = String()
    }

}

// MARK: - ConversationView

extension ConversationViewController: ConversationView {

    func uploadData() {
        performSegue(withIdentifier: "uploadProfile", sender: nil)
    }

    func authUser(with completion: @escaping Completion<Result>) {
        let context = LAContext()

        var error: NSError?

        if context.canEvaluatePolicy(
            LAPolicy.deviceOwnerAuthenticationWithBiometrics,
            error: &error) {
            // Device can use biometric authentication
            context.evaluatePolicy(
                LAPolicy.deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access requires authentication",
                reply: {(success, error) in
                    DispatchQueue.main.async {

                        if let err = error {

                            switch err._code {
                            case LAError.Code.systemCancel.rawValue:
                                completion((false, error))
                            case LAError.Code.userCancel.rawValue:
                                completion((false, error))
                            case LAError.Code.userFallback.rawValue:
                                completion((false, error))
                            default:
                                completion((false, nil))
                            }

                        } else {
                            completion((true, nil))
                        }
                    }
            })

        } else {
            // Device cannot use biometric authentication
            completion((false, error))
        }
    }

    func failAssistantWithError(_ error: Error) {
        showAlert(with:.error(error.localizedDescription))
    }

    func setMessage(with text: String) {
        NVActivityIndicatorPresenter.sharedInstance.setMessage(text)
    }

    func animate(with message: String?) {
        // Start activity indicator
        startAnimating( message: message, type: NVActivityIndicatorType.ballScaleRipple)
    }

    func insertItemAtBottom() {
        let section = viewModel.messageList.count - 1
        messagesCollectionView.insertSections([section])
        messagesCollectionView.scrollToBottom()
    }

    func reloadData() {
        self.messagesCollectionView.reloadData()
    }

    func scrollToBottom() {
        self.messagesCollectionView.scrollToBottom()
    }

    // Method to show an alert with an alertTitle String and alertMessage String
    func showAlert(with error: AssistantError) {
        DispatchQueue.main.async {
            // Stop animating if necessary
            self.stopAnimating()
            // If an alert is not currently being displayed
            if self.presentedViewController == nil {
                // Set alert properties
                let alert = UIAlertController(title: error.alertTitle,
                                              message: error.alertMessage,
                                              preferredStyle: .alert)
                // Add an action to the alert
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                // Show the alert
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}


