//  Copyright Snap Inc. All rights reserved.
//  CameraKitSampleTests

import XCTest
@testable import CameraKitSample

class ApplicationInfoTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVersionInfo() {
        // Assert `CFBundleShortVersionString` is not nil
        XCTAssertNotNil(ApplicationInfo.version)
    }
    
    func testBuildInfo() {
        // Assert `CFBundleVersion` is not nil
        XCTAssertNotNil(ApplicationInfo.build)
    }
}
