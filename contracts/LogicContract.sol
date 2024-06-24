pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract LogicContract {
    uint256 public num;
    struct BEData {
        string be;
        string add;
    }
    uint256[] public keys;

    mapping(uint256 => BEData) public beDataMapping;

    event SETData(uint256 indexed _id, string be);

    function setNum(uint256 _num) public {
        num = _num;
    }

    function setData(uint256 _id, BEData memory _beData) public {
        beDataMapping[_id].be = _beData.be;
        beDataMapping[_id].add = _beData.add;
        keys.push(_id);
        emit SETData(_id, beDataMapping[_id].be);
    }

    function getAllBEData() public view returns (BEData[] memory) {
        BEData[] memory allData = new BEData[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            allData[i] = beDataMapping[keys[i]];
        }
        return allData;
    }
}
