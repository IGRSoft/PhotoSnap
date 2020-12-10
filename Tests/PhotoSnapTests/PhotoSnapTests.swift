import XCTest
@testable import PhotoSnap

final class PhotoSnapTests: XCTestCase {
    func testPhotoSnapToMemory() {
        /*NEEDFIX: This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.*/
//        let ps = PhotoSnap()
//
//        var model: PhotoSnapModel? = nil
//
//        ps.fetchSnapshot() { photoModel in
//            model = photoModel
//        }
//
//        waitForExpectations(timeout: 2, handler: nil)
//
//        XCTAssertNotNil(model)
    }

    static var allTests = [
        ("testPhotoSnapToMemory", testPhotoSnapToMemory),
    ]
}
