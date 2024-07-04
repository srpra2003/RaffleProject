//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract DeployRaffle is Script {
    function deployRaffle() internal returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        Raffle raffle;

        (
            uint256 entryfee,
            uint256 automataionInterval,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            address vrf_Coordinator_add,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrf_Coordinator_add, deployerKey);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(subId, vrf_Coordinator_add, link, deployerKey);
        }

        vm.startBroadcast(deployerKey);
        raffle = new Raffle(entryfee, automataionInterval, keyHash, subId, callbackGasLimit, vrf_Coordinator_add);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(subId, address(raffle), vrf_Coordinator_add, deployerKey);

        return (raffle, helperConfig);
    }

    function run() external returns (Raffle, HelperConfig) {
        return deployRaffle();
    }
}
