import XCTest
@testable import CigTrack

final class OnboardingValidationTests: XCTestCase {
    func testCigarettesValidationDetectsInvalidFields() {
        var config = CigarettesConfig()
        config.cigarettesPerDay = 0
        config.cigarettesPerPack = 5
        config.packPrice = 0

        XCTAssertFalse(config.isValid)
        XCTAssertEqual(config.validationMessages.count, 3)
    }

    func testDisposableVapeValidation() {
        var config = DisposableVapeConfig()
        config.puffsPerDevice = 100
        config.devicePrice = -1

        XCTAssertFalse(config.isValid)
        XCTAssertEqual(config.validationMessages.count, 2)

        config.puffsPerDevice = 800
        config.devicePrice = 12

        XCTAssertTrue(config.isValid)
    }
}
