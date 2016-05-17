//
//  StateMachine.swift
//  Egeniq
//
//  Created by Johan Kool on 13/8/15.
//  Copyright (c) 2015 Egeniq. All rights reserved.
//

import Foundation

/** __A Simple State Machine__

FIXME: OUTDATED This state machine is typically setup with an enum for its possible states, and an enum for its actions. The state
of the machine determines wether an action is allowed to run. The state of a machine can only be changed via an
action. The action handler returns the new state of the machine.

It is also possible to register multiple handlers that get run when certain state changes occur.

Sample code:

```
enum State {
    case Empty
    case Loading(loadingMore: Bool)
    case Loaded(hasMore: Bool, offset: Int, updated: NSDate)
}

let machine = StateMachine(initialState: State.Empty) { old, new in
    switch (old, new) {
    // Load
    case (.Empty, .Loading(let loadingMore)):
        return !loadingMore
    // Finish loading
    case (.Loading, .Loaded):
        return true
    // Refresh/Load More
    case (.Loaded(let hasMore, _, _), .Loading(let loadingMore)):
        return !loadingMore || (hasMore && loadingMore)
    default:
        return false
    }
}

func load() {
    if machine.changeToState(.Loading(loadingMore: false)) {
        // Load items
        itemService.loadItems(offset: 0) { result, hasMore, offset in
            items = result
            machine.changeToState(.Loaded(hasMore: hasMore, offset: offset, updated: NSDate()))
        }
    }
}

func refresh() {
    if machine.changeToState(.Loading(loadingMore: false)) {
        // Reset
        items.removeAll()

        // Load items
        itemService.loadItems(offset: 0) { result, hasMore, offset in
            items = result
            machine.changeToState(.Loaded(hasMore: hasMore, offset: offset, updated: NSDate()))
        }
    }
}

func loadMore() {
    guard case let State.Loaded(_, offset, _) = machine.state else { return }

    if machine.changeToState(.Loading(loadingMore: true)) {
        // Load more items
        itemService.loadItems(offset: offset) { result, hasMore, offset in
            items.appendContentsOf(result)
            machine.changeToState(.Loaded(hasMore: hasMore, offset: offset, updated: NSDate()))
        }
    }
}

machine.onChange = { old, new in
    switch new {
    case .Empty:
        self.statusLabel.text = "Hello!"
    case .Loading:
        self.statusLabel.text = "Loading"
    case .Loaded(_, _, let updated):
        self.statusLabel.text = "Last updated \(updated)"
    }
}
```
*/
public class StateMachine<S> {

    /** Create a new state machine

    - parameter initialState: The initial state of the machine
    - parameter canChange: Handler that is used to determine wether the state change is allowed
    - returns: A state machine
    */
    public init(initialState: S, canChange: ((old: S, new: S) -> Bool)) {
        self.state = initialState
        self.canChange = canChange
    }

    /// Handler that is used to determine wether the state change is allowed
    public var canChange: ((old: S, new: S) -> Bool)

    /// Handler that is run when a state change occurs
    public var onChange: ((old: S, new: S) -> ())? = nil

    /// The current state of the machine
    public private(set) var state: S {
        didSet {
            onChange?(old: oldValue, new: state)
        }
    }

    /** Check wether a state change is allowed

    - parameter toState: The proposed new state of the machine
    - returns: Boolean indicating wether the state change is allowed
    */
    public func canChangeToState(toState: S) -> Bool {
        return canChange(old: state, new: toState)
    }

    /** Make a state change if allowed

    - parameter toState: The proposed new state of the machine
    - returns: Boolean indicating wether the state change is made
    */
    public func changeToState(toState: S) -> Bool {
        if canChangeToState(toState) {
            state = toState
            return true
        } else {
            return false
        }
    }
}
