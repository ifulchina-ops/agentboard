// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AgentBoard
/// @notice A minimal on-chain message board gated by Agent ID.
/// @dev Only addresses holding at least one Agent ID (SPACE ID Agent ID,
///      ERC-721, non-transferable) may post. Anyone may read messages.
///      The contract has NO owner, NO admin functions, NO mint/tax/pause/
///      freeze/withdraw powers, and NO upgradeability. It holds no funds.
interface IAgentId {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract AgentBoard {
    /// @notice The Agent ID contract (SPACE ID Agent ID, ERC-721).
    IAgentId public immutable agentId;

    /// @notice Maximum message length in bytes (keeps gas costs bounded).
    uint256 public constant MAX_MESSAGE_LENGTH = 280;

    struct Message {
        address author;
        string content;
        uint256 timestamp;
    }

    Message[] private messages;

    /// @notice Emitted whenever an Agent ID holder posts a message.
    event MessagePosted(
        uint256 indexed index,
        address indexed author,
        string content,
        uint256 timestamp
    );

    error NotAgentIdHolder();
    error EmptyMessage();
    error MessageTooLong(uint256 length, uint256 maxLength);

    constructor(address agentIdAddress) {
        require(agentIdAddress != address(0), "AgentBoard: zero Agent ID address");
        agentId = IAgentId(agentIdAddress);
    }

    /// @notice Post a message. Caller must hold at least one Agent ID.
    /// @param content The message text (1-280 bytes).
    function postMessage(string calldata content) external {
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentIdHolder();
        uint256 len = bytes(content).length;
        if (len == 0) revert EmptyMessage();
        if (len > MAX_MESSAGE_LENGTH) revert MessageTooLong(len, MAX_MESSAGE_LENGTH);

        uint256 index = messages.length;
        messages.push(Message({author: msg.sender, content: content, timestamp: block.timestamp}));
        emit MessagePosted(index, msg.sender, content, block.timestamp);
    }

    /// @notice Total number of messages posted.
    function getMessageCount() external view returns (uint256) {
        return messages.length;
    }

    /// @notice Read a single message by index.
    function getMessage(uint256 index) external view returns (Message memory) {
        return messages[index];
    }

    /// @notice Read a page of messages, newest last.
    /// @param start Index of the first message to return.
    /// @param count Maximum number of messages to return.
    function getMessages(uint256 start, uint256 count) external view returns (Message[] memory) {
        uint256 total = messages.length;
        if (start >= total) return new Message[](0);
        uint256 end = start + count;
        if (end > total) end = total;
        Message[] memory page = new Message[](end - start);
        for (uint256 i = start; i < end; i++) {
            page[i - start] = messages[i];
        }
        return page;
    }
}
