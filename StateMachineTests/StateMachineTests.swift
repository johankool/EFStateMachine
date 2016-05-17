//
//  StateMachineTests.swift
//  StateMachineTests
//
//  Created by Johan Kool on 15/8/15.
//  Copyright © 2015 Egeniq. All rights reserved.
//

import XCTest
import StateMachine

class StateMachineTests: XCTestCase {

    enum TestLoadState {
        case Empty
        case Loading(loadingMore: Bool)
        case Loaded(hasMore: Bool, offset: Int, updated: NSDate)
    }

    private func setupLoadMachine(length length: UInt = 3) -> StateMachine<TestLoadState> {
        let machine = StateMachine(initialState: TestLoadState.Empty) { old, new in
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

        return machine
    }

    private var loadMachine: StateMachine<TestLoadState>!
    private var recordedCallBacks: [(old: TestLoadState, new: TestLoadState)] = []

    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        loadMachine = setupLoadMachine()
        recordedCallBacks = []
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        loadMachine  = nil
        recordedCallBacks.removeAll()

        super.tearDown()
    }

    func testInitialState() {
        if case TestLoadState.Empty = loadMachine.state {
            // Expected
        } else {
            XCTFail("Unexpected initial state")
        }
    }

    func testValidStateChange() {
        // Check returned state
        let state = loadMachine.changeToState(.Loading(loadingMore: false))
        XCTAssertTrue(state)

        // Check reported state
        if case let TestLoadState.Loading(loadingMore) = loadMachine.state {
            // Expected
            XCTAssertFalse(loadingMore)
        } else {
            XCTFail("Unexpected state")
        }
    }

    func testInvalidStateChange() {
        // Check returned state
        let state = loadMachine.changeToState(.Loaded(hasMore: true, offset: 20, updated: NSDate()))
        XCTAssertFalse(state)

        // Check reported state
        if case TestLoadState.Empty = loadMachine.state {
            // Expected
        } else {
            XCTFail("Unexpected state")
        }
    }

    func testOnChangeCallbacks() {

        loadMachine.onChange = { old, new in
            self.recordedCallBacks.append((old: old, new: new))
        }

        XCTAssertEqual(recordedCallBacks.count, 0)

        loadMachine.changeToState(.Loading(loadingMore: false))
        XCTAssertEqual(recordedCallBacks.count, 1)

        loadMachine.changeToState(.Loading(loadingMore: false))
        XCTAssertEqual(recordedCallBacks.count, 1)

        loadMachine.changeToState(.Loaded(hasMore: true, offset: 20, updated: NSDate()))
        XCTAssertEqual(recordedCallBacks.count, 2)

        loadMachine.changeToState(.Loaded(hasMore: true, offset: 20, updated: NSDate()))
        XCTAssertEqual(recordedCallBacks.count, 2)
    }

    var statusLabel: UILabel = UILabel()

    func testSampleCode() {

        class ItemService {
            func loadItems(offset offset:Int, handler: (([Item], Bool, Int) -> Void)) {}
        }
        let itemService = ItemService()
        class Item {}
        var items = [Item()]

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

        load()
        refresh()
        loadMore()
    }
}
