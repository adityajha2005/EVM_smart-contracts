//SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Exchange} from "./Exchange.sol";
contract Factory {
   //token => exchange
   mapping(address => address) public tokenToExchange;

   event ExchangeCreated(address indexed token, address indexed exchange);

   function createExchange(address _token) external returns (address) {
    require(_token != address(0), "Invalid token address");
    //check if the exchange already exists
    require(tokenToExchange[_token] == address(0), "Exchange already exists");
    //deploy the exchange contract
    Exchange exchange = new Exchange(_token);
    tokenToExchange[_token] = address(exchange);
    emit ExchangeCreated(_token, address(exchange));
    return address(exchange);
   }
}