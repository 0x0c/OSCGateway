//
//  BrightnessMessage.swift
//  OSCGateway
//
//  Created by Akira Matsuda on 2019/02/16.
//  Copyright © 2019 Akira Matsuda. All rights reserved.
//

import Foundation
import OSCGateway
import SwiftOSC

struct BrightnessEndpoint: Endpoint {
    static func address() -> String {
        return "/v"
    }
}

struct BrightnessMessage: Message {
    typealias EndpointType = BrightnessEndpoint

    private let brightness: Float

    init(_ brightness: Float) {
        self.brightness = brightness
    }

    func arguments() -> [OSCType] {
        return [brightness]
    }
}
