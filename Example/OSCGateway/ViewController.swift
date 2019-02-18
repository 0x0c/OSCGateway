//
//  ViewController.swift
//  OSCGateway
//
//  Created by Akira Matsuda on 02/17/2019.
//  Copyright (c) 2019 Akira Matsuda. All rights reserved.
//

import UIKit
import OSCGateway

class ViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Gateway.shared.address = "localhost"
        Gateway.shared.incomingPort = 8080
        Gateway.shared.outgoingPort = 7070
        
        Gateway.shared.observe(endpoint: StateEndpoint.self, key: "ViewController") { [weak self] (data) in
            guard let weakSelf = self, let data = data else {
                return
            }
            weakSelf.statusLabel.text = data.currentState.toString()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        Gateway.shared.send(message: BrightnessMessage(sender.value))
    }
    
}

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            switch textField.placeholder {
            case "Address":
                    Gateway.shared.address = text
            case "Incoming Port":
                if let port = Int(text) {
                    Gateway.shared.incomingPort = port
                }
            case "Outgoint Port":
                if let port = Int(text) {
                    Gateway.shared.incomingPort = port
                }
            case .none:
                print("unknown text")
            default:
                print("unknown text")
            }
        }
        textField.resignFirstResponder()
        return true
    }
}
