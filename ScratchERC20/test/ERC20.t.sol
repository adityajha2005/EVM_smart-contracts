// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.29;

// import "../src/ERC20.sol";
// import "../lib/forge-std/src/Test.sol";

// contract ERC20Test is Test {
//     ERC20 token;
//     address user1 = makeAddr("user1");
//     address user2 = makeAddr("user2");

//     function setUp() public {
//         token = new ERC20("MyToken", "MTK", 18); // Assuming your constructor uses name, symbol, decimals
//     }

//     function testMintAndBalance() public {
//         token.mint(address(this), 1000 ether);
//         assertEq(token.totalSupply(), 1000 ether);
//         assertEq(token.balanceOf(address(this)), 1000 ether);
//     }

//     function testTransfer() public {
//         token.mint(address(this), 1000 ether);
//         token.transfer(user1, 500 ether);
//         assertEq(token.balanceOf(user1), 500 ether);
//     }

//     function testApproveAndTransferFrom() public {
//         token.mint(address(this), 1000 ether);
//         token.approve(user1, 300 ether);

//         vm.prank(user1);
//         token.transferFrom(address(this), user2, 300 ether);

//         assertEq(token.balanceOf(user2), 300 ether);
//         assertEq(token.allowance(address(this), user1), 0);
//     }

//     function testBurn() public {
//         token.mint(address(this), 1000 ether);
//         token.burn(400 ether);
//         assertEq(token.totalSupply(), 600 ether);
//     }
// }
