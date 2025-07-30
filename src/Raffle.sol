// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @author  . Kovacs7 aka Asish
 * @title   . Raffle
 * @dev     . Implements Chainlink VRFv2.5
 * @notice  . This contract implements a simple raffle system. Participants can enter the raffle by sending Ether to the contract.
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /*
    Errors
    */
    // error starts with "Raffle__" to indicate it's specific to the Raffle contract
    error Raffle__EntranceFeeNotMet();
    error Raffle__IntervalNotMet();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();

    /* 
    Enums
    */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1

    }

    /* 
    State variables
    */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // In seconds
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* 
    Events
    */
    event RaffleEntered(address indexed player, uint256 amount);
    event RaffleWinner(address indexed winner, uint256 timestamp);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        require(entranceFee > 0, "Entrance fee must be greater than zero");

        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;

        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // require(msg.value > i_entranceFee, "Must send more Ether to enter the raffle");
        // requires more gas

        if (msg.value < i_entranceFee) {
            revert Raffle__EntranceFeeNotMet();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        // In 8.26 of solidity, we can add error statements as require arguments, but still costs more gas than the above statement
        // require(msg.value >= i_entranceFee, Raffle__EntranceFeeNotMet());

        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender, msg.value);
    }

    function pickWinner() external {
        // Logic to pick a winner using Chainlink VRF
        // This function would typically be called after a certain condition is met

        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__IntervalNotMet();
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestID = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false})) // new parameter
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        (bool success,) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__TransferFailed();
        }

        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0); // Reset the players array
        s_lastTimestamp = block.timestamp; // Reset the last timestamp
        emit RaffleWinner(s_recentWinner, block.timestamp);
    }

    /*
    Getter function
    */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
