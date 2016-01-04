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

    public let busy: Signal<Bool>

    private var sequence: [AsyncBlock] = []
    private let _busy: Input<Bool> = Input(initial: false)

    public init() {
        busy = _busy
    }
    
    public func dispatch(block: AsyncBlock) {
        sequence.append(block)
        if sequence.count == 1 {
            dispatch_async(dispatch_get_main_queue()) {
                self._busy <-- true
                self.next()
            }
        }
    }
    
    private func next() {
        if sequence.isEmpty {
            self._busy <-- false
            return
        }
        sequence[0] {
            _ = self.sequence.removeFirst()
            self.next()
        }
    }
}