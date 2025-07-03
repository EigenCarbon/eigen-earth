// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/EigenEarth.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/verifiers/EigenCarbonVerifier.sol";
import "../src/services/carbon/EigenCarbonService.sol";

contract EigenCarbonVerifierTest is Test {
    EigenCarbonVerifier public verifier;
    EigenCarbonService public carbonService;
    EigenEarth public earth;
    EigenEarthFoundation public foundationContract;

    address public admin = address(0xA);
    address public foundationBeneficiary = address(0xB);
    address public verifierBeneficiary = address(0xC);
    address public user = address(0xD);

    event CarbonVerificationRecorded(
        uint256 indexed tokenId,
        bool verified,
        string reason
    );

    function setUp() public {
        vm.startPrank(admin);

        foundationContract = new EigenEarthFoundation(
            admin,
            verifierBeneficiary, // land verifier beneficiary
            0.01 ether, // land fee
            verifierBeneficiary, // carbon verifier beneficiary
            0.01 ether, // carbon fee
            foundationBeneficiary // carbon coin commission beneficiary
        );

        verifier = foundationContract.carbonVerifier();
        carbonService = foundationContract.carbonService();
        earth = foundationContract.earth();

        vm.deal(user, 10 ether);

        vm.stopPrank();
    }

    function testCarbonServiceInVerifierMustMatchFoundation() public {
        assertEq(
            address(foundationContract.carbonVerifier().carbonService()),
            address(foundationContract.carbonService()),
            "CarbonVerifier wiring error"
        );
    }

    function testConstructorConfigIntegrity() public {
        assertEq(verifier.getFee(), 0.01 ether, "Fee mismatch");
        assertEq(
            verifier.getBeneficiary(),
            verifierBeneficiary,
            "Beneficiary mismatch"
        );
        assertEq(
            address(verifier.carbonService()),
            address(carbonService),
            "CarbonService address mismatch"
        );

        // Internal wiring checks
        assertTrue(
            verifier.hasRole(verifier.DEFAULT_ADMIN_ROLE(), admin),
            "Admin role missing"
        );
        assertTrue(
            verifier.hasRole(
                verifier.DEFAULT_ADMIN_ROLE(),
                address(foundationContract)
            ),
            "Foundation role missing"
        );
    }

    function testFoundationDeploysCorrectCarbonVerifierConstructorArgs()
        public
    {
        // Check that the constructor addresses match foundation config
        assertEq(
            address(verifier.carbonService()),
            address(carbonService),
            "CarbonService in verifier should match"
        );
        assertEq(
            verifier.getBeneficiary(),
            verifierBeneficiary,
            "Verifier beneficiary should match config"
        );
    }

    function testSetFeeAndGetFee() public {
        vm.startPrank(admin);
        verifier.setFee(2 ether);
        vm.stopPrank();
        assertEq(verifier.getFee(), 2 ether, "Fee not updated");
    }

    function testSetBeneficiaryAndGetBeneficiary() public {
        address newBeneficiary = address(0xE);
        vm.startPrank(admin);
        verifier.setBeneficiary(newBeneficiary);
        vm.stopPrank();
        assertEq(
            verifier.getBeneficiary(),
            newBeneficiary,
            "Beneficiary not updated"
        );
    }

    function testRequestVerificationExternalPaysFeeAndTriggersEvent() public {
        uint256 fee = verifier.getFee();
        vm.startPrank(user);
        vm.expectEmit(true, false, false, true);
        emit CarbonVerificationRecorded(
            1,
            false,
            "Verification requested by external user"
        );
        verifier.requestVerification{value: fee}(1);
        vm.stopPrank();
    }

    function testRequestVerificationExternalInsufficientFeeFails() public {
        uint256 fee = verifier.getFee();
        vm.startPrank(user);
        vm.expectRevert("Insufficient fee");
        verifier.requestVerification{value: fee - 1}(1);
        vm.stopPrank();
    }

    function testRequestVerificationAdminAutoVerifiesAndCallsApprove() public {
        vm.startPrank(admin);

        // Start recording logs so we can inspect what is emitted
        vm.recordLogs();

        // Call the function
        verifier.requestVerification(1);

        // Retrieve and print the logs
        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log("Number of logs emitted: %s", entries.length);

        for (uint i = 0; i < entries.length; i++) {
            console.log("Log %s", i);
            console.logBytes32(entries[i].topics[0]);
            if (entries[i].topics.length > 1) {
                console.logBytes32(entries[i].topics[1]);
            }
            console.logBytes(entries[i].data);
        }

        vm.stopPrank();

        // Optional: You can still assert the event if you want strict checking
        // But first decode the log and compare manually or:
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit CarbonVerificationRecorded(
            1,
            true,
            "Auto-verified by foundation/admin"
        );
        verifier.requestVerification(2); // Use a different ID to avoid reusing same state
        vm.stopPrank();
    }

    function testSetVerifiedEmitsEventAndCallsApprove() public {
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit CarbonVerificationRecorded(42, true, "Manual verify");
        verifier.setVerified(42, true, "Manual verify");
        vm.stopPrank();
    }

    function testSetFeeOnlyAdmin() public {
        vm.startPrank(user);
        vm.expectRevert();
        verifier.setFee(1 ether);
        vm.stopPrank();
    }

    function testSetBeneficiaryOnlyAdmin() public {
        vm.startPrank(user);
        vm.expectRevert();
        verifier.setBeneficiary(address(0xE));
        vm.stopPrank();
    }

    function testSetVerifiedOnlyAdmin() public {
        vm.startPrank(user);
        vm.expectRevert();
        verifier.setVerified(1, true, "Should fail");
        vm.stopPrank();
    }

    function testFoundationConstructorsAndRoles() public {
        // Foundation should be admin of verifier + carbonService + earth
        assertTrue(
            verifier.hasRole(
                verifier.DEFAULT_ADMIN_ROLE(),
                address(foundationContract)
            )
        );
        assertEq(
            address(foundationContract.carbonService()),
            address(carbonService)
        );
        assertEq(address(foundationContract.earth()), address(earth));
    }
}
