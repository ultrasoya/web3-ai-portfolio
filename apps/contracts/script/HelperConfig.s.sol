// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE = 1e9;

    int256 public MOCK_WEI_PER_UNIT_LINK = 1e18;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        bytes32 gasLane;
        uint256 entranceFee;
        uint256 interval;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfig;

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfig[chainId].vrfCoordinator != address(0)) {
            return networkConfig[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                entranceFee: 0.01 ether, // 1e16
                interval: 30, // 30 seconds
                callbackGasLimit: 500000 // 500,000 gas
            });
    }

    function getConfigStruct() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfig()
        public
        returns (
            uint256 entranceFee,
            uint256 interval,
            bytes32 gasLane,
            uint32 callbackGasLimit
        )
    {
        NetworkConfig memory config = getConfigByChainId(block.chainid);
        return (
            config.entranceFee,
            config.interval,
            config.gasLane,
            config.callbackGasLimit
        );
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        localNetworkConfig = NetworkConfig({
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            entranceFee: 0.01 ether, // 1e16
            interval: 30, // 30 seconds
            callbackGasLimit: 500000
        });

        return localNetworkConfig;
    }
}
