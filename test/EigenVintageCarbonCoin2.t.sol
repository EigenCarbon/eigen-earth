// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/services/carbon/EigenVintageCarbonCoin.sol";

contract VintageCarbonCoinTest is Test {
    EigenVintageCarbonCoin public coin;
    address admin = address(0xA11CE);
    address foundation = address(0xF00D);
    address carbonService = address(0xC0DE);
    address user = address(0xBEEF);

    function setUp() public {
        vm.startPrank(admin);
        coin = new EigenVintageCarbonCoin(
            admin,
            foundation,
            carbonService,
            2025
        );
        vm.stopPrank();
    }

    function testInitialRoles() public {
        assertTrue(coin.hasRole(coin.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(coin.hasRole(coin.CARBON_MINTER_ROLE(), admin));
        assertTrue(coin.hasRole(coin.DEFAULT_ADMIN_ROLE(), foundation));
        assertTrue(coin.hasRole(coin.CARBON_MINTER_ROLE(), foundation));
        assertTrue(coin.hasRole(coin.DEFAULT_ADMIN_ROLE(), carbonService));
        assertTrue(coin.hasRole(coin.CARBON_MINTER_ROLE(), carbonService));
    }

    function testMintFailsWithoutRole() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                user,
                coin.CARBON_MINTER_ROLE()
            )
        );
        coin.mint(user, 1000);
        vm.stopPrank();
    }

    function testBurnFailsWithoutRole() public {
        vm.startPrank(admin);
        coin.mint(user, 1000);
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSignature(
                "AccessControlUnauthorizedAccount(address,bytes32)",
                user,
                coin.CARBON_MINTER_ROLE()
            )
        );
        coin.burn(user, 500);
        vm.stopPrank();
    }

    function testBurnFailsInsufficientBalance() public {
        vm.startPrank(admin);
        coin.mint(user, 500);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(); // OpenZeppelin ERC20 burn does not emit string error
        coin.burn(user, 1000);
        vm.stopPrank();
    }

    function testMintFailsZeroAddress() public {
        vm.startPrank(admin);
        vm.expectRevert("Zero address");
        coin.mint(address(0), 1000);
        vm.stopPrank();
    }

    function testMintFailsZeroAmount() public {
        vm.startPrank(admin);
        vm.expectRevert("Zero amount");
        coin.mint(user, 0);
        vm.stopPrank();
    }

    function testBurnFailsZeroAddress() public {
        vm.startPrank(admin);
        vm.expectRevert("Zero address");
        coin.burn(address(0), 1000);
        vm.stopPrank();
    }

    function testBurnFailsZeroAmount() public {
        vm.startPrank(admin);
        vm.expectRevert("Zero amount");
        coin.burn(user, 0);
        vm.stopPrank();
    }

    function testCoinBeginEnd() public {
        uint256 begin = coin.CoinBegin();
        uint256 end = coin.CoinEnd();

        assertLt(begin, end);
        emit log_named_uint("CoinBegin", begin);
        emit log_named_uint("CoinEnd", end);
    }

    /// Helpers
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory hexChars = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            uint8 b = uint8(data[i]);
            hexChars[2 * i] = nibbleToHexChar(b >> 4);
            hexChars[2 * i + 1] = nibbleToHexChar(b & 0x0f);
        }
        return string(hexChars);
    }

    function nibbleToHexChar(uint8 nibble) internal pure returns (bytes1) {
        return nibble < 10 ? bytes1(nibble + 0x30) : bytes1(nibble + 0x61 - 10);
    }
}
