//
//  OSCTypes.swift
//  SwiftOSC
//
//  Created by Devin Roth on 6/26/16.
//  Copyright © 2016 Devin Roth Music. All rights reserved.
//

import Foundation

public struct Impulse {
    public init() {}
}

extension Impulse: OSCType {
    public var tag: String {
        return "I"
    }

    public var data: Data {
        return Data()
    }
}

public let impulse = Impulse()
