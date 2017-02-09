//
//  KeychainTests.swift
//  SAMKeychain
//
//  Created by Sam Soffes on 3/10/16.
//  Copyright © 2010-2016 Sam Soffes. All rights reserved.
//

import XCTest
import SAMKeychain

class KeychainTests: XCTestCase {

	// MARK: - Properties

	let testService = "SSToolkitTestService"
	let testAccount = "SSToolkitTestAccount"
	let testPassword = "SSToolkitTestPassword"
	let testLabel = "SSToolkitLabel"


	// MARK: - XCTestCase

	override func tearDown() {
		SAMKeychain.deletePassword(forService: testService, account: testAccount)
		super.tearDown()
	}


	// MARK: - Tests

	func testNewItem() {
		// New item
		let newQuery = SAMKeychainQuery()
		newQuery.password = testPassword
		newQuery.service = testService
		newQuery.account = testAccount
		newQuery.label = testLabel
		try! newQuery.save()

		// Look up
		let lookupQuery = SAMKeychainQuery()
		lookupQuery.service = testService
		lookupQuery.account = testAccount
		try! lookupQuery.fetch()

		XCTAssertEqual(newQuery.password, lookupQuery.password)

		// Search for all accounts
		let allQuery = SAMKeychainQuery()
		var accounts = try! allQuery.fetchAll()
		XCTAssertTrue(self.accounts(accounts as [[String : AnyObject]], containsAccountWithName: testAccount), "Matching account was not returned")

		// Check accounts for service
		allQuery.service = testService
		accounts = try! allQuery.fetchAll()
		XCTAssertTrue(self.accounts(accounts as [[String : AnyObject]], containsAccountWithName: testAccount), "Matching account was not returned")

		// Delete
		let deleteQuery = SAMKeychainQuery()
		deleteQuery.service = testService
		deleteQuery.account = testAccount
		try! deleteQuery.deleteItem()
	}

	func testPasswordObject() {
		let newQuery = SAMKeychainQuery()
		newQuery.service = testService
		newQuery.account = testAccount

		let dictionary: [String: NSObject] = [
			"number": 42 as NSObject,
			"string": "Hello World" as NSObject
		]

		newQuery.passwordObject = dictionary as NSCoding?
		try! newQuery.save()

		let lookupQuery = SAMKeychainQuery()
		lookupQuery.service = testService
		lookupQuery.account = testAccount
		try! lookupQuery.fetch()

		let readDictionary = lookupQuery.passwordObject as! [String: NSObject]
		XCTAssertEqual(dictionary, readDictionary)
	}

	func testCreateWithMissingInformation() {
		var query = SAMKeychainQuery()
		query.service = testService
		query.account = testAccount
		XCTAssertThrowsError(try query.save())

		query = SAMKeychainQuery()
		query.account = testAccount
		query.password = testPassword
		XCTAssertThrowsError(try query.save())

		query = SAMKeychainQuery()
		query.service = testService
		query.password = testPassword
		XCTAssertThrowsError(try query.save())
	}

	func testDeleteWithMissingInformation() {
		var query = SAMKeychainQuery()
		query.account = testAccount
		XCTAssertThrowsError(try query.deleteItem())

		query = SAMKeychainQuery()
		query.service = testService
		XCTAssertThrowsError(try query.deleteItem())

		query = SAMKeychainQuery()
		query.account = testAccount
		XCTAssertThrowsError(try query.deleteItem())
	}

	func testFetchWithMissingInformation() {
		var query = SAMKeychainQuery()
		query.account = testAccount
		XCTAssertThrowsError(try query.fetch())

		query = SAMKeychainQuery()
		query.service = testService
		XCTAssertThrowsError(try query.fetch())
	}

	func testSynchronizable() {
		let createQuery = SAMKeychainQuery()
		createQuery.service = testService
		createQuery.account = testAccount
		createQuery.password = testPassword
		createQuery.synchronizationMode = .yes
		try! createQuery.save()

		let noFetchQuery = SAMKeychainQuery()
		noFetchQuery.service = testService
		noFetchQuery.account = testAccount
	    noFetchQuery.synchronizationMode = .no
		XCTAssertThrowsError(try noFetchQuery.fetch())
		XCTAssertNotEqual(createQuery.password, noFetchQuery.password)

		let anyFetchQuery = SAMKeychainQuery()
		anyFetchQuery.service = testService
		anyFetchQuery.account = testAccount
		anyFetchQuery.synchronizationMode = .any
		try! anyFetchQuery.fetch()
		XCTAssertEqual(createQuery.password, anyFetchQuery.password)
	}

	func testConvenienceMethods() {
		// Create a new item
		SAMKeychain.setPassword(testPassword, forService: testService, account: testAccount)

		// Check password
		XCTAssertEqual(testPassword, SAMKeychain.password(forService: testService, account: testAccount))

		// Check all accounts
		XCTAssertTrue(accounts(SAMKeychain.allAccounts() as! [[String : AnyObject]], containsAccountWithName: testAccount))

		// Check account
		XCTAssertTrue(accounts(SAMKeychain.accounts(forService: testService) as! [[String : AnyObject]], containsAccountWithName: testAccount))

		#if !os(OSX)
			SAMKeychain.setAccessibilityType(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
			XCTAssertEqual(String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly), String(describing: SAMKeychain.accessibilityType().takeRetainedValue()))
		#endif
	}

	func testUpdateAccessibilityType() {
		SAMKeychain.setAccessibilityType(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)

		// Create a new item
		SAMKeychain.setPassword(testPassword, forService: testService, account: testAccount)

		// Check all accounts
		XCTAssertTrue(accounts(SAMKeychain.allAccounts() as! [[String : AnyObject]], containsAccountWithName: testAccount))

		// Check account
		XCTAssertTrue(accounts(SAMKeychain.accounts(forService: testService) as! [[String : AnyObject]], containsAccountWithName: testAccount))

		SAMKeychain.setAccessibilityType(kSecAttrAccessibleAlwaysThisDeviceOnly)
		SAMKeychain.setPassword(testPassword, forService: testService, account: testAccount)

		// Check all accounts
		XCTAssertTrue(accounts(SAMKeychain.allAccounts() as! [[String : AnyObject]], containsAccountWithName: testAccount))

		// Check account
		XCTAssertTrue(accounts(SAMKeychain.accounts(forService: testService) as! [[String : AnyObject]], containsAccountWithName: testAccount))
	}
	

	// MARK: - Private

	fileprivate func accounts(_ accounts: [[String: AnyObject]], containsAccountWithName name: String) -> Bool {
		for account in accounts {
			if let acct = account["acct"] as? String, acct == name {
				return true
			}
		}

		return false
	}
}
