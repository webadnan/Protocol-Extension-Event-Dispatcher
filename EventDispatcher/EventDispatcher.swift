//
//  EventDispatcher.swift
//  EventDispatcher
//
//  Created by Simon Gladman on 27/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
//  Example usage....
//
//    To Fire or dispatch:
//    fire("tap", target: self)
//
//    To register:
//    let unregister = childOfDispatcher.on("tap") {_ in 
//        print("event dispatched")
//    }
//
//    To unregister:
//    unregister()

import Foundation
import UIKit

protocol TYEventDispatcher: class {
    func on(type: String, handler: TYEventDispatcher -> Void) -> () -> Void
    func fire(type: String, target: TYEventDispatcher)
    func getEventLists() -> TYEventListeners
}

extension TYEventDispatcher {
    func getEventLists() -> TYEventListeners {
        if let el = objc_getAssociatedObject(self, &TYEventDispatcherKey.eventDispatcher) as? TYEventListeners {
            return el
        } else {
            let eventListeners = TYEventListeners()
            objc_setAssociatedObject(self,
                &TYEventDispatcherKey.eventDispatcher,
                eventListeners,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return eventListeners
        }
    }
    
    func on(type: String, handler: TYEventDispatcher -> Void) -> () -> Void {
        let eventLists = getEventLists()
        
        let tyEventHandler = TYEventHandler(callback: handler)
        
        if let _ = eventLists.listeners[type] {
            eventLists.listeners[type]?.insert(tyEventHandler)
        } else {
            eventLists.listeners[type] = Set<TYEventHandler>([tyEventHandler])
        }
        
        let unregister = { () -> Void in
            eventLists.listeners[type]?.remove(tyEventHandler)
        }
        
        return unregister
    }
    
    func fire(type: String, target: TYEventDispatcher) {
        let el = getEventLists()
        if let handlers = el.listeners[type] {
            for handler in handlers {
                handler.callback(target)
            }
        }
    }
}

struct TYEventHandler: Hashable {
    let callback: TYEventDispatcher -> Void
    let id = NSUUID()
    
    var hashValue: Int {
        return id.hashValue
    }
}

func == (lhs: TYEventHandler, rhs: TYEventHandler) -> Bool{
    return lhs.id == rhs.id
}

class TYEventListeners {
    var listeners: [String: Set<TYEventHandler>] = [:]
}

struct TYEventDispatcherKey {
    static var eventDispatcher = "eventDispatcher"
}
