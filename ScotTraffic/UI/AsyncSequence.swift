//
//  AsyncSequence.swift
//  ScotTraffic
//
//  Created by Neil Gall on 06/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

public class AsyncSequence {
    
    public typealias AsyncCompletionBlock = Void -> Void
    public typealias AsyncBlock = AsyncCompletionBlock -> Void

    private var sequence: [AsyncBlock] = []
    
    public func dispatch(block: AsyncBlock) {
        sequence.append(block)
        if sequence.count == 1 {
            next()
        }
    }
    
    private func next() {
        if sequence.isEmpty {
            return
        }
        sequence[0] {
            _ = self.sequence.removeFirst()
            self.next()
        }
    }
}