////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import XCTest
import RealmSwift

#if swift(>=3.0)

class CTTAggregateObject: Object {
    dynamic var intCol = 0
    dynamic var int8Col = 0
    dynamic var int16Col = 0
    dynamic var int32Col = 0
    dynamic var int64Col = 0
    dynamic var floatCol = 0 as Float
    dynamic var doubleCol = 0.0
    dynamic var boolCol = false
    dynamic var dateCol = Date()
    dynamic var trueCol = true
    let stringListCol = List<CTTStringObjectWithLink>()
    dynamic var linkCol: CTTLinkTarget?
}

class CTTAggregateObjectList: Object {
    let list = List<CTTAggregateObject>()
}

class CTTStringObjectWithLink: Object {
    dynamic var stringCol = ""
    dynamic var linkCol: CTTLinkTarget?
}

class CTTLinkTarget: Object {
    dynamic var id = 0
    let stringObjects = LinkingObjects(fromType: CTTStringObjectWithLink.self, property: "linkCol")
    let aggregateObjects = LinkingObjects(fromType: CTTAggregateObject.self, property: "linkCol")
}

class CTTStringList: Object {
    let array = List<CTTStringObjectWithLink>()
}

class RealmCollectionTypeTests: TestCase {
    var str1: CTTStringObjectWithLink?
    var str2: CTTStringObjectWithLink?
    var collection: AnyRealmCollection<CTTStringObjectWithLink>?

    func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        fatalError("Abstract method. Try running tests using Control-U.")
    }

    func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        fatalError("Abstract method. Try running tests using Control-U.")
    }

    func makeAggregateableObjectsInWriteTransaction() -> [CTTAggregateObject] {
        let obj1 = CTTAggregateObject()
        obj1.intCol = 1
        obj1.int8Col = 1
        obj1.int16Col = 1
        obj1.int32Col = 1
        obj1.int64Col = 1
        obj1.floatCol = 1.1
        obj1.doubleCol = 1.11
        obj1.dateCol = Date(timeIntervalSince1970: 1)
        obj1.boolCol = false

        let obj2 = CTTAggregateObject()
        obj2.intCol = 2
        obj2.int8Col = 2
        obj2.int16Col = 2
        obj2.int32Col = 2
        obj2.int64Col = 2
        obj2.floatCol = 2.2
        obj2.doubleCol = 2.22
        obj2.dateCol = Date(timeIntervalSince1970: 2)
        obj2.boolCol = false

        let obj3 = CTTAggregateObject()
        obj3.intCol = 3
        obj3.int8Col = 3
        obj3.int16Col = 3
        obj3.int32Col = 3
        obj3.int64Col = 3
        obj3.floatCol = 2.2
        obj3.doubleCol = 2.22
        obj3.dateCol = Date(timeIntervalSince1970: 2)
        obj3.boolCol = false

        realmWithTestPath().add([obj1, obj2, obj3])
        return [obj1, obj2, obj3]
    }

    func makeAggregateableObjects() -> [CTTAggregateObject] {
        var result: [CTTAggregateObject]?
        try! realmWithTestPath().write {
            result = makeAggregateableObjectsInWriteTransaction()
        }
        return result!
    }

    override func setUp() {
        super.setUp()

        let str1 = CTTStringObjectWithLink()
        str1.stringCol = "1"
        self.str1 = str1

        let str2 = CTTStringObjectWithLink()
        str2.stringCol = "2"
        self.str2 = str2

        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(str1)
            realm.add(str2)
        }

        collection = AnyRealmCollection(getCollection())
    }

    override func tearDown() {
        str1 = nil
        str2 = nil
        collection = nil

        super.tearDown()
    }

    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(RealmCollectionTypeTests.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func testRealm() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(collection.realm!.configuration.fileURL, realmWithTestPath().configuration.fileURL)
    }

    func testDescription() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "Results<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = (null);\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = (null);\n\t}\n)")
    }

    func testCount() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(2, collection.count)
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = '2'").count)
        XCTAssertEqual(0, collection.filter("stringCol = '0'").count)
    }

    func testIndexOfObject() {
        guard let collection = collection, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(0, collection.index(of: str1)!)
        XCTAssertEqual(1, collection.index(of: str2)!)

        let str1Only = collection.filter("stringCol = '1'")
        XCTAssertEqual(0, str1Only.index(of: str1)!)
        XCTAssertNil(str1Only.index(of: str2))
    }

    func testIndexOfPredicate() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(0, collection.index(matching: pred1)!)
        XCTAssertEqual(1, collection.index(matching: pred2)!)
        XCTAssertNil(collection.index(matching: pred3))
    }

    func testIndexOfFormat() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(0, collection.index(matching: "stringCol = '1'")!)
        XCTAssertEqual(0, collection.index(matching: "stringCol = %@", "1")!)
        XCTAssertEqual(1, collection.index(matching: "stringCol = %@", "2")!)
        XCTAssertNil(collection.index(matching: "stringCol = %@", "3"))
    }

    func testSubscript() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(str1, collection[0])
        XCTAssertEqual(str2, collection[1])

        assertThrows(collection[200])
        assertThrows(collection[-200])
    }

    func testFirst() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(str1, collection.first!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").first!)
        XCTAssertNil(collection.filter("stringCol = '3'").first)
    }

    func testLast() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(str2, collection.last!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").last!)
        XCTAssertNil(collection.filter("stringCol = '3'").last)
    }

    func testValueForKey() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        let expected = Array(collection.map { $0.stringCol })
        let actual = collection.value(forKey: "stringCol") as! [String]!
        XCTAssertEqual(expected, actual!)

        XCTAssertEqual(collection.map { $0 }, collection.value(forKey: "self") as! [CTTStringObjectWithLink])
    }

    func testSetValueForKey() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        try! realmWithTestPath().write {
            collection.setValue("hi there!", forKey: "stringCol")
        }
        let expected = Array((0..<collection.count).map { _ in "hi there!" })
        let actual = Array(collection.map { $0.stringCol })
        XCTAssertEqual(expected, actual)
    }

    func testFilterFormat() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "1").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "2").count)
        XCTAssertEqual(0, collection.filter("stringCol = %@", "3").count)
    }

    func testFilterList() {
        let outerArray = SwiftDoubleListOfSwiftObject()
        let realm = realmWithTestPath()
        let innerArray = SwiftListOfSwiftObject()
        innerArray.array.append(SwiftObject())
        outerArray.array.append(innerArray)
        try! realm.write {
            realm.add(outerArray)
        }
        XCTAssertEqual(1, outerArray.array.filter("ANY array IN %@", realm.objects(SwiftObject.self)).count)
    }

    func testFilterResults() {
        let array = SwiftListOfSwiftObject()
        let realm = realmWithTestPath()
        array.array.append(SwiftObject())
        try! realm.write {
            realm.add(array)
        }
        XCTAssertEqual(1, realm.objects(SwiftListOfSwiftObject.self).filter("ANY array IN %@", realm.objects(SwiftObject.self)).count)
    }

    func testFilterPredicate() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(1, collection.filter(pred1).count)
        XCTAssertEqual(1, collection.filter(pred2).count)
        XCTAssertEqual(0, collection.filter(pred3).count)
    }

    func testSortWithProperty() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        var sorted = collection.sorted(byProperty: "stringCol", ascending: true)
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = collection.sorted(byProperty: "stringCol", ascending: false)
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)

        assertThrows(collection.sorted(byProperty: "noSuchCol", ascending: true), named: "Invalid sort property")
    }

    func testSortWithDescriptor() {
        let collection = getAggregateableCollection()

        let notActuallySorted = collection.sorted(by: [])
        XCTAssertEqual(collection[0], notActuallySorted[0])
        XCTAssertEqual(collection[1], notActuallySorted[1])

        var sorted = collection.sorted(by: [SortDescriptor(property: "intCol", ascending: true)])
        XCTAssertEqual(1, sorted[0].intCol)
        XCTAssertEqual(2, sorted[1].intCol)

        sorted = collection.sorted(by: [SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)])
        XCTAssertEqual(2.22, sorted[0].doubleCol)
        XCTAssertEqual(3, sorted[0].intCol)
        XCTAssertEqual(2.22, sorted[1].doubleCol)
        XCTAssertEqual(2, sorted[1].intCol)
        XCTAssertEqual(1.11, sorted[2].doubleCol)

        assertThrows(collection.sorted(by: [SortDescriptor(property: "noSuchCol")]), named: "Invalid sort property")
    }

    func testMin() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(1, collection.min(ofProperty: "intCol") as NSNumber!)
        XCTAssertEqual(1, collection.min(ofProperty: "intCol") as Int!)
        XCTAssertEqual(1, collection.min(ofProperty: "int8Col") as NSNumber!)
        XCTAssertEqual(1, collection.min(ofProperty: "int8Col") as Int8!)
        XCTAssertEqual(1, collection.min(ofProperty: "int16Col") as NSNumber!)
        XCTAssertEqual(1, collection.min(ofProperty: "int16Col") as Int16!)
        XCTAssertEqual(1, collection.min(ofProperty: "int32Col") as NSNumber!)
        XCTAssertEqual(1, collection.min(ofProperty: "int32Col") as Int32!)
        XCTAssertEqual(1, collection.min(ofProperty: "int64Col") as NSNumber!)
        XCTAssertEqual(1, collection.min(ofProperty: "int64Col") as Int64!)
        XCTAssertEqual(1.1 as Float as NSNumber, collection.min(ofProperty: "floatCol") as NSNumber!)
        XCTAssertEqual(1.1, collection.min(ofProperty: "floatCol") as Float!)
        XCTAssertEqual(1.11, collection.min(ofProperty: "doubleCol") as NSNumber!)
        XCTAssertEqual(1.11, collection.min(ofProperty: "doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 1), collection.min(ofProperty: "dateCol") as NSDate!)
        XCTAssertEqual(Date(timeIntervalSince1970: 1), collection.min(ofProperty: "dateCol") as Date!)

        assertThrows(collection.min(ofProperty: "noSuchCol") as NSNumber!, named: "Invalid property name")
        assertThrows(collection.min(ofProperty: "noSuchCol") as Float!, named: "Invalid property name")
    }

    func testMax() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(3, collection.max(ofProperty: "intCol") as NSNumber!)
        XCTAssertEqual(3, collection.max(ofProperty: "intCol") as Int!)
        XCTAssertEqual(3, collection.max(ofProperty: "int8Col") as NSNumber!)
        XCTAssertEqual(3, collection.max(ofProperty: "int8Col") as Int8!)
        XCTAssertEqual(3, collection.max(ofProperty: "int16Col") as NSNumber!)
        XCTAssertEqual(3, collection.max(ofProperty: "int16Col") as Int16!)
        XCTAssertEqual(3, collection.max(ofProperty: "int32Col") as NSNumber!)
        XCTAssertEqual(3, collection.max(ofProperty: "int32Col") as Int32!)
        XCTAssertEqual(3, collection.max(ofProperty: "int64Col") as NSNumber!)
        XCTAssertEqual(3, collection.max(ofProperty: "int64Col") as Int64!)
        XCTAssertEqual(2.2 as Float as NSNumber, collection.max(ofProperty: "floatCol") as NSNumber!)
        XCTAssertEqual(2.2, collection.max(ofProperty: "floatCol") as Float!)
        XCTAssertEqual(2.22, collection.max(ofProperty: "doubleCol") as NSNumber!)
        XCTAssertEqual(2.22, collection.max(ofProperty: "doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 2), collection.max(ofProperty: "dateCol") as NSDate!)
        XCTAssertEqual(Date(timeIntervalSince1970: 2), collection.max(ofProperty: "dateCol") as Date!)

        assertThrows(collection.max(ofProperty: "noSuchCol") as NSNumber!, named: "Invalid property name")
        assertThrows(collection.max(ofProperty: "noSuchCol") as Float!, named: "Invalid property name")
    }

    func testSum() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(6, collection.sum(ofProperty: "intCol") as NSNumber)
        XCTAssertEqual(6, collection.sum(ofProperty: "intCol") as Int)
        XCTAssertEqual(6, collection.sum(ofProperty: "int8Col") as NSNumber)
        XCTAssertEqual(6, collection.sum(ofProperty: "int8Col") as Int8)
        XCTAssertEqual(6, collection.sum(ofProperty: "int16Col") as NSNumber)
        XCTAssertEqual(6, collection.sum(ofProperty: "int16Col") as Int16)
        XCTAssertEqual(6, collection.sum(ofProperty: "int32Col") as NSNumber)
        XCTAssertEqual(6, collection.sum(ofProperty: "int32Col") as Int32)
        XCTAssertEqual(6, collection.sum(ofProperty: "int64Col") as NSNumber)
        XCTAssertEqual(6, collection.sum(ofProperty: "int64Col") as Int64)
        XCTAssertEqualWithAccuracy(5.5, (collection.sum(ofProperty: "floatCol") as NSNumber).floatValue,
                                   accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.5, collection.sum(ofProperty: "floatCol") as Float, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.55, (collection.sum(ofProperty: "doubleCol") as NSNumber).doubleValue,
                                   accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.55, collection.sum(ofProperty: "doubleCol") as Double, accuracy: 0.001)

        assertThrows(collection.sum(ofProperty: "noSuchCol") as NSNumber, named: "Invalid property name")
        assertThrows(collection.sum(ofProperty: "noSuchCol") as Float, named: "Invalid property name")
    }

    func testAverage() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(2, collection.average(ofProperty: "intCol") as NSNumber!)
        XCTAssertEqual(2, collection.average(ofProperty: "intCol") as Int!)
        XCTAssertEqual(2, collection.average(ofProperty: "int8Col") as NSNumber!)
        XCTAssertEqual(2, collection.average(ofProperty: "int8Col") as Int8!)
        XCTAssertEqual(2, collection.average(ofProperty: "int16Col") as NSNumber!)
        XCTAssertEqual(2, collection.average(ofProperty: "int16Col") as Int16!)
        XCTAssertEqual(2, collection.average(ofProperty: "int32Col") as NSNumber!)
        XCTAssertEqual(2, collection.average(ofProperty: "int32Col") as Int32!)
        XCTAssertEqual(2, collection.average(ofProperty: "int64Col") as NSNumber!)
        XCTAssertEqual(2, collection.average(ofProperty: "int64Col") as Int64!)
        XCTAssertEqualWithAccuracy(1.8333, (collection.average(ofProperty: "floatCol") as NSNumber!).floatValue,
                                   accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.8333, collection.average(ofProperty: "floatCol") as Float!, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.85, (collection.average(ofProperty: "doubleCol") as NSNumber!).doubleValue,
                                   accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.85, collection.average(ofProperty: "doubleCol") as Double!, accuracy: 0.001)

        assertThrows(collection.average(ofProperty: "noSuchCol")! as NSNumber, named: "Invalid property name")
        assertThrows(collection.average(ofProperty: "noSuchCol")! as Float, named: "Invalid property name")
    }

    func testFastEnumeration() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }

        var str = ""
        for obj in collection {
            str += obj.stringCol
        }

        XCTAssertEqual(str, "12")
    }

    func testFastEnumerationWithMutation() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }

        let realm = realmWithTestPath()
        try! realm.write {
            for obj in collection {
                realm.delete(obj)
            }
        }
        XCTAssertEqual(0, collection.count)
    }

    func testAssignListProperty() {
        // no way to make RealmCollectionType conform to NSFastEnumeration
        // so test the concrete collections directly.
        fatalError("abstract")
    }

    func testArrayAggregateWithSwiftObjectDoesntThrow() {
        let collection = getAggregateableCollection()

        // Should not throw a type error.
        _ = collection.filter("ANY stringListCol == %@", CTTStringObjectWithLink())
    }

    func testAddNotificationBlock() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }

        var theExpectation = expectation(description: "")
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 2)
                break
            case .update:
                XCTFail("Shouldn't happen")
                break
            case .error:
                XCTFail("Shouldn't happen")
                break
            }

            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // add a second notification and wait for it
        theExpectation = expectation(description: "")
        let token2 = collection.addNotificationBlock { _ in
            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        theExpectation = expectation(description: "")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(collection)
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectations(timeout: 1, handler: nil)

        token.stop()
        token2.stop()
    }

    func testValueForKeyPath() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }

        XCTAssertEqual(["1", "2"], collection.value(forKeyPath: "@unionOfObjects.stringCol") as! NSArray?)

        let theCollection = getAggregateableCollection()
        XCTAssertEqual(3, (theCollection.value(forKeyPath: "@count") as! NSNumber?)?.int64Value)
        XCTAssertEqual(3, (theCollection.value(forKeyPath: "@max.intCol") as! NSNumber?)?.int64Value)
        XCTAssertEqual(1, (theCollection.value(forKeyPath: "@min.intCol") as! NSNumber?)?.int64Value)
        XCTAssertEqual(6, (theCollection.value(forKeyPath: "@sum.intCol") as! NSNumber?)?.int64Value)
        XCTAssertEqual(2.0, (theCollection.value(forKeyPath: "@avg.intCol") as! NSNumber?)?.doubleValue)
    }

    func testInvalidate() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }

        XCTAssertFalse(collection.isInvalidated)
        realmWithTestPath().invalidate()
        XCTAssertTrue(collection.realm == nil || collection.isInvalidated)
    }
}

// MARK: Results

class ResultsTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ResultsTests.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        fatalError("abstract")
    }

    final func collectionBase() -> Results<CTTStringObjectWithLink> {
        var result: Results<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            result = collectionBaseInWriteTransaction()
        }
        return result!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        try! realmWithTestPath().write {
            let array = CTTStringList()
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }

    func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.create(CTTStringObjectWithLink.self, value: ["a"])
        }
    }

    func testNotificationBlockUpdating() {
        let collection = collectionBase()

        var theExpectation = expectation(description: "")
        var calls = 0
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let results):
                XCTAssertEqual(results.count, calls + 2)
                XCTAssertEqual(results, collection)
                break
            case .update(let results, _, _, _):
                XCTAssertEqual(results.count, calls + 2)
                XCTAssertEqual(results, collection)
                break
            case .error:
                XCTFail("Shouldn't happen")
                break
            }
            calls += 1
            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        theExpectation = expectation(description: "")
        addObjectToResults()
        waitForExpectations(timeout: 1, handler: nil)

        token.stop()
    }

    func testNotificationBlockChangeIndices() {
        let collection = collectionBase()

        var theExpectation = expectation(description: "")
        var calls = 0
        let token = collection.addNotificationBlock { (change: RealmCollectionChange) in
            switch change {
            case .initial(let results):
                XCTAssertEqual(calls, 0)
                XCTAssertEqual(results.count, 2)
                break
            case .update(let results, let deletions, let insertions, let modifications):
                XCTAssertEqual(calls, 1)
                XCTAssertEqual(results.count, 3)
                XCTAssertEqual(deletions, [])
                XCTAssertEqual(insertions, [2])
                XCTAssertEqual(modifications, [])
                break
            case .error(let error):
                XCTFail(String(describing: error))
                break
            }

            calls += 1
            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        theExpectation = expectation(description: "")
        addObjectToResults()
        waitForExpectations(timeout: 1, handler: nil)

        token.stop()
    }
}

class ResultsWithCustomInitializerTest: TestCase {
    func testValueForKey() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(SwiftCustomInitializerObject(stringVal: "A"))
        }

        let collection = realm.objects(SwiftCustomInitializerObject.self)
        let expected = Array(collection.map { $0.stringCol })
        let actual = collection.value(forKey: "stringCol") as! [String]!
        XCTAssertEqual(expected, actual!)
        XCTAssertEqual(collection.map { $0 }, collection.value(forKey: "self") as! [CTTStringObjectWithLink])
    }
}

class ResultsFromTableTests: ResultsTests {

    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        return realmWithTestPath().objects(CTTStringObjectWithLink.self)
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        _ = makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(CTTAggregateObject.self))
    }
}

class ResultsFromTableViewTests: ResultsTests {

    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        return realmWithTestPath().objects(CTTStringObjectWithLink.self).filter("stringCol != ''")
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        _ = makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(CTTAggregateObject.self).filter("trueCol == true"))
    }
}

class ResultsFromLinkViewTests: ResultsTests {

    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        guard let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failed")
        }
        let array = realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        return array.array.filter(NSPredicate(value: true))
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = CTTAggregateObjectList()
            realmWithTestPath().add(list!)
            list!.list.append(objectsIn: makeAggregateableObjectsInWriteTransaction())
        }
        return AnyRealmCollection(list!.list.filter(NSPredicate(value: true)))
    }

    override func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            let array = realm.objects(CTTStringList.self).last!
            array.array.append(realm.create(CTTStringObjectWithLink.self, value: ["a"]))
        }
    }
}

// MARK: List

class ListRealmCollectionTypeTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ListRealmCollectionTypeTests.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        fatalError("abstract")
    }

    final func collectionBase() -> List<CTTStringObjectWithLink> {
        var collection: List<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            collection = collectionBaseInWriteTransaction()
        }
        return collection!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        try! realmWithTestPath().write {
            let array = CTTStringList()
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }

    override func testDescription() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "List<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = (null);\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = (null);\n\t}\n)")
    }

    func testAddNotificationBlockDirect() {
        let collection = collectionBase()

        var theExpectation = expectation(description: "")
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .initial(let collection):
                XCTAssertEqual(collection.count, 2)
                break
            case .update:
                XCTFail("Shouldn't happen")
                break
            case .error:
                XCTFail("Shouldn't happen")
                break
            }

            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // add a second notification and wait for it
        theExpectation = expectation(description: "")
        let token2 = collection.addNotificationBlock { _ in
            theExpectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        theExpectation = expectation(description: "")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(collection)
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectations(timeout: 1, handler: nil)

        token.stop()
        token2.stop()
    }
}

class ListStandaloneRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        guard let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failed")
        }
        return CTTStringList(value: [[str1, str2]]).array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        return AnyRealmCollection(CTTAggregateObjectList(value: [makeAggregateableObjects()]).list)
    }

    override func testRealm() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertNil(collection.realm)
    }

    override func testCount() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(2, collection.count)
    }

    override func testIndexOfObject() {
        guard let collection = collection, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(0, collection.index(of: str1)!)
        XCTAssertEqual(1, collection.index(of: str2)!)
    }

    override func testSortWithDescriptor() {
        let collection = getAggregateableCollection()
        assertThrows(collection.sorted(by: [SortDescriptor(property: "intCol", ascending: true)]))
        assertThrows(collection.sorted(by: [SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)]))
    }

    override func testFastEnumerationWithMutation() {
        // No standalone removal interface provided on RealmCollectionType
    }

    override func testFirst() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(str1, collection.first!)
    }

    override func testLast() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        XCTAssertEqual(str2, collection.last!)
    }

    // MARK: Things not implemented in standalone

    override func testSortWithProperty() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.sorted(byProperty: "stringCol", ascending: true))
        assertThrows(collection.sorted(byProperty: "noSuchCol", ascending: true))
    }

    override func testFilterFormat() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.filter("stringCol = '1'"))
        assertThrows(collection.filter("noSuchCol = '1'"))
    }

    override func testFilterPredicate() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "noSuchCol = '2'")

        assertThrows(collection.filter(pred1))
        assertThrows(collection.filter(pred2))
    }

    override func testArrayAggregateWithSwiftObjectDoesntThrow() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.filter("ANY stringListCol == %@", CTTStringObjectWithLink()))
    }

    override func testMin() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.min(ofProperty: "intCol") as NSNumber!)
        assertThrows(collection.min(ofProperty: "intCol") as Int!)
        assertThrows(collection.min(ofProperty: "int8Col") as NSNumber!)
        assertThrows(collection.min(ofProperty: "int8Col") as Int8!)
        assertThrows(collection.min(ofProperty: "int16Col") as NSNumber!)
        assertThrows(collection.min(ofProperty: "int16Col") as Int16!)
        assertThrows(collection.min(ofProperty: "int32Col") as NSNumber!)
        assertThrows(collection.min(ofProperty: "int32Col") as Int32!)
        assertThrows(collection.min(ofProperty: "int64Col") as NSNumber!)
        assertThrows(collection.min(ofProperty: "int64Col") as Int64!)
        assertThrows(collection.min(ofProperty: "floatCol") as NSNumber!)
        assertThrows(collection.min(ofProperty: "floatCol") as Float!)
        assertThrows(collection.min(ofProperty: "doubleCol") as NSNumber!)
        assertThrows(collection.min(ofProperty: "doubleCol") as Double!)
        assertThrows(collection.min(ofProperty: "dateCol") as NSDate!)
        assertThrows(collection.min(ofProperty: "dateCol") as Date!)
    }

    override func testMax() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.max(ofProperty: "intCol") as NSNumber!)
        assertThrows(collection.max(ofProperty: "intCol") as Int!)
        assertThrows(collection.max(ofProperty: "int8Col") as NSNumber!)
        assertThrows(collection.max(ofProperty: "int8Col") as Int8!)
        assertThrows(collection.max(ofProperty: "int16Col") as NSNumber!)
        assertThrows(collection.max(ofProperty: "int16Col") as Int16!)
        assertThrows(collection.max(ofProperty: "int32Col") as NSNumber!)
        assertThrows(collection.max(ofProperty: "int32Col") as Int32!)
        assertThrows(collection.max(ofProperty: "int64Col") as NSNumber!)
        assertThrows(collection.max(ofProperty: "int64Col") as Int64!)
        assertThrows(collection.max(ofProperty: "floatCol") as NSNumber!)
        assertThrows(collection.max(ofProperty: "floatCol") as Float!)
        assertThrows(collection.max(ofProperty: "doubleCol") as NSNumber!)
        assertThrows(collection.max(ofProperty: "doubleCol") as Double!)
        assertThrows(collection.max(ofProperty: "dateCol") as NSDate!)
        assertThrows(collection.max(ofProperty: "dateCol") as Date!)
    }

    override func testSum() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.sum(ofProperty: "intCol") as NSNumber)
        assertThrows(collection.sum(ofProperty: "intCol") as Int)
        assertThrows(collection.sum(ofProperty: "int8Col") as NSNumber)
        assertThrows(collection.sum(ofProperty: "int8Col") as Int8)
        assertThrows(collection.sum(ofProperty: "int16Col") as NSNumber)
        assertThrows(collection.sum(ofProperty: "int16Col") as Int16)
        assertThrows(collection.sum(ofProperty: "int32Col") as NSNumber)
        assertThrows(collection.sum(ofProperty: "int32Col") as Int32)
        assertThrows(collection.sum(ofProperty: "int64Col") as NSNumber)
        assertThrows(collection.sum(ofProperty: "int64Col") as Int64)
        assertThrows(collection.sum(ofProperty: "floatCol") as NSNumber)
        assertThrows(collection.sum(ofProperty: "floatCol") as Float)
        assertThrows(collection.sum(ofProperty: "doubleCol") as NSNumber)
        assertThrows(collection.sum(ofProperty: "doubleCol") as Double)
    }

    override func testAverage() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.average(ofProperty: "intCol") as NSNumber!)
        assertThrows(collection.average(ofProperty: "intCol") as Int!)
        assertThrows(collection.average(ofProperty: "int8Col") as NSNumber!)
        assertThrows(collection.average(ofProperty: "int8Col") as Int8!)
        assertThrows(collection.average(ofProperty: "int16Col") as NSNumber!)
        assertThrows(collection.average(ofProperty: "int16Col") as Int16!)
        assertThrows(collection.average(ofProperty: "int32Col") as NSNumber!)
        assertThrows(collection.average(ofProperty: "int32Col") as Int32!)
        assertThrows(collection.average(ofProperty: "int64Col") as NSNumber!)
        assertThrows(collection.average(ofProperty: "int64Col") as Int64!)
        assertThrows(collection.average(ofProperty: "floatCol") as NSNumber!)
        assertThrows(collection.average(ofProperty: "floatCol") as Float!)
        assertThrows(collection.average(ofProperty: "doubleCol") as NSNumber!)
        assertThrows(collection.average(ofProperty: "doubleCol") as Double!)
    }

    override func testAddNotificationBlock() {
        guard let collection = collection else {
            fatalError("Test precondition failed")
        }
        assertThrows(collection.addNotificationBlock { _ in })
    }

    override func testAddNotificationBlockDirect() {
        let collection = collectionBase()
        assertThrows(collection.addNotificationBlock { _ in })
    }
}

class ListNewlyAddedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        guard let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure - a property was unexpectedly nil")
        }
        let array = CTTStringList(value: [[str1, str2]])
        realmWithTestPath().add(array)
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = CTTAggregateObjectList(value: [makeAggregateableObjectsInWriteTransaction()])
            realmWithTestPath().add(list!)
        }
        return AnyRealmCollection(list!.list)
    }
}

class ListNewlyCreatedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        guard let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure - a property was unexpectedly nil")
        }
        let array = realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = realmWithTestPath().create(CTTAggregateObjectList.self,
                                                    value: [makeAggregateableObjectsInWriteTransaction()])
        }
        return AnyRealmCollection(list!.list)
    }
}

class ListRetrievedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        guard let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure - a property was unexpectedly nil")
        }
        _ = realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        let array = realmWithTestPath().objects(CTTStringList.self).first!
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            _ = realmWithTestPath().create(CTTAggregateObjectList.self,
                                                 value: [makeAggregateableObjectsInWriteTransaction()])
            list = realmWithTestPath().objects(CTTAggregateObjectList.self).first
        }
        return AnyRealmCollection(list!.list)
    }
}

class LinkingObjectsCollectionTypeTests: RealmCollectionTypeTests {
    func collectionBaseInWriteTransaction() -> LinkingObjects<CTTStringObjectWithLink> {
        let target = realmWithTestPath().create(CTTLinkTarget.self, value: [0])
        for object in realmWithTestPath().objects(CTTStringObjectWithLink.self) {
            object.linkCol = target
        }
        return target.stringObjects
    }

    final func collectionBase() -> LinkingObjects<CTTStringObjectWithLink> {
        var result: LinkingObjects<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            result = collectionBaseInWriteTransaction()
        }
        return result!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var target: CTTLinkTarget?
        try! realmWithTestPath().write {
            let objects = makeAggregateableObjectsInWriteTransaction()
            target = realmWithTestPath().create(CTTLinkTarget.self, value: [0])
            for object in objects {
                object.linkCol = target
            }
        }
        return AnyRealmCollection(target!.aggregateObjects)
    }

    override func testDescription() {
        guard let collection = collection else {
            fatalError("Test precondition failure - a property was unexpectedly nil")
        }
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "LinkingObjects<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = CTTLinkTarget {\n\t\t\tid = 0;\n\t\t};\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = CTTLinkTarget {\n\t\t\tid = 0;\n\t\t};\n\t}\n)")
    }

    override func testAssignListProperty() {
        let array = CTTStringList()
        try! realmWithTestPath().write {
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }
}

#else

class CTTAggregateObject: Object {
    dynamic var intCol = 0
    dynamic var int8Col = 0
    dynamic var int16Col = 0
    dynamic var int32Col = 0
    dynamic var int64Col = 0
    dynamic var floatCol = 0 as Float
    dynamic var doubleCol = 0.0
    dynamic var boolCol = false
    dynamic var dateCol = NSDate()
    dynamic var trueCol = true
    let stringListCol = List<CTTStringObjectWithLink>()
    dynamic var linkCol: CTTLinkTarget?
}

class CTTAggregateObjectList: Object {
    let list = List<CTTAggregateObject>()
}

class CTTStringObjectWithLink: Object {
    dynamic var stringCol = ""
    dynamic var linkCol: CTTLinkTarget?
}

class CTTLinkTarget: Object {
    dynamic var id = 0
    let stringObjects = LinkingObjects(fromType: CTTStringObjectWithLink.self, property: "linkCol")
    let aggregateObjects = LinkingObjects(fromType: CTTAggregateObject.self, property: "linkCol")
}

class CTTStringList: Object {
    let array = List<CTTStringObjectWithLink>()
}

class RealmCollectionTypeTests: TestCase {
    var str1: CTTStringObjectWithLink!
    var str2: CTTStringObjectWithLink!
    var collection: AnyRealmCollection<CTTStringObjectWithLink>!

    func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        fatalError("abstract")
    }

    func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        fatalError("abstract")
    }

    func makeAggregateableObjectsInWriteTransaction() -> [CTTAggregateObject] {
        let obj1 = CTTAggregateObject()
        obj1.intCol = 1
        obj1.int8Col = 1
        obj1.int16Col = 1
        obj1.int32Col = 1
        obj1.int64Col = 1
        obj1.floatCol = 1.1
        obj1.doubleCol = 1.11
        obj1.dateCol = NSDate(timeIntervalSince1970: 1)
        obj1.boolCol = false

        let obj2 = CTTAggregateObject()
        obj2.intCol = 2
        obj2.int8Col = 2
        obj2.int16Col = 2
        obj2.int32Col = 2
        obj2.int64Col = 2
        obj2.floatCol = 2.2
        obj2.doubleCol = 2.22
        obj2.dateCol = NSDate(timeIntervalSince1970: 2)
        obj2.boolCol = false

        let obj3 = CTTAggregateObject()
        obj3.intCol = 3
        obj3.int8Col = 3
        obj3.int16Col = 3
        obj3.int32Col = 3
        obj3.int64Col = 3
        obj3.floatCol = 2.2
        obj3.doubleCol = 2.22
        obj3.dateCol = NSDate(timeIntervalSince1970: 2)
        obj3.boolCol = false

        realmWithTestPath().add([obj1, obj2, obj3])
        return [obj1, obj2, obj3]
    }

    func makeAggregateableObjects() -> [CTTAggregateObject] {
        var result: [CTTAggregateObject]?
        try! realmWithTestPath().write {
            result = makeAggregateableObjectsInWriteTransaction()
        }
        return result!
    }

    override func setUp() {
        super.setUp()

        str1 = CTTStringObjectWithLink()
        str1.stringCol = "1"
        str2 = CTTStringObjectWithLink()
        str2.stringCol = "2"

        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(str1)
            realm.add(str2)
        }

        collection = AnyRealmCollection(getCollection())
    }

    override func tearDown() {
        str1 = nil
        str2 = nil
        collection = nil

        super.tearDown()
    }

    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(RealmCollectionTypeTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func testRealm() {
        XCTAssertEqual(collection.realm!.configuration.fileURL, realmWithTestPath().configuration.fileURL)
    }

    func testDescription() {
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "Results<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = (null);\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = (null);\n\t}\n)")
    }

    func testCount() {
        XCTAssertEqual(2, collection.count)
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = '2'").count)
        XCTAssertEqual(0, collection.filter("stringCol = '0'").count)
    }

    func testIndexOfObject() {
        XCTAssertEqual(0, collection.indexOf(str1)!)
        XCTAssertEqual(1, collection.indexOf(str2)!)

        let str1Only = collection.filter("stringCol = '1'")
        XCTAssertEqual(0, str1Only.indexOf(str1)!)
        XCTAssertNil(str1Only.indexOf(str2))
    }

    func testIndexOfPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(0, collection.indexOf(pred1)!)
        XCTAssertEqual(1, collection.indexOf(pred2)!)
        XCTAssertNil(collection.indexOf(pred3))
    }

    func testIndexOfFormat() {
        XCTAssertEqual(0, collection.indexOf("stringCol = '1'")!)
        XCTAssertEqual(0, collection.indexOf("stringCol = %@", "1")!)
        XCTAssertEqual(1, collection.indexOf("stringCol = %@", "2")!)
        XCTAssertNil(collection.indexOf("stringCol = %@", "3"))
    }

    func testSubscript() {
        XCTAssertEqual(str1, collection[0])
        XCTAssertEqual(str2, collection[1])

        assertThrows(self.collection[200])
        assertThrows(self.collection[-200])
    }

    func testFirst() {
        XCTAssertEqual(str1, collection.first!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").first!)
        XCTAssertNil(collection.filter("stringCol = '3'").first)
    }

    func testLast() {
        XCTAssertEqual(str2, collection.last!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").last!)
        XCTAssertNil(collection.filter("stringCol = '3'").last)
    }

    func testValueForKey() {
        let expected = collection.map { $0.stringCol }
        let actual = collection.valueForKey("stringCol") as! [String]!
        XCTAssertEqual(expected, actual)

        XCTAssertEqual(collection.map { $0 }, collection.valueForKey("self") as! [CTTStringObjectWithLink])
    }

    func testSetValueForKey() {
        try! realmWithTestPath().write {
            collection.setValue("hi there!", forKey: "stringCol")
        }
        let expected = (0..<collection.count).map { _ in "hi there!" }
        let actual = collection.map { $0.stringCol }
        XCTAssertEqual(expected, actual)
    }

    func testFilterFormat() {
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "1").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "2").count)
        XCTAssertEqual(0, collection.filter("stringCol = %@", "3").count)
    }

    func testFilterList() {
        let outerArray = SwiftDoubleListOfSwiftObject()
        let realm = realmWithTestPath()
        let innerArray = SwiftListOfSwiftObject()
        innerArray.array.append(SwiftObject())
        outerArray.array.append(innerArray)
        try! realm.write {
            realm.add(outerArray)
        }
        XCTAssertEqual(1, outerArray.array.filter("ANY array IN %@", realm.objects(SwiftObject.self)).count)
    }

    func testFilterResults() {
        let array = SwiftListOfSwiftObject()
        let realm = realmWithTestPath()
        array.array.append(SwiftObject())
        try! realm.write {
            realm.add(array)
        }
        XCTAssertEqual(1,
            realm.objects(SwiftListOfSwiftObject.self).filter("ANY array IN %@", realm.objects(SwiftObject.self)).count)
    }

    func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(1, collection.filter(pred1).count)
        XCTAssertEqual(1, collection.filter(pred2).count)
        XCTAssertEqual(0, collection.filter(pred3).count)
    }

    func testSortWithProperty() {
        var sorted = collection.sorted("stringCol", ascending: true)
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = collection.sorted("stringCol", ascending: false)
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)

        assertThrows(self.collection.sorted("noSuchCol", ascending: true), named: "Invalid sort property")
    }

    func testSortWithDescriptor() {
        let collection = getAggregateableCollection()

        let notActuallySorted = collection.sorted([])
        XCTAssertEqual(collection[0], notActuallySorted[0])
        XCTAssertEqual(collection[1], notActuallySorted[1])

        var sorted = collection.sorted([SortDescriptor(property: "intCol", ascending: true)])
        XCTAssertEqual(1, sorted[0].intCol)
        XCTAssertEqual(2, sorted[1].intCol)

        sorted = collection.sorted([SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)])
        XCTAssertEqual(2.22, sorted[0].doubleCol)
        XCTAssertEqual(3, sorted[0].intCol)
        XCTAssertEqual(2.22, sorted[1].doubleCol)
        XCTAssertEqual(2, sorted[1].intCol)
        XCTAssertEqual(1.11, sorted[2].doubleCol)

        assertThrows(collection.sorted([SortDescriptor(property: "noSuchCol")]), named: "Invalid sort property")
    }

    func testMin() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(1, collection.min("intCol") as NSNumber!)
        XCTAssertEqual(1, collection.min("intCol") as Int!)
        XCTAssertEqual(1, collection.min("int8Col") as NSNumber!)
        XCTAssertEqual(1, collection.min("int8Col") as Int8!)
        XCTAssertEqual(1, collection.min("int16Col") as NSNumber!)
        XCTAssertEqual(1, collection.min("int16Col") as Int16!)
        XCTAssertEqual(1, collection.min("int32Col") as NSNumber!)
        XCTAssertEqual(1, collection.min("int32Col") as Int32!)
        XCTAssertEqual(1, collection.min("int64Col") as NSNumber!)
        XCTAssertEqual(1, collection.min("int64Col") as Int64!)
        XCTAssertEqual(1.1 as Float, collection.min("floatCol") as NSNumber!)
        XCTAssertEqual(1.1, collection.min("floatCol") as Float!)
        XCTAssertEqual(1.11, collection.min("doubleCol") as NSNumber!)
        XCTAssertEqual(1.11, collection.min("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 1), collection.min("dateCol") as NSDate!)

        assertThrows(collection.min("noSuchCol") as Float!, named: "Invalid property name")
    }

    func testMax() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(3, collection.max("intCol") as NSNumber!)
        XCTAssertEqual(3, collection.max("intCol") as Int!)
        XCTAssertEqual(3, collection.max("int8Col") as NSNumber!)
        XCTAssertEqual(3, collection.max("int8Col") as Int8!)
        XCTAssertEqual(3, collection.max("int16Col") as NSNumber!)
        XCTAssertEqual(3, collection.max("int16Col") as Int16!)
        XCTAssertEqual(3, collection.max("int32Col") as NSNumber!)
        XCTAssertEqual(3, collection.max("int32Col") as Int32!)
        XCTAssertEqual(3, collection.max("int64Col") as NSNumber!)
        XCTAssertEqual(3, collection.max("int64Col") as Int64!)
        XCTAssertEqual(2.2 as Float, collection.max("floatCol") as NSNumber!)
        XCTAssertEqual(2.2, collection.max("floatCol") as Float!)
        XCTAssertEqual(2.22, collection.max("doubleCol") as NSNumber!)
        XCTAssertEqual(2.22, collection.max("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 2), collection.max("dateCol") as NSDate!)

        assertThrows(collection.max("noSuchCol") as NSNumber!, named: "Invalid property name")
        assertThrows(collection.max("noSuchCol") as Float!, named: "Invalid property name")
    }

    func testSum() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(6, collection.sum("intCol") as NSNumber)
        XCTAssertEqual(6, collection.sum("intCol") as Int)
        XCTAssertEqual(6, collection.sum("int8Col") as NSNumber)
        XCTAssertEqual(6, collection.sum("int8Col") as Int8)
        XCTAssertEqual(6, collection.sum("int16Col") as NSNumber)
        XCTAssertEqual(6, collection.sum("int16Col") as Int16)
        XCTAssertEqual(6, collection.sum("int32Col") as NSNumber)
        XCTAssertEqual(6, collection.sum("int32Col") as Int32)
        XCTAssertEqual(6, collection.sum("int64Col") as NSNumber)
        XCTAssertEqual(6, collection.sum("int64Col") as Int64)
        XCTAssertEqualWithAccuracy(5.5, (collection.sum("floatCol") as NSNumber).floatValue, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.5, collection.sum("floatCol") as Float, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.55, (collection.sum("doubleCol") as NSNumber).doubleValue, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(5.55, collection.sum("doubleCol") as Double, accuracy: 0.001)

        assertThrows(collection.sum("noSuchCol") as NSNumber, named: "Invalid property name")
        assertThrows(collection.sum("noSuchCol") as Float, named: "Invalid property name")
    }

    func testAverage() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(2, collection.average("intCol") as NSNumber!)
        XCTAssertEqual(2, collection.average("intCol") as Int!)
        XCTAssertEqual(2, collection.average("int8Col") as NSNumber!)
        XCTAssertEqual(2, collection.average("int8Col") as Int8!)
        XCTAssertEqual(2, collection.average("int16Col") as NSNumber!)
        XCTAssertEqual(2, collection.average("int16Col") as Int16!)
        XCTAssertEqual(2, collection.average("int32Col") as NSNumber!)
        XCTAssertEqual(2, collection.average("int32Col") as Int32!)
        XCTAssertEqual(2, collection.average("int64Col") as NSNumber!)
        XCTAssertEqual(2, collection.average("int64Col") as Int64!)
        XCTAssertEqualWithAccuracy(1.8333, (collection.average("floatCol") as NSNumber!).floatValue, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.8333, collection.average("floatCol") as Float!, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.85, (collection.average("doubleCol") as NSNumber!).doubleValue, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(1.85, collection.average("doubleCol") as Double!, accuracy: 0.001)

        assertThrows(collection.average("noSuchCol")! as Float, named: "Invalid property name")
    }

    func testFastEnumeration() {
        var str = ""
        for obj in collection {
            str += obj.stringCol
        }

        XCTAssertEqual(str, "12")
    }

    func testFastEnumerationWithMutation() {
        let realm = realmWithTestPath()
        try! realm.write {
            for obj in collection {
                realm.delete(obj)
            }
        }
        XCTAssertEqual(0, collection.count)
    }

    func testAssignListProperty() {
        // no way to make RealmCollectionType conform to NSFastEnumeration
        // so test the concrete collections directly.
        fatalError("abstract")
    }

    func testArrayAggregateWithSwiftObjectDoesntThrow() {
        let collection = getAggregateableCollection()

        // Should not throw a type error.
        collection.filter("ANY stringListCol == %@", CTTStringObjectWithLink())
    }

    func testAddNotificationBlock() {
        var expectation = expectationWithDescription("")
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .Initial(let collection):
                XCTAssertEqual(collection.count, 2)
                break
            case .Update:
                XCTFail("Shouldn't happen")
                break
            case .Error:
                XCTFail("Shouldn't happen")
                break
            }

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        // add a second notification and wait for it
        expectation = expectationWithDescription("")
        let token2 = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        expectation = expectationWithDescription("")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(collection)
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
        token2.stop()
    }

    func testValueForKeyPath() {
        XCTAssertEqual(["1", "2"], self.collection.valueForKeyPath("@unionOfObjects.stringCol") as! NSArray?)

        let collection = getAggregateableCollection()
        XCTAssertEqual(3, collection.valueForKeyPath("@count")?.longValue)
        XCTAssertEqual(3, collection.valueForKeyPath("@max.intCol")?.longValue)
        XCTAssertEqual(1, collection.valueForKeyPath("@min.intCol")?.longValue)
        XCTAssertEqual(6, collection.valueForKeyPath("@sum.intCol")?.longValue)
        XCTAssertEqual(2.0, collection.valueForKeyPath("@avg.intCol")?.doubleValue)
    }

    func testInvalidate() {
        XCTAssertFalse(collection.invalidated)
        realmWithTestPath().invalidate()
        XCTAssertTrue(collection.realm == nil || collection.invalidated)
    }
}

// MARK: Results

class ResultsTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ResultsTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        fatalError("abstract")
    }

    final func collectionBase() -> Results<CTTStringObjectWithLink> {
        var result: Results<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            result = collectionBaseInWriteTransaction()
        }
        return result!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        try! realmWithTestPath().write {
            let array = CTTStringList()
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }

    func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.create(CTTStringObjectWithLink.self, value: ["a"])
        }
    }

    func testNotificationBlockUpdating() {
        let collection = collectionBase()

        var expectation = expectationWithDescription("")
        var calls = 0
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .Initial(let results):
                XCTAssertEqual(results.count, calls + 2)
                XCTAssertEqual(results, collection)
                break
            case .Update(let results, _, _, _):
                XCTAssertEqual(results.count, calls + 2)
                XCTAssertEqual(results, collection)
                break
            case .Error:
                XCTFail("Shouldn't happen")
                break
            }
            calls += 1
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        expectation = expectationWithDescription("")
        addObjectToResults()
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
    }

    func testNotificationBlockChangeIndices() {
        let collection = collectionBase()

        var expectation = expectationWithDescription("")
        var calls = 0
        let token = collection.addNotificationBlock { (change: RealmCollectionChange) in
            switch change {
            case .Initial(let results):
                XCTAssertEqual(calls, 0)
                XCTAssertEqual(results.count, 2)
                break
            case .Update(let results, let deletions, let insertions, let modifications):
                XCTAssertEqual(calls, 1)
                XCTAssertEqual(results.count, 3)
                XCTAssertEqual(deletions, [])
                XCTAssertEqual(insertions, [2])
                XCTAssertEqual(modifications, [])
                break
            case .Error(let err):
                XCTFail(err.description)
                break
            }

            calls += 1
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        expectation = expectationWithDescription("")
        addObjectToResults()
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
    }
}

class ResultsWithCustomInitializerTest: TestCase {
    func testValueForKey() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(SwiftCustomInitializerObject(stringVal: "A"))
        }

        let collection = realm.objects(SwiftCustomInitializerObject.self)
        let expected = collection.map { $0.stringCol }
        let actual = collection.valueForKey("stringCol") as! [String]!
        XCTAssertEqual(expected, actual)

        XCTAssertEqual(collection.map { $0 }, collection.valueForKey("self") as! [CTTStringObjectWithLink])
    }
}

class ResultsFromTableTests: ResultsTests {
    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        return realmWithTestPath().objects(CTTStringObjectWithLink.self)
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(CTTAggregateObject.self))
    }
}

class ResultsFromTableViewTests: ResultsTests {
    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        return realmWithTestPath().objects(CTTStringObjectWithLink.self).filter("stringCol != ''")
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(CTTAggregateObject.self).filter("trueCol == true"))
    }
}

class ResultsFromLinkViewTests: ResultsTests {
    override func collectionBaseInWriteTransaction() -> Results<CTTStringObjectWithLink> {
        let array = realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        return array.array.filter(NSPredicate(value: true))
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = CTTAggregateObjectList()
            realmWithTestPath().add(list!)
            list!.list.appendContentsOf(makeAggregateableObjectsInWriteTransaction())
        }
        return AnyRealmCollection(list!.list.filter(NSPredicate(value: true)))
    }

    override func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            let array = realm.objects(CTTStringList.self).last!
            array.array.append(realm.create(CTTStringObjectWithLink.self, value: ["a"]))
        }
    }
}

// MARK: List

class ListRealmCollectionTypeTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ListRealmCollectionTypeTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        fatalError("abstract")
    }

    final func collectionBase() -> List<CTTStringObjectWithLink> {
        var collection: List<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            collection = collectionBaseInWriteTransaction()
        }
        return collection!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        try! realmWithTestPath().write {
            let array = CTTStringList()
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }

    override func testDescription() {
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "List<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = (null);\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = (null);\n\t}\n)")
    }

    func testAddNotificationBlockDirect() {
        let collection = collectionBase()

        var expectation = expectationWithDescription("")
        let token = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            switch changes {
            case .Initial(let collection):
                XCTAssertEqual(collection.count, 2)
                break
            case .Update:
                XCTFail("Shouldn't happen")
                break
            case .Error:
                XCTFail("Shouldn't happen")
                break
            }

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        // add a second notification and wait for it
        expectation = expectationWithDescription("")
        let token2 = collection.addNotificationBlock { (changes: RealmCollectionChange) in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        // make a write and implicitly verify that only the unskipped
        // notification is called (the first would error on .update)
        expectation = expectationWithDescription("")
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.delete(collection)
        try! realm.commitWrite(withoutNotifying: [token])
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
        token2.stop()
    }
}

class ListUnmanagedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        return CTTStringList(value: [[str1, str2]]).array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        return AnyRealmCollection(CTTAggregateObjectList(value: [makeAggregateableObjects()]).list)
    }

    override func testRealm() {
        XCTAssertNil(collection.realm)
    }

    override func testCount() {
        XCTAssertEqual(2, collection.count)
    }

    override func testIndexOfObject() {
        XCTAssertEqual(0, collection.indexOf(str1)!)
        XCTAssertEqual(1, collection.indexOf(str2)!)
    }

    override func testSortWithDescriptor() {
        let collection = getAggregateableCollection()
        assertThrows(collection.sorted([SortDescriptor(property: "intCol", ascending: true)]))
        assertThrows(collection.sorted([SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)]))
    }

    override func testFastEnumerationWithMutation() {
        // No removal interface provided for unmanaged RealmCollectionType instances
    }

    override func testFirst() {
        XCTAssertEqual(str1, collection.first!)
    }

    override func testLast() {
        XCTAssertEqual(str2, collection.last!)
    }

    // MARK: Things not implemented for unmanaged instances

    override func testSortWithProperty() {
        assertThrows(self.collection.sorted("stringCol", ascending: true))
        assertThrows(self.collection.sorted("noSuchCol", ascending: true))
    }

    override func testFilterFormat() {
        assertThrows(self.collection.filter("stringCol = '1'"))
        assertThrows(self.collection.filter("noSuchCol = '1'"))
    }

    override func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "noSuchCol = '2'")

        assertThrows(self.collection.filter(pred1))
        assertThrows(self.collection.filter(pred2))
    }

    override func testArrayAggregateWithSwiftObjectDoesntThrow() {
        assertThrows(self.collection.filter("ANY stringListCol == %@", CTTStringObjectWithLink()))
    }

    override func testMin() {
        assertThrows(self.collection.min("intCol") as NSNumber!)
        assertThrows(self.collection.min("intCol") as Int!)
        assertThrows(self.collection.min("int8Col") as NSNumber!)
        assertThrows(self.collection.min("int8Col") as Int8!)
        assertThrows(self.collection.min("int16Col") as NSNumber!)
        assertThrows(self.collection.min("int16Col") as Int16!)
        assertThrows(self.collection.min("int32Col") as NSNumber!)
        assertThrows(self.collection.min("int32Col") as Int32!)
        assertThrows(self.collection.min("int64Col") as NSNumber!)
        assertThrows(self.collection.min("int64Col") as Int64!)
        assertThrows(self.collection.min("floatCol") as NSNumber!)
        assertThrows(self.collection.min("floatCol") as Float!)
        assertThrows(self.collection.min("doubleCol") as NSNumber!)
        assertThrows(self.collection.min("doubleCol") as Double!)
        assertThrows(self.collection.min("dateCol") as NSDate!)
    }

    override func testMax() {
        assertThrows(self.collection.max("intCol") as NSNumber!)
        assertThrows(self.collection.max("intCol") as Int!)
        assertThrows(self.collection.max("int8Col") as NSNumber!)
        assertThrows(self.collection.max("int8Col") as Int8!)
        assertThrows(self.collection.max("int16Col") as NSNumber!)
        assertThrows(self.collection.max("int16Col") as Int16!)
        assertThrows(self.collection.max("int32Col") as NSNumber!)
        assertThrows(self.collection.max("int32Col") as Int32!)
        assertThrows(self.collection.max("int64Col") as NSNumber!)
        assertThrows(self.collection.max("int64Col") as Int64!)
        assertThrows(self.collection.max("floatCol") as NSNumber!)
        assertThrows(self.collection.max("floatCol") as Float!)
        assertThrows(self.collection.max("doubleCol") as NSNumber!)
        assertThrows(self.collection.max("doubleCol") as Double!)
        assertThrows(self.collection.max("dateCol") as NSDate!)
    }

    override func testSum() {
        assertThrows(self.collection.sum("intCol") as NSNumber)
        assertThrows(self.collection.sum("intCol") as Int)
        assertThrows(self.collection.sum("int8Col") as NSNumber)
        assertThrows(self.collection.sum("int8Col") as Int8)
        assertThrows(self.collection.sum("int16Col") as NSNumber)
        assertThrows(self.collection.sum("int16Col") as Int16)
        assertThrows(self.collection.sum("int32Col") as NSNumber)
        assertThrows(self.collection.sum("int32Col") as Int32)
        assertThrows(self.collection.sum("int64Col") as NSNumber)
        assertThrows(self.collection.sum("int64Col") as Int64)
        assertThrows(self.collection.sum("floatCol") as NSNumber)
        assertThrows(self.collection.sum("floatCol") as Float)
        assertThrows(self.collection.sum("doubleCol") as NSNumber)
        assertThrows(self.collection.sum("doubleCol") as Double)
    }

    override func testAverage() {
        assertThrows(self.collection.average("intCol") as NSNumber!)
        assertThrows(self.collection.average("intCol") as Int!)
        assertThrows(self.collection.average("int8Col") as NSNumber!)
        assertThrows(self.collection.average("int8Col") as Int8!)
        assertThrows(self.collection.average("int16Col") as NSNumber!)
        assertThrows(self.collection.average("int16Col") as Int16!)
        assertThrows(self.collection.average("int32Col") as NSNumber!)
        assertThrows(self.collection.average("int32Col") as Int32!)
        assertThrows(self.collection.average("int64Col") as NSNumber!)
        assertThrows(self.collection.average("int64Col") as Int64!)
        assertThrows(self.collection.average("floatCol") as NSNumber!)
        assertThrows(self.collection.average("floatCol") as Float!)
        assertThrows(self.collection.average("doubleCol") as NSNumber!)
        assertThrows(self.collection.average("doubleCol") as Double!)
    }

    override func testAddNotificationBlock() {
        assertThrows(self.collection.addNotificationBlock { (changes: RealmCollectionChange) in })
    }

    override func testAddNotificationBlockDirect() {
        let collection = collectionBase()
        assertThrows(collection.addNotificationBlock { (changes: RealmCollectionChange) in })
    }
}

class ListNewlyAddedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        let array = CTTStringList(value: [[str1, str2]])
        realmWithTestPath().add(array)
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = CTTAggregateObjectList(value: [makeAggregateableObjectsInWriteTransaction()])
            realmWithTestPath().add(list!)
        }
        return AnyRealmCollection(list!.list)
    }
}

class ListNewlyCreatedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        let array = realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            list = realmWithTestPath().create(CTTAggregateObjectList.self,
                value: [makeAggregateableObjectsInWriteTransaction()])
        }
        return AnyRealmCollection(list!.list)
    }
}

class ListRetrievedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBaseInWriteTransaction() -> List<CTTStringObjectWithLink> {
        realmWithTestPath().create(CTTStringList.self, value: [[str1, str2]])
        let array = realmWithTestPath().objects(CTTStringList.self).first!
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var list: CTTAggregateObjectList?
        try! realmWithTestPath().write {
            realmWithTestPath().create(CTTAggregateObjectList.self,
                value: [makeAggregateableObjectsInWriteTransaction()])
            list = realmWithTestPath().objects(CTTAggregateObjectList.self).first
        }
        return AnyRealmCollection(list!.list)
    }
}

class LinkingObjectsCollectionTypeTests: RealmCollectionTypeTests {
    func collectionBaseInWriteTransaction() -> LinkingObjects<CTTStringObjectWithLink> {
        let target = realmWithTestPath().create(CTTLinkTarget.self, value: [0])
        for object in realmWithTestPath().objects(CTTStringObjectWithLink.self) {
            object.linkCol = target
        }
        return target.stringObjects
    }

    final func collectionBase() -> LinkingObjects<CTTStringObjectWithLink> {
        var result: LinkingObjects<CTTStringObjectWithLink>?
        try! realmWithTestPath().write {
            result = collectionBaseInWriteTransaction()
        }
        return result!
    }

    override func getCollection() -> AnyRealmCollection<CTTStringObjectWithLink> {
        return AnyRealmCollection(collectionBase())
    }

    override func getAggregateableCollection() -> AnyRealmCollection<CTTAggregateObject> {
        var target: CTTLinkTarget?
        try! realmWithTestPath().write {
            let objects = makeAggregateableObjectsInWriteTransaction()
            target = realmWithTestPath().create(CTTLinkTarget.self, value: [0])
            for object in objects {
                object.linkCol = target
            }
        }
        return AnyRealmCollection(target!.aggregateObjects)
    }

    override func testDescription() {
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "LinkingObjects<CTTStringObjectWithLink> (\n\t[0] CTTStringObjectWithLink {\n\t\tstringCol = 1;\n\t\tlinkCol = CTTLinkTarget {\n\t\t\tid = 0;\n\t\t};\n\t},\n\t[1] CTTStringObjectWithLink {\n\t\tstringCol = 2;\n\t\tlinkCol = CTTLinkTarget {\n\t\t\tid = 0;\n\t\t};\n\t}\n)")
    }

    override func testAssignListProperty() {
        let array = CTTStringList()
        try! realmWithTestPath().write {
            realmWithTestPath().add(array)
            array["array"] = collectionBaseInWriteTransaction()
        }
    }
}

#endif
