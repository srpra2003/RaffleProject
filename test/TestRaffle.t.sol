//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract TestRaffle is Test {
    event PlayersLog(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;
    address public Player = makeAddr("player1");
    uint256 private constant START_BALANCE = 100 ether;

    uint256 private entryfee;
    uint256 private automataionInterval;
    bytes32 private keyHash;
    uint64 private subId;
    uint32 private callbackGasLimit;
    address private vrf_Coordinator_add;
    address private link;
    uint256 private deployerKey;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (entryfee, automataionInterval, keyHash, subId, callbackGasLimit, vrf_Coordinator_add, link, deployerKey) =
            helperConfig.activeNetConfig();

        vm.deal(Player, START_BALANCE);
    }

    function testEnterRaffleFailsOnLowEntryFeePaying() public {
        vm.prank(Player);
        vm.expectRevert(Raffle.Raffle__Pay_Required_Entry_Fee.selector);

        raffle.EnterRaffle{value: 0}();
    }

    function testRafflenOnlyEntersIfItIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testEnteringRaffleChangePlayersDataStructure() public {
        vm.prank(Player);
        raffle.EnterRaffle{value: 0.01 ether}();

        assert(Player == raffle.getPlayerAddressByIndex(0));
    }

    function testEnteringRaffleEmitsPlayersLogEvent() public {
        vm.prank(Player);

        vm.expectEmit(true, true, false, false, address(raffle));
        emit PlayersLog(Player);
        raffle.EnterRaffle{value: 0.01 ether}();
    }

    function testEnteringRaffleRevertWhenRaffleStateIsNotOpen() public {
        vm.prank(Player);

        raffle.EnterRaffle{value: 1 ether}();
        vm.warp(block.timestamp + automataionInterval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("0x0");

        vm.expectRevert();
        vm.prank(makeAddr("NewPlayer"));
        raffle.EnterRaffle{value: 1 ether}();
    }

    modifier OnlyOnAnvil() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
}
