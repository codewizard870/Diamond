// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {
    struct Item {
        uint256 id;
        string name;
    }

    Item public item;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function setItem(uint256 _id, string calldata _name) public onlyOwner {
        item = Item(_id, _name);
    }

    function getItem() public view returns (Item memory) {
        return item;
    }
}