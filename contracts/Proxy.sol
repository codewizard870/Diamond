// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    address public logicAddress;

    constructor(address _logicAddress) {
        logicAddress = _logicAddress;
    }

    fallback() external payable {
        (bool success, ) = logicAddress.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }
}