//
//  ShowAlert.swift
//  Blocks
//
//  Created by 沈畅 on 5/25/19.
//  Copyright © 2019 Chang Shen. All rights reserved.
//

import UIKit


func showAlert(presentingViewController: UIViewController, title: String, message: String? = nil) {
    guard presentingViewController.viewIfLoaded?.window != nil else { print("Failed to showAlert because view controller is not visible"); return}
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    let alertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
    alert.addAction(alertAction)
    presentingViewController.present(alert, animated: true, completion: nil)
}
