//
//  StateMessage.swift
//  OSCGateway
//
//  Created by Akira Matsuda on 2019/02/16.
//  Copyright © 2019 Akira Matsuda. All rights reserved.
//

import Foundation
import SwiftOSC
import OSCGateway

enum State: Int, CaseIterable {
    case invalid = -1
    case powerOn
    case powerOff
    
    func toString() -> String {
        switch self {
        case .invalid:
            return "Invalid"
        case .powerOn:
            return "Power On"
        case .powerOff:
            return "Power Off"
        }
    }
}

struct StateData
{
    
    let currentState: State
    
    init(_ state: Int) {
        self.currentState = State(rawValue: state) ?? .invalid
    }

}

struct StateEndpoint: ServerEndpoint {
    
    typealias Data = StateData
    
    static func address() -> String {
        return "/state"
    }
    
    static func parse(message: OSCMessage) -> StateData? {
        if message.arguments.count == 1, let state = message.arguments[0] as? Float {
            return StateData(Int(state))
        }
        
        return nil
    }
    
}
