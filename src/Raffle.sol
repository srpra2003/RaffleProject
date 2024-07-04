//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    error Raffle__Pay_Required_Entry_Fee();
    error Raffle__Raffle_Is_Not_Open();
    error Raffle__No_UpkeepNeeded();
    error Transfer_To_Winner_Failed(uint256 timeStamp, uint256 requestId);

    enum RaffleState {
        OPEN,
        CLOSED,
        CALCULATING
    }

    uint16 private constant MIN_CONFIRMATIONS = 4;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entryfee;
    uint256 private immutable i_automationInterval;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subId;
    uint32 private immutable i_callBackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrf_Coordinator;
    RaffleState private s_state;

    event PlayersLog(address indexed player);
    event WinnersLog(address indexed player);
    event RequestedWinners(uint256 indexed requestId);

    constructor(
        uint256 entryfee,
        uint256 automataionInterval,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit,
        address vrf_Coordinator_add
    ) VRFConsumerBaseV2(vrf_Coordinator_add) {
        s_state = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_entryfee = entryfee;
        i_automationInterval = automataionInterval;
        i_keyHash = keyHash;
        i_subId = subId;
        i_callBackGasLimit = callbackGasLimit;
        i_vrf_Coordinator = VRFCoordinatorV2Interface(vrf_Coordinator_add);
    }

    function EnterRaffle() external payable {
        if (msg.value < i_entryfee) {
            revert Raffle__Pay_Required_Entry_Fee();
        }
        if (s_state != RaffleState.OPEN) {
            revert Raffle__Raffle_Is_Not_Open();
        }

        s_players.push(payable(msg.sender));
        emit PlayersLog(msg.sender);
    }

    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool isTime = (block.timestamp - s_lastTimeStamp) >= i_automationInterval;
        bool isOpen = (s_state == RaffleState.OPEN);
        bool isBalanced = (address(this).balance > 0);
        bool arePlayersAvailable = (s_players.length > 0);

        upkeepNeeded = (isTime && isOpen && isBalanced && arePlayersAvailable);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /*performData*/ ) external {
        (bool upkeepNeed,) = checkUpkeep("0x0");

        if (!upkeepNeed) {
            revert Raffle__No_UpkeepNeeded();
        }

        s_state = RaffleState.CALCULATING;
        uint256 requestId =
            i_vrf_Coordinator.requestRandomWords(i_keyHash, i_subId, MIN_CONFIRMATIONS, i_callBackGasLimit, NUM_WORDS);

        emit RequestedWinners(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 winnerPlayerIndex = randomWords[0] % s_players.length;
        address winnerPlayer = s_players[winnerPlayerIndex];
        s_state = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        emit WinnersLog(winnerPlayer);

        (bool callSucces,) = payable(winnerPlayer).call{value: address(this).balance}("");

        if (!callSucces) {
            revert Transfer_To_Winner_Failed(block.timestamp, requestId);
        }
    }

    //getters view & pure

    function getRaffleState() public view returns (RaffleState) {
        return s_state;
    }

    function getPlayerAddressByIndex(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
