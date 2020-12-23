//
//  OSCGateway.swift
//  OSCGateway
//
//  Created by Akira Matsuda on 2019/02/13.
//  Copyright © 2019 Akira Matsuda. All rights reserved.
//

import Foundation
import SwiftOSC

public final class Gateway {
    public static let shared = Gateway()

    var client: OSCClient?
    var server: OSCServer?
    var observers: EndpointObserver<[String: InternalHandler]>

    typealias InternalHandler = (OSCMessage) -> Void
    public typealias Handler<T> = (T) -> Void

    public var address: String {
        get {
            guard let c = client else {
                return ""
            }
            return c.address
        }
        set {
            configureClient(ipAddress: newValue, port: outgoingPort)
        }
    }

    public var incomingPort: Int {
        get {
            guard let s = server else {
                return 0
            }
            return s.port
        }

        set {
            configureServer(port: newValue)
        }
    }

    public var outgoingPort: Int {
        get {
            guard let c = client else {
                return 0
            }
            return c.port
        }

        set {
            configureClient(ipAddress: address, port: newValue)
        }
    }

    init() {
        observers = EndpointObserver<[String: InternalHandler]>()
    }

    convenience init(address: String, outgoingPort: Int) {
        self.init()
        configureClient(ipAddress: address, port: outgoingPort)
    }

    convenience init(address: String, incomingPort: Int) {
        self.init()
        configureServer(port: incomingPort)
    }

    convenience init(address: String, incomingPort: Int, outgoingPort: Int) {
        self.init()
        configureClient(ipAddress: address, port: outgoingPort)
        configureServer(port: incomingPort)
    }

    func configureClient(ipAddress: String, port: Int) {
        client = OSCClient(address: ipAddress, port: port)
    }

    func configureServer(port: Int) {
        server = OSCServer(address: "", port: port)
        server!.delegate = self
        server!.start()
    }

    public func send<T>(message: T) where T: Message {
        guard let client = client else {
            return
        }
        client.send(OSCMessage(
            OSCAddressPattern(message.address()),
            message.arguments()
        ))
    }

    public func observe<T>(endpoint: T.Type, key: String, handler: @escaping Handler<T.Data?>) where T: ServerEndpoint {
        remove(endpoint: T.self, forKey: key)
        let internalHandler: InternalHandler = { message in
            handler(T.parse(message: message))
        }
        let pair = [key: internalHandler]
        observers.append(handler: pair, key: T.self)
    }

    public func remove<T>(endpoint: T.Type, forKey: String) where T: ServerEndpoint {
        var handlers = observers[endpoint]
        handlers.removeAll { (dict) -> Bool in
            for key in dict.keys {
                if key == forKey {
                    return true
                }
            }

            return false
        }
    }
}

extension Gateway: OSCServerDelegate {
    public func didReceive(_ message: OSCMessage) {
        guard let (_, handlers) = observers.endpoint(forKey: message.address.string) else {
            return
        }

        for h in handlers {
            for (_, f) in h {
                f(message)
            }
        }
    }
}

public protocol Endpoint {
    static func address() -> String
    func address() -> String
}

public protocol ServerEndpoint: Endpoint {
    associatedtype Data
    static func parse(message: OSCMessage) -> Data?
}

public extension Endpoint {
    func address() -> String {
        return Self.address()
    }
}

public protocol Message {
    associatedtype EndpointType: Endpoint
    func arguments() -> [OSCType]
}

public extension Message {
    func address() -> String {
        return EndpointType.address()
    }
}

struct EndpointKey: Equatable, Hashable {
    let endpoint: Endpoint.Type

    var hashValue: Int {
        return endpoint.address().hashValue
    }

    static func == (lhs: EndpointKey, rhs: EndpointKey) -> Bool {
        return lhs.endpoint.address() == rhs.endpoint.address()
    }

    func string() -> String {
        return endpoint.address()
    }
}

class EndpointObserver<T> {
    private var storage = [EndpointKey: [T]]()

    func endpoint(forKey key: String) -> (Endpoint.Type, [T])? {
        for (endpointKey, value) in storage {
            if endpointKey.endpoint.address() == key {
                return (endpointKey.endpoint, value)
            }
        }
        return nil
    }

    func append(handler: T, key: Endpoint.Type) {
        var handlers = self[key]
        handlers.append(handler)
        self[key] = handlers
    }

    subscript(key: Endpoint.Type) -> [T] {
        get {
            if let handlers = storage[EndpointKey(endpoint: key)] {
                return handlers
            }
            storage[EndpointKey(endpoint: key)] = [T]()
            return storage[EndpointKey(endpoint: key)]!
        }
        set {
            storage[EndpointKey(endpoint: key)] = newValue
        }
    }
}
