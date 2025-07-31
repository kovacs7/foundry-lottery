// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;

    function setUp() public {}

    function deployContract()
        public
        returns (Raffle, HelperConfig.networkConfig memory, HelperConfig)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );

        vm.stopBroadcast();
        return (raffle, config, helperConfig);
    }
}
