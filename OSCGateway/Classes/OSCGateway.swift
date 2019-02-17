//
//  OSCGateway.swift
//  OSCGateway
//
//  Created by Akira Matsuda on 2019/02/13.
//  Copyright © 2019 Akira Matsuda. All rights reserved.
//

import Foundation
import SwiftOSC

class Gateway {
    
    static let shared = Gateway()
    
    private var client: OSCClient?
    private var server: OSCServer?
    
    
    typealias Handler = (OSCMessage) -> Void
    
    private var observers: EndpointObserver<[String : Handler]>
    
    init() {
        self.observers = EndpointObserver<[String : Handler]>()
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
        self.server!.delegate = self
        self.server!.start()
    }
    
    func send<T>(message: T) where T:Message {
        guard let client = client else {
            return
        }
        client.send(OSCMessage(OSCAddressPattern(message.address()),
                               message.arguments()))
    }
    
    func observe<T>(endpoint: T.Type, key: String, handler: @escaping Handler) where T:Endpoint {
        observers.append(handler: [key : handler], key: endpoint)
    }
    
    func remove<T>(endpoint: T.Type, forKey: String) where T:Endpoint {
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
    
    func didReceive(_ message: OSCMessage){
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

protocol Endpoint {
    
    static func address() -> String
    func address() -> String
    
}

protocol ServerEndpoint: Endpoint {
    
    associatedtype Data
    static func parse(message: OSCMessage) -> Data?
    
}

extension Endpoint {
    
    func address() -> String {
        return Self.address()
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

protocol Message {
    
    associatedtype EndpointType: Endpoint
    func arguments() -> [OSCType]
    
}

extension Message {
    
    func address() -> String {
        return EndpointType.address()
    }
    
}
