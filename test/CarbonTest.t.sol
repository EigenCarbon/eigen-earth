// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/EigenEarth.sol";
import "../src/EigenEarthFoundation.sol";
import "../src/services/carbon/EigenCarbonService.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CarbonTest is Test {
    EigenEarth public earth;
    EigenCarbonService public carbon;
    ERC1967Proxy public earthProxy;
    ERC1967Proxy public carbonProxy;
    address public owner = address(this);

   function setUp() public {
    // Set up addresses for test context
    address deployer = address(this);
    address landVerifierBeneficiary = address(0x1);
    uint256 landFee = 0.01 ether;
    address carbonVerifierBeneficiary = address(0x2);
    uint256 carbonFee = 0.02 ether;
    address carbonCoinCommissionBeneficiary = address(0x3);

    // Deploy the foundation
    EigenEarthFoundation foundation = new EigenEarthFoundation(
        deployer,
        landVerifierBeneficiary,
        landFee,
        carbonVerifierBeneficiary,
        carbonFee,
        carbonCoinCommissionBeneficiary
    );

    // Access deployed contracts
    earth = foundation.earth();
    carbon = foundation.carbonService();

    // Mint vintage coins for testing
    carbon.createVintageCoin(2025);
    carbon.createVintageCoin(2026);
    carbon.createVintageCoin(2027);
    carbon.createVintageCoin(2028);
    carbon.createVintageCoin(2029);
    carbon.createVintageCoin(2030);
}

}
