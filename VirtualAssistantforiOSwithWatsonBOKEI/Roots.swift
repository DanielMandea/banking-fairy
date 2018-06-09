//
//  Roots.swift
//  VirtualAssistantforiOSwithWatsonBOKEI
//
//  Created by DanielMandea on 6/9/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class Routes {

    static func setRootViewController(for window: UIWindow?) {
        // User is not logged in -> show login view
        window?.rootViewController = conversationController
        window?.makeKeyAndVisible()
    }

    // MARK: - Static controllers

    static var conversationController: UIViewController {
        guard let nav = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UINavigationController, let vc = nav.topViewController as? ConversationViewController else {
            return UIViewController()
        }
        let viewModel = ConversationViewModel()
        vc.viewModel = viewModel
        return nav
    }
}
