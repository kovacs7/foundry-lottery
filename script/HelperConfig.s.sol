// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract Constants {
    uint256 internal constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant LOCAL_ANVIL_CHAIN_ID = 31337;

    /* VRF mock values */
    uint96 internal constant BASE_FEE = 0.1 ether; // Base fee for VRF mock
    uint96 internal constant GAS_PRICE = 0.1 ether; // Gas price for VRF mock
    int256 internal constant WEI_PER_UNIT_LINK = 1e18; //
}

contract HelperConfig is Constants, Script {
    error HelperConfig__UnsupportedNetwork();

    struct networkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    networkConfig public activeNetworkConfig;
    mapping(uint256 => networkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthNetworkConfig();
    }

    function getNetworkByChainId(uint256 chainId) public returns (networkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthNetworkConfig();
        } else if (chainId == LOCAL_ANVIL_CHAIN_ID) {
            activeNetworkConfig = getAnvilNetworkConfig();
        } else {
            revert HelperConfig__UnsupportedNetwork();
        }
        return activeNetworkConfig;
    }

    function getConfig() external returns (networkConfig memory) {
        return getNetworkByChainId(block.chainid);
    }

    function getSepoliaEthNetworkConfig() internal pure returns (networkConfig memory) {
        return networkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000
        });
    }

    function getAnvilNetworkConfig() internal returns (networkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        } // dont overwrite the active config if it is already set

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        vm.stopBroadcast();

        return networkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            // doesnt matter for local testing
            subscriptionId: 0, // might need to be updated later
            callbackGasLimit: 500000
        });
    }
}
