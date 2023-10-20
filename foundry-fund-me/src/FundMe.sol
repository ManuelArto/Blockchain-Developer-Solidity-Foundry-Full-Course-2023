// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    AggregatorV3Interface private s_priceFeed;

    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable i_owner;

    address[] private s_funders;
    mapping(address => uint256) private s_addresToAmountFunded; 

    constructor(address priceFeed) { // Sepolia => 0x694AA1769357215DE4FAC081bf1f309aDC325306
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier is_owner() {
        // require(msg.sender == i_owner, "Only owner can access");
        if (msg.sender != i_owner) { revert FundMe_NotOwner(); }
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Money must be greater then 5"); // 1e18 = 1 ETH
        s_funders.push(msg.sender);
        s_addresToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public is_owner {
        for (uint i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addresToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function getVersion() public view returns (uint256) {
        return PriceConverter.getVersion(s_priceFeed);
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

    /**
     * View / Pure functions (Getter)
     */

    function getAddresToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addresToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

}