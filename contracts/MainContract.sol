pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract MainContract {
    uint256 public num;
    struct BEData {
        string be;
        string add;
    }
    uint256[] public keys;

    mapping(uint256 => BEData) public beDataMapping;

    event SETData(uint256 indexed _id, string be);

    address public logicContract;

    constructor(address _logicContract) {
        logicContract = _logicContract;
    }

    function setNum(uint256 _num) public {
        (bool success, ) = logicContract.delegatecall(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
        require(success, "delegatecall failed");
    }

    function setData(uint256 _id, BEData memory _beData) public {
        (bool success, ) = logicContract.delegatecall(
            abi.encodeWithSignature(
                "setData(uint256,(string,string))",
                _id,
                _beData
            )
        );
        require(success, "delegatecall failed");
    }

    function getNum() public view returns (uint256) {
        return num;
    }

    function getAllBEData() public view returns (BEData[] memory) {
        BEData[] memory allData = new BEData[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            allData[i] = beDataMapping[keys[i]];
        }
        return allData;
    }
}
