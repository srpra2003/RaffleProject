//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscription(address vrf_Coordinator_add, uint256 deployerKey) public returns (uint64) {
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrf_Coordinator_add).createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function createSubscriptionViaConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,,,,, address vrf_Coordinator_add,, uint256 deployerKey) = helperConfig.activeNetConfig();

        return createSubscription(vrf_Coordinator_add, deployerKey);
    }

    function run() external returns (uint64 subId) {
        return createSubscriptionViaConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(uint64 subId, address consumer, address vrf_Coordinator_add, uint256 deployerkey) public {
        vm.startBroadcast(deployerkey);
        VRFCoordinatorV2Mock(vrf_Coordinator_add).addConsumer(subId, consumer);
        vm.stopBroadcast();
    }

    function addUserViaConfig(address consumer) public {
        HelperConfig helperConfig = new HelperConfig();
        (,,, uint64 subId,, address vrf_Coordinator_add, address link, uint256 deployerkey) =
            helperConfig.activeNetConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            createSubscription.createSubscription(vrf_Coordinator_add, deployerkey);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(subId, vrf_Coordinator_add, link, deployerkey);
        }

        addConsumer(subId, consumer, vrf_Coordinator_add, deployerkey);
    }

    function run() public {
        address consumer = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addUserViaConfig(consumer);
    }
}

contract FundSubscription is Script {
    function fundSubscription(uint64 subId, address vrf_Coordinator_add, address link, uint256 deployerkey) public {
        uint96 amount = 3 ether;

        if (block.chainid == 31337) {
            //if we are on the local testing network :: anvil
            vm.startBroadcast(deployerkey);
            VRFCoordinatorV2Mock(vrf_Coordinator_add).fundSubscription(subId, amount);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerkey);
            LinkToken(link).transferAndCall(vrf_Coordinator_add, amount, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function fundSubscriptionViaConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,,, uint64 subId,, address vrf_Coordinator_add, address link, uint256 deployerkey) =
            helperConfig.activeNetConfig();

        if (subId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subId = createSubscription.createSubscription(vrf_Coordinator_add, deployerkey);
        }

        fundSubscription(subId, vrf_Coordinator_add, link, deployerkey);
    }

    function run() public {
        fundSubscriptionViaConfig();
    }
}
