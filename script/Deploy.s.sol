// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentBoard} from "../src/AgentBoard.sol";

/// @notice Deploys AgentBoard to BNB Chain mainnet (chainId 56).
/// @dev Agent ID contract (SPACE ID Agent ID, ERC-721, non-transferable):
///      0x60b9262456de011f7d15a54cdd8c48baaa8b022f
///
///      Usage (DO NOT RUN until gas is funded):
///        export PRIVATE_KEY=<deployer private key, fresh agent wallet only>
///        export BSCSCAN_API_KEY=<BscScan API key>
///        forge script script/Deploy.s.sol:Deploy \
///          --rpc-url https://bsc-dataseed.binance.org \
///          --broadcast --verify --etherscan-api-key $BSCSCAN_API_KEY
contract Deploy is Script {
    address public constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (AgentBoard) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        AgentBoard board = new AgentBoard(AGENT_ID);
        vm.stopBroadcast();
        console.log("AgentBoard deployed at:", address(board));
        console.log("Agent ID contract:", AGENT_ID);
        return board;
    }
}
