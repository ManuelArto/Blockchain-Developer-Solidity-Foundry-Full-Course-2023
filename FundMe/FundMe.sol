// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_EUR = 5e18;

    address[] public funders;
    mapping(address => uint256) public addresToAmountFunded; 

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier is_owner() {
        // require(msg.sender == i_owner, "Only owner can access");
        if (msg.sender != i_owner) { revert NotOwner(); }
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_EUR, "Money must be greater then 5"); // 1e18 = 1 ETH
        funders.push(msg.sender);
        addresToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public is_owner {
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addresToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);

        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // What happen if someone sends this contract ETH without using fund() function?
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        fund();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        fund();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}