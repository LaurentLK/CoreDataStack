////
////  FetchedResultsControllerTests.swift
////  CoreDataStack
////
////  Created by Robert Edwards on 11/19/15.
////  Copyright © 2015 Big Nerd Ranch. All rights reserved.
////
//
//import XCTest
//
//import CoreData
//import CoreDataStack
//
//// MARK: - FetchedResultsControllerDelegate
//
//class SampleFetchedResultsControllerDelegate: FetchedResultsControllerDelegate {
//    var didChangeObjectCalls: [FetchedResultsObjectChange<Book>] = []
//    var didChangeSectionCalls: [FetchedResultsSectionChange<Book>] = []
//    var willChangeContentCount = 0
//    var didChangeContentCount = 0
//    var didPerformFetchCount = 0
//
//    func fetchedResultsController(_ controller: FetchedResultsController<Book>,
//        didChangeObject change: FetchedResultsObjectChange<Book>) {
//            didChangeObjectCalls.append(change)
//    }
//
//    func fetchedResultsController(_ controller: FetchedResultsController<Book>,
//        didChangeSection change: FetchedResultsSectionChange<Book>) {
//            didChangeSectionCalls.append(change)
//    }
//
//    func fetchedResultsControllerWillChangeContent(_ controller: FetchedResultsController<Book>) {
//        willChangeContentCount += 1
//    }
//
//    func fetchedResultsControllerDidChangeContent(_ controller: FetchedResultsController<Book>) {
//        didChangeContentCount += 1
//    }
//
//    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedResultsController<Book>) {
//        didPerformFetchCount += 1
//    }
//}
//
//// MARK: - Test Cases
//
//class FetchedResultsControllerTests: TempDirectoryTestCase {
//
//    var coreDataStack: CoreDataStack!
//    var fetchedResultsController: FetchedResultsController<Book>!
//    var delegate = SampleFetchedResultsControllerDelegate()
//    static let cacheName = "Cache"
//
//    override func setUp() {
//        super.setUp()
//
//        weak var setupEx = expectation(withDescription: "Setup")
//
//        // Setup Stack
//        CoreDataStack.constructSQLiteStack(withModelName: "Sample", inBundle: unitTestBundle, withStoreURL: tempStoreURL) { result in
//            switch result {
//            case .success(let stack):
//                self.coreDataStack = stack
//            case .failure(let error):
//                self.failingOn(error)
//            }
//            setupEx?.fulfill()
//        }
//        waitForExpectations(withTimeout: 10, handler: nil)
//
//        let moc = coreDataStack.mainQueueContext
//
//        // Insert some Books
//        let bookTitles = StubbedBookData.books
//        for title in bookTitles {
//            let book = Book(managedObjectContext: moc)
//            book.title = title
//        }
//        try! moc.saveContextAndWait()
//
//        // Setup fetched results controller
//        let fr = NSFetchRequest(entityName: Book.entityName)
//        fr.sortDescriptors = [SortDescriptor(key: "title", ascending: true)]
//        fetchedResultsController = FetchedResultsController<Book>(fetchRequest: fr, managedObjectContext: moc, sectionNameKeyPath: "firstInitial", cacheName: FetchedResultsControllerTests.cacheName)
//        fetchedResultsController.setDelegate(self.delegate)
//
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {
//            failingOn(error)
//        }
//    }
//
//    func testInitialFetch() {
//        guard let books = fetchedResultsController.fetchedObjects else {
//            XCTFail("Books missing from fetch")
//            return
//        }
//        XCTAssertEqual(books.count, 100)
//
//        guard let sections = fetchedResultsController.sections else {
//            XCTFail("Sections missing")
//            return
//        }
//        XCTAssertEqual(sections.count, 19)
//
//        let topSection = sections[0]
//        XCTAssertEqual(topSection.objects.count, 1)
//
//        guard let topBook = topSection.objects.first else {
//            XCTFail("Top book missing from first section")
//            return
//        }
//        XCTAssertEqual(topBook.title, "1984")
//
//        let aSection = sections[1]
//        XCTAssertEqual(aSection.name, "A")
//        XCTAssertEqual(aSection.indexTitle, "A")
//    }
//
//    func testObjectInserts() {
//        let moc = coreDataStack.mainQueueContext
//
//        // Insert some Books
//        let newBook = Book(managedObjectContext: moc)
//        newBook.title = "1111"
//        moc.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
//
//        guard let change = delegate.didChangeObjectCalls.first else {
//            XCTFail("Missing object change")
//            return
//        }
//        switch change {
//        case let .Insert(book, indexPath):
//            XCTAssertEqual(book, newBook)
//            XCTAssertEqual(indexPath, IndexPath(forRow: 0, inSection: 0))
//            break
//        case .Move, .Delete, .Update:
//            XCTFail("Incorrect update type")
//        }
//    }
//
//    func testObjectDeletions() {
//        guard let firstBook = fetchedResultsController.fetchedObjects?.first else {
//            XCTFail("first fetched book missing")
//            return
//        }
//
//        // Delete a book
//        let moc = coreDataStack.mainQueueContext
//        moc.deleteObject(firstBook)
//        moc.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
//        guard let change = delegate.didChangeObjectCalls.first else {
//            XCTFail("Missing object change object")
//            return
//        }
//
//        switch change {
//        case .Delete(let book, let indexPath):
//            XCTAssertEqual(book, firstBook)
//            XCTAssertEqual(indexPath, IndexPath(forRow: 0, inSection: 0))
//        case .Update, .Move, .Insert:
//            XCTFail("Unexpected change type")
//        }
//    }
//
//    func testObjectMoves() {
//        guard let lastBook = fetchedResultsController.fetchedObjects?.last else {
//            XCTFail("Last book missing")
//            return
//        }
//
//        XCTAssertEqual(lastBook.title, "Wide Sargasso Sea")
//
//        // Remame the book
//        lastBook.title = "Narrow Sargasso Sea"
//        coreDataStack.mainQueueContext.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//
//        // iOS 8 will report an .Update and .Move where as iOS 9 reports only the .Move
//        XCTAssertLessThanOrEqual(delegate.didChangeObjectCalls.count, 2)
//
//        guard let change = delegate.didChangeObjectCalls.first else {
//            XCTFail("Missing change object")
//            return
//        }
//
//        let expectedToPath = IndexPath(row: 1, section: 11)
//        let expectedFromPath = IndexPath(row: 3, section: 18)
//
//        switch change {
//        case let .Move(object: book, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath):
//            XCTAssertEqual(book, lastBook)
//            XCTAssertEqual(fromIndexPath, expectedFromPath)
//            XCTAssertEqual(toIndexPath, expectedToPath)
//        case let .Update(object: book, indexPath: indexPath): // iOS 8 Reports and Update and Move
//            XCTAssertEqual(book, lastBook)
//            XCTAssertEqual(indexPath, expectedFromPath)
//        case .Insert, .Delete:
//            XCTFail("Incorrect change type: \(change)")
//        }
//    }
//
//    func testObjectUpdates() {
//        guard let firstBook = fetchedResultsController.fetchedObjects?.first else {
//            XCTFail("first fetched book missing")
//            return
//        }
//        let moc = coreDataStack.mainQueueContext
//
//        // Update a book
//        XCTAssertEqual(firstBook.authors.count, 0)
//        let author = Author(managedObjectContext: moc)
//        author.firstName = "George"
//        author.lastName = "Orwell"
//        firstBook.authors.insert(author)
//        moc.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
//        guard let change = delegate.didChangeObjectCalls.first else {
//            XCTFail("Update missing")
//            return
//        }
//
//        switch change {
//        case let .Update(book, indexPath):
//            XCTAssertEqual(book, firstBook)
//            XCTAssertEqual(book.authors.count, 1)
//            XCTAssertEqual(book.authors.first, author)
//            XCTAssertEqual(indexPath, IndexPath(forRow: 0, inSection: 0))
//        case .Delete, .Move, .Insert:
//            XCTFail("Wrong type of update")
//        }
//    }
//
//    func testSectionInserts() {
//        let moc = coreDataStack.mainQueueContext
//
//        //Create a new book with a title that will create a new section
//        let newBook = Book(managedObjectContext: moc)
//        newBook.title = "##@%@#%^"
//        moc.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
//        XCTAssertEqual(delegate.didChangeSectionCalls.count, 1)
//        guard let sectionChange = delegate.didChangeSectionCalls.first else {
//            XCTFail("Missing section change assertion")
//            return
//        }
//
//        switch sectionChange {
//        case let .Insert(sectionInfo, sectionIndex):
//            XCTAssertEqual(sectionInfo.indexTitle, "#")
//            XCTAssertEqual(sectionInfo.objects.first, newBook)
//            XCTAssertEqual(sectionInfo.objects.count, 1)
//            XCTAssertEqual(sectionInfo.name, "#")
//            XCTAssertEqual(sectionIndex, 0)
//        case .Delete:
//            XCTFail("Wrong section update type")
//        }
//    }
//
//    func testSectionDeletions() {
//        let moc = coreDataStack.mainQueueContext
//
//        // Delete a book that will remove an entire section
//        guard let firstBook = fetchedResultsController.first else {
//            XCTFail("Missing first book")
//            return
//        }
//        XCTAssertEqual(firstBook.title, "1984")
//        moc.deleteObject(firstBook)
//        moc.processPendingChanges()
//
//        XCTAssertEqual(delegate.didChangeContentCount, 1)
//        XCTAssertEqual(delegate.willChangeContentCount, 1)
//        XCTAssertEqual(delegate.didChangeObjectCalls.count, 1)
//        XCTAssertEqual(delegate.didChangeSectionCalls.count, 1)
//        guard let sectionChange = delegate.didChangeSectionCalls.first else {
//            XCTFail("Missing the section delete change")
//            return
//        }
//        switch sectionChange {
//        case let .Delete(sectionInfo, sectionIndex):
//            XCTAssertEqual(sectionInfo.objects.count, 0)
//            XCTAssertEqual(sectionInfo.name, "1")
//            XCTAssertEqual(sectionInfo.indexTitle, "1")
//            XCTAssertEqual(sectionIndex, 0)
//        case .Insert:
//            XCTFail("Incorrect section update type")
//        }
//    }
//
//    func testCacheName() {
//        XCTAssertEqual(fetchedResultsController.cacheName, FetchedResultsControllerTests.cacheName)
//    }
//}
