// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleTest is Test {

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_ENTRANCE_FEE = 0.001 ether;

    DeployRaffle public deployRaffle;
    HelperConfig public helperConfig;
    Raffle public raffle;
    HelperConfig public helperConfigInstance;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() public {
        deployRaffle = new DeployRaffle();
        (raffle,, helperConfigInstance) = deployRaffle.deployContract();
        HelperConfig.networkConfig memory config = helperConfigInstance.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, PLAYER_ENTRANCE_FEE); // Give player enough ether
    }

    function testInitializedRaffleState() public view {
        assertEq(uint256(raffle.getRaffleState()), uint256(Raffle.RaffleState.OPEN));
    }

    function testEnoughEntranceFee() public {
        // Arrange
        vm.startPrank(PLAYER);
        // Act
        vm.expectRevert(Raffle.Raffle__EntranceFeeNotMet.selector);
        raffle.enterRaffle();
        vm.stopPrank();
        // Assert
    }
}
