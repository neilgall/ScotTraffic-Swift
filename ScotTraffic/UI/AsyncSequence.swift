//
//  AsyncSequence.swift
//  ScotTraffic
//
//  Created by Neil Gall on 06/11/2015.
//  Copyright © 2015 Neil Gall. All rights reserved.
//

import Foundation

class AsyncSequence {
    
    typealias AsyncCompletionBlock = Void -> Void
    typealias AsyncBlock = AsyncCompletionBlock -> Void

    let busy: Signal<Bool>

    private var sequence: [AsyncBlock] = []
    private let _busy: Input<Bool> = Input(initial: false)

    init() {
        busy = _busy
    }
    
    func dispatch(block: AsyncBlock) {
        sequence.append(block)
        if sequence.count == 1 {
            onMainQueue {
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