    //SPDX-License-Identifier: MIT
    pragma solidity ^0.8.29;

    import {Test} from "forge-std/Test.sol";
    import {Factory} from "../src/Factory.sol";
    import {Exchange} from "../src/Exchange.sol";
    import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
    import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

    contract MockToken is ERC20 {
        constructor() ERC20("Mock Token", "MTK") {
            _mint(msg.sender, 1_000_000 ether);
        }
    }

    contract FactoryTest is Test {
        using SafeERC20 for IERC20;
        Factory public factory;
        MockToken public token;
        address public user;
        address public exchange;

        function setUp() public {
            factory = new Factory();
            token = new MockToken();
            user = makeAddr("user");

            token.transfer(user, 1000 ether);
            vm.prank(user);
            //user creates exchange
            exchange = factory.createExchange(address(token));
            vm.prank(user);
            token.approve(exchange, type(uint256).max);    
        }
        
        function test_createExchange() public {
            MockToken newToken = new MockToken();
            address newUser = makeAddr("newUser");
            newToken.transfer(newUser, 1000 ether);
            assertEq(factory.tokenToExchange(address(newToken)), address(0));
            vm.prank(newUser);
            address newExchange = factory.createExchange(address(newToken));
            assertEq(factory.tokenToExchange(address(newToken)), newExchange);
        }
        function test_createNewExchange() public {
            MockToken newToken1 = new MockToken();
            address newUser1 = makeAddr("newUser1");
            newToken1.transfer(newUser1, 100 ether);
            assertEq(factory.tokenToExchange(address(newToken1)), address(0));
            vm.prank(newUser1);
            address newExchange = factory.createExchange(address(newToken1));
            assertEq(factory.tokenToExchange(address(newToken1)), newExchange);
        }

        function test_RevertIfTokenAddressIsZero() public {
            vm.expectRevert();
            factory.createExchange(address(0));
        }

        function test_existingExchange() public {
            vm.expectRevert();
            factory.createExchange(address(token));
        }
        function test_revertIfExchangeAlreadyExists() public {
            MockToken token = new MockToken();
            factory.createExchange(address(token));
            vm.expectRevert("Exchange already exists");
            factory.createExchange(address(token));
        }

    }
