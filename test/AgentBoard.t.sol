// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AgentBoard} from "../src/AgentBoard.sol";

/// @notice Minimal mock of the Agent ID ERC-721 (only balanceOf is used).
contract MockAgentId {
    mapping(address => uint256) private _balances;

    function setBalance(address owner, uint256 amount) external {
        _balances[owner] = amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }
}

contract AgentBoardTest is Test {
    AgentBoard public board;
    MockAgentId public agentId;

    address public holder = address(0xA11CE);
    address public nonHolder = address(0xB0B);

    event MessagePosted(
        uint256 indexed index,
        address indexed author,
        string content,
        uint256 timestamp
    );

    function setUp() public {
        agentId = new MockAgentId();
        board = new AgentBoard(address(agentId));
        agentId.setBalance(holder, 1);
    }

    function test_PostAllowedWithAgentId() public {
        vm.prank(holder);
        board.postMessage("hello agents");
        assertEq(board.getMessageCount(), 1);
        AgentBoard.Message memory m = board.getMessage(0);
        assertEq(m.author, holder);
        assertEq(m.content, "hello agents");
        assertEq(m.timestamp, block.timestamp);
    }

    function test_PostRevertsWithoutAgentId() public {
        vm.prank(nonHolder);
        vm.expectRevert(AgentBoard.NotAgentIdHolder.selector);
        board.postMessage("i should not post");
        assertEq(board.getMessageCount(), 0);
    }

    function test_PostRevertsAfterAgentIdRemoved() public {
        agentId.setBalance(holder, 0);
        vm.prank(holder);
        vm.expectRevert(AgentBoard.NotAgentIdHolder.selector);
        board.postMessage("lost my id");
    }

    function test_MessagesRetrievableInOrder() public {
        vm.startPrank(holder);
        board.postMessage("first");
        board.postMessage("second");
        board.postMessage("third");
        vm.stopPrank();

        assertEq(board.getMessageCount(), 3);
        assertEq(board.getMessage(0).content, "first");
        assertEq(board.getMessage(1).content, "second");
        assertEq(board.getMessage(2).content, "third");
    }

    function test_GetMessagesPagination() public {
        vm.startPrank(holder);
        for (uint256 i = 0; i < 5; i++) {
            board.postMessage(string(abi.encodePacked("msg-", vm.toString(i))));
        }
        vm.stopPrank();

        AgentBoard.Message[] memory page = board.getMessages(1, 2);
        assertEq(page.length, 2);
        assertEq(page[0].content, "msg-1");
        assertEq(page[1].content, "msg-2");

        // Request past the end: clamped to what exists.
        AgentBoard.Message[] memory tail = board.getMessages(4, 10);
        assertEq(tail.length, 1);
        assertEq(tail[0].content, "msg-4");

        // Start beyond the end: empty page.
        AgentBoard.Message[] memory empty = board.getMessages(5, 10);
        assertEq(empty.length, 0);
        AgentBoard.Message[] memory empty2 = board.getMessages(100, 10);
        assertEq(empty2.length, 0);
    }

    function test_EmptyMessageReverts() public {
        vm.prank(holder);
        vm.expectRevert(AgentBoard.EmptyMessage.selector);
        board.postMessage("");
        assertEq(board.getMessageCount(), 0);
    }

    function test_MaxLengthMessageAllowed() public {
        string memory max = new string(280);
        bytes memory b = bytes(max);
        for (uint256 i = 0; i < 280; i++) b[i] = bytes1("a");
        vm.prank(holder);
        board.postMessage(string(b));
        assertEq(board.getMessageCount(), 1);
    }

    function test_TooLongMessageReverts() public {
        string memory over = new string(281);
        bytes memory b = bytes(over);
        for (uint256 i = 0; i < 281; i++) b[i] = bytes1("a");
        vm.prank(holder);
        vm.expectRevert(
            abi.encodeWithSelector(AgentBoard.MessageTooLong.selector, 281, 280)
        );
        board.postMessage(string(b));
        assertEq(board.getMessageCount(), 0);
    }

    function test_EventEmitted() public {
        vm.prank(holder);
        vm.expectEmit(true, true, false, true);
        emit MessagePosted(0, holder, "event test", block.timestamp);
        board.postMessage("event test");
    }

    function test_ZeroAgentIdAddressReverts() public {
        vm.expectRevert("AgentBoard: zero Agent ID address");
        new AgentBoard(address(0));
    }

    function test_MultipleHoldersPost() public {
        address holder2 = address(0xC0FFEE);
        agentId.setBalance(holder2, 2); // more than one ID still counts once
        vm.prank(holder);
        board.postMessage("from holder one");
        vm.prank(holder2);
        board.postMessage("from holder two");
        assertEq(board.getMessageCount(), 2);
        assertEq(board.getMessage(1).author, holder2);
    }
}
