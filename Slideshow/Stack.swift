//
//  Stack.swift
//  Slideshow
//
//  Implements a stack data type.
//
//  Created by Berthy Feng on 6/27/17.
//  Copyright © 2017 Berthy Feng. All rights reserved.
//

import Foundation

public struct Stack<Element> {
    private var array: [Element] = []
    
    public mutating func push(_ element: Element) {
        array.append(element)
    }
    
    public mutating func pop() -> Element? {
        return array.popLast()
    }
    
    public func peek() -> Element? {
        return array.last
    }
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public var count: Int {
        return array.count
    }
}
