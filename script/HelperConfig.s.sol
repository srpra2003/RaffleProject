//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entryfee;
        uint256 automataionInterval;
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        address vrf_Coordinator_add;
        address link;
        uint256 deployerkey;
    }

    NetworkConfig public activeNetConfig;

    event HelperConfig_CreateMockAnvilVRF(address indexed vrf_coordinator);

    constructor() {
        if (block.chainid == 11155111) {
            activeNetConfig = getSepoliaEthNetConfig();
        } else if (block.chainid == 1) {
            activeNetConfig = getMainnetEthNetConfig();
        } else {
            activeNetConfig = getOrCreateAnvilNetConfig();
        }
    }

    function getSepoliaEthNetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryfee: 0.001 ether,
            automataionInterval: 2 minutes,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 0,
            callbackGasLimit: 500000,
            vrf_Coordinator_add: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerkey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getMainnetEthNetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryfee: 0.001 ether,
            automataionInterval: 2 minutes,
            keyHash: 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92,
            subId: 0,
            callbackGasLimit: 500000,
            vrf_Coordinator_add: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            deployerkey: vm.envUint("MAINNET_PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilNetConfig() internal returns (NetworkConfig memory) {
        if (activeNetConfig.vrf_Coordinator_add != address(0)) {
            return activeNetConfig;
        }

        uint96 basefee = 50000;
        uint96 gasPrice = 1e8;

        vm.startBroadcast(vm.envUint("ANVIL_PRIVATE_KEY"));
        VRFCoordinatorV2Mock vrf_coordinator_mock = new VRFCoordinatorV2Mock(basefee, gasPrice);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        emit HelperConfig_CreateMockAnvilVRF(address(vrf_coordinator_mock));

        return NetworkConfig({
            entryfee: 0.001 ether,
            automataionInterval: 2 minutes,
            keyHash: 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92,
            subId: 0,
            callbackGasLimit: 500000,
            vrf_Coordinator_add: address(vrf_coordinator_mock),
            link: address(link),
            deployerkey: vm.envUint("ANVIL_PRIVATE_KEY")
        });
    }
}
