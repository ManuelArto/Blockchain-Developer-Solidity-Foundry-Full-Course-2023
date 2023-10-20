// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {

    function run() external returns (FundMe fundMe) {
        // Before startBroadcast => not a reat tx
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceeFeed = helperConfig.activeNetworkConfig();
        
        // After startBroadcast => reat tx
        vm.startBroadcast();
        fundMe = new FundMe(ethUsdPriceeFeed);
        vm.stopBroadcast();
    }

}