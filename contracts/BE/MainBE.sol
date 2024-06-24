// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract MainTempBE {
    using Strings for string;
    using Counters for Counters.Counter;

    address[] private beAddresses;

    mapping(address => BEData) private bes;
    mapping(address => BEData) private pendingBes;
    address public logicBeAddress;

    /******* ENUMS ********/

    enum BEStatus {
        Live,
        Split,
        Deregistered,
        Purged
    }

    enum AdminRights {
        ANY_ONE,
        FIRST_AND_ANY_ONE,
        FIRST_AND_SECOND,
        FIRST_AND_THIRD,
        SECOND_AND_ANY_ONE,
        SECOND_AND_THIRD,
        THIRD_AND_ANY_ONE,
        MAJORITY,
        ALL
    }

    /******* STRUCTS ********/

    struct Administrator {
        address adminAddress;
        bool verified;
    }

    struct ReserveAdmin {
        address reserveAdminAddress;
        bool verified;
    }

    // struct Approval {
    //     bool isApproved;
    //     uint256 timestamp;
    // }

    struct Owner {
        address ownerAddress;
        uint256 ownerShares;
        string[] ownerAccess;
        bool verified;
    }

    struct NotificationParty {
        address notificationPartyAddress;
        string[] notificationPartyAccess;
        bool verified;
    }

    struct Agent {
        uint256 agentId;
        string agentName;
        string agentAddress;
        string agentTelephone;
        string agentEmail;
        string[] agentAccess;
    }

    struct Document {
        uint256 submittedAt;
        string title;
        string url;
    }

    struct BEData {
        string beName;
        address creator;
        string status;
        string privacyStatus;
        bool documentsFiled;
        bool hasAgent;
        Agent agent;
        Administrator[] administrators;
        ReserveAdmin[] reserveAdministrators;
        uint256 reservePeriod;
        string adminRights;
        bool hasOwners;
        Owner[] owners;
        bool hasNotificationParties;
        NotificationParty[] notificationParties;
        Document[] documents;
        bool hasExpiryDate;
        uint256 expiryDate;
        uint256 createdAt;
        uint256 updatedAt;
        bool archived;
        uint256 archivedAt;
        bool isPending;
    }

    struct BEInfo {
        address beAddress;
        string role;
    }
    /******* EVENTS ********/

    event BERegistered(
        address indexed beAddress,
        string beName,
        address indexed creator
    );
    event BEUpdated(
        address indexed beAddress,
        string beName,
        address indexed updator
    );
    event BEStatusChanged(
        address indexed beAddress,
        address indexed adminAddress,
        string newStatus
    );

    event BEArchived(address indexed beAddress, address indexed archiver);
    event BEDeleted(address indexed beAddress, address indexed deleter);


    /******* MODIFIERS ********/

    bool internal locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");

        locked = true;
        _;
        locked = false;
    }

    // Only an administrator of the BE can call the function
    modifier onlyAdministrator(address beAddress) {
        require(
            isAdmin(beAddress, msg.sender),
            "Only administrators can call this function."
        );
        _;
    }

    // Checks to make sure the expiration date of the BE has not been exceeded
    modifier expirationCheck(address beAddress) {
        require(hasExpired(beAddress) == false, "This BE has expired");
        _;
    }

    constructor(address _logicBeAddress) {
        logicBeAddress = _logicBeAddress;
    }

    function registerBE(BEData memory _beData) public {
        // console.log(_beData.agent.agentName);
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature(
                "registerBE(uint256,(string,address,string,string,bool,bool,(uint256,string,string,string,string,string[]),(address,bool)[],(address,bool)[],uint256,string,bool,(address,uint256,string[],bool)[],bool,(address,string[],bool)[],(uint256,string,string)[],bool,uint256,uint256,uint256,bool,uint256,bool))",
                0,
                _beData
            )
        );
        require(success, "delegatecall failed");
    }

    // Update a BE
    function updateBE(address beAddress, BEData memory _beData) public {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature(
                "updateBE(address,(string,address,string,string,bool,bool,(uint256,string,string,string,string,string[]),(address,bool)[],(address,bool)[],uint256,string,bool,(address,uint256,string[],bool)[],bool,(address,string[],bool)[],(uint256,string,string)[],bool,uint256,uint256,uint256,bool,uint256,bool))",
                beAddress,
                _beData
            )
        );
        require(success, "delegatecall failed");
    }

    // Change BE Status
    function changeBEStatus(address beAddress, string memory newStatus) public {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature(
                "changeBEStatus(address,string)",
                beAddress,
                newStatus
            )
        );
        require(success, "delegatecall failed");
    }

    // Archive the BE
    function archiveBE(address beAddress) public {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature("archiveBE(address)", beAddress)
        );
        require(success, "delegatecall failed");
    }

    // Delete a BE by BE address ⛔️ This is a hard delete! (data will be erased)
    function deleteBE(address beAddress) public {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature("deleteBE(address)", beAddress)
        );
        require(success, "delegatecall failed");
    }

    // /******* APPROVALS FUNCTIONS *******/
    function handleExpiredApprovals() external {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature("handleExpiredApprovals()")
        );
        require(success, "delegatecall failed");
    }

    function testHandleExpiredApprovals() external {
        (bool success, ) = logicBeAddress.delegatecall(
            abi.encodeWithSignature("testHandleExpiredApprovals()")
        );
        require(success, "delegatecall failed");
    }

    // Get Admin BE Info
    function getAdminBEInformation(address beAddress)
        public
        view
        returns (BEData memory beData)
    {
        require(bytes(bes[beAddress].beName).length != 0, "BE does not exist.");
        if (bes[beAddress].isPending == false) return (bes[beAddress]);
        else return pendingBes[beAddress];
    }

    // // Get all administrators of a BE
    function getAdministrators(
        address beAddress
    ) public view expirationCheck(beAddress) returns (Administrator[] memory) {
        BEData storage be = bes[beAddress];
        uint256 totalAdministrators = be.administrators.length;
        Administrator[] memory administrators = new Administrator[](
            totalAdministrators
        );
        for (uint256 i = 0; i < totalAdministrators; i++) {
            administrators[i] = be.administrators[i];
        }
        return administrators;
    }

    function getAllBes() public view returns (BEData[] memory) {
        BEData[] memory allBes = new BEData[](beAddresses.length);
        for (uint256 i = 0; i < beAddresses.length; i++) {
            allBes[i] = bes[beAddresses[i]];
        }
        return allBes;
    }

    
    // Get all owners of a BE
    function getOwners(
        address beAddress
    ) public view expirationCheck(beAddress) returns (Owner[] memory) {
        BEData storage be = bes[beAddress];
        uint256 totalOwners = be.owners.length;
        Owner[] memory owners = new Owner[](totalOwners);
        for (uint256 i = 0; i < totalOwners; i++) {
            owners[i] = be.owners[i];
        }
        return owners;
    }

    // Get all notification parties of a BE
    function getNotificationParties(
        address beAddress
    )
        public
        view
        expirationCheck(beAddress)
        returns (NotificationParty[] memory)
    {
        BEData storage be = bes[beAddress];
        uint256 totalParties = be.notificationParties.length;
        NotificationParty[] memory parties = new NotificationParty[](
            totalParties
        );
        for (uint256 i = 0; i < totalParties; i++) {
            parties[i] = be.notificationParties[i];
        }
        return parties;
    }

    // Get all BEs that the user address is creator, admin, owner, or notification party
    function getBEsByUser(
        address user
    )
        public
        view
        returns (BEInfo[] memory notExpired, BEInfo[] memory expired)
    {
        BEInfo[] memory notExpiredBEs;
        BEInfo[] memory expiredBEs;

        address[] memory notExpiredCreators;
        address[] memory expiredCreators;
        (notExpiredCreators, expiredCreators) = getBEsByCreator(user);
        notExpiredBEs = assignRole(notExpiredCreators, "Creator");
        expiredBEs = assignRole(expiredCreators, "Creator");

        address[] memory notExpiredAdmins;
        address[] memory expiredAdmins;
        (notExpiredAdmins, expiredAdmins) = getBEsByAdminAddress(user);
        notExpiredBEs = mergeRoles(
            notExpiredBEs,
            assignRole(notExpiredAdmins, "Admin")
        );
        expiredBEs = mergeRoles(expiredBEs, assignRole(expiredAdmins, "Admin"));

        address[] memory notExpiredOwners;
        address[] memory expiredOwners;
        (notExpiredOwners, expiredOwners) = getBEsByOwner(user);
        notExpiredBEs = mergeRoles(
            notExpiredBEs,
            assignRole(notExpiredOwners, "Owner")
        );
        expiredBEs = mergeRoles(expiredBEs, assignRole(expiredOwners, "Owner"));

        address[] memory notExpiredNotificationParties;
        address[] memory expiredNotificationParties;
        (
            notExpiredNotificationParties,
            expiredNotificationParties
        ) = getBEsByNotificationParty(user);
        notExpiredBEs = mergeRoles(
            notExpiredBEs,
            assignRole(notExpiredNotificationParties, "Notification Party")
        );
        expiredBEs = mergeRoles(
            expiredBEs,
            assignRole(expiredNotificationParties, "Notification Party")
        );

        return (notExpiredBEs, expiredBEs);
    }

    // Get all BEs where the user address is the creator
    function getBEsByCreator(
        address creatorAddress
    )
        public
        view
        returns (address[] memory notExpired, address[] memory expired)
    {
        uint256 notExpiredCount = 0;
        uint256 expiredCount = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            address beAddress = beAddresses[i];
            if (bes[beAddress].creator == creatorAddress) {
                if (hasExpired(beAddress)) {
                    expiredCount++;
                } else {
                    notExpiredCount++;
                }
            }
        }

        address[] memory notExpiredResult = new address[](notExpiredCount);
        address[] memory expiredResult = new address[](expiredCount);
        uint256 notExpiredIndex = 0;
        uint256 expiredIndex = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            address beAddress = beAddresses[i];
            if (bes[beAddress].creator == creatorAddress) {
                if (hasExpired(beAddress)) {
                    expiredResult[expiredIndex] = beAddress;
                    expiredIndex++;
                } else {
                    notExpiredResult[notExpiredIndex] = beAddress;
                    notExpiredIndex++;
                }
            }
        }

        return (notExpiredResult, expiredResult);
    }

    // Get all BEs where the user address is an admin
    function getBEsByAdminAddress(
        address adminAddress
    )
        public
        view
        returns (address[] memory notExpired, address[] memory expired)
    {
        uint256 notExpiredCount = 0;
        uint256 expiredCount = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            for (uint256 j = 0; j < be.administrators.length; j++) {
                if (be.administrators[j].adminAddress == adminAddress) {
                    if (hasExpired(beAddresses[i])) {
                        expiredCount++;
                    } else {
                        notExpiredCount++;
                    }
                    break;
                }
            }
        }

        address[] memory notExpiredResult = new address[](notExpiredCount);
        address[] memory expiredResult = new address[](expiredCount);
        uint256 notExpiredIndex = 0;
        uint256 expiredIndex = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            for (uint256 j = 0; j < be.administrators.length; j++) {
                if (be.administrators[j].adminAddress == adminAddress) {
                    if (hasExpired(beAddresses[i])) {
                        expiredResult[expiredIndex] = beAddresses[i];
                        expiredIndex++;
                    } else {
                        notExpiredResult[notExpiredIndex] = beAddresses[i];
                        notExpiredIndex++;
                    }
                    break;
                }
            }
        }

        return (notExpiredResult, expiredResult);
    }

    // Get BEs where the address is an owner
    function getBEsByOwner(
        address ownerAddress
    )
        public
        view
        returns (address[] memory notExpired, address[] memory expired)
    {
        uint256 notExpiredCount = 0;
        uint256 expiredCount = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            if (be.hasOwners) {
                for (uint256 j = 0; j < be.owners.length; j++) {
                    if (be.owners[j].ownerAddress == ownerAddress) {
                        if (hasExpired(beAddresses[i])) {
                            expiredCount++;
                        } else {
                            notExpiredCount++;
                        }
                        break;
                    }
                }
            }
        }

        address[] memory notExpiredResult = new address[](notExpiredCount);
        address[] memory expiredResult = new address[](expiredCount);
        uint256 notExpiredIndex = 0;
        uint256 expiredIndex = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            if (be.hasOwners) {
                for (uint256 j = 0; j < be.owners.length; j++) {
                    if (be.owners[j].ownerAddress == ownerAddress) {
                        if (hasExpired(beAddresses[i])) {
                            expiredResult[expiredIndex] = beAddresses[i];
                            expiredIndex++;
                        } else {
                            notExpiredResult[notExpiredIndex] = beAddresses[i];
                            notExpiredIndex++;
                        }
                        break;
                    }
                }
            }
        }

        return (notExpiredResult, expiredResult);
    }

    // Get BEs where the address is a notification party
    function getBEsByNotificationParty(
        address notificationPartyAddress
    )
        public
        view
        returns (address[] memory notExpired, address[] memory expired)
    {
        uint256 notExpiredCount = 0;
        uint256 expiredCount = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            for (uint256 j = 0; j < be.notificationParties.length; j++) {
                if (
                    be.notificationParties[j].notificationPartyAddress ==
                    notificationPartyAddress
                ) {
                    if (hasExpired(beAddresses[i])) {
                        expiredCount++;
                    } else {
                        notExpiredCount++;
                    }
                    break;
                }
            }
        }

        address[] memory notExpiredResult = new address[](notExpiredCount);
        address[] memory expiredResult = new address[](expiredCount);
        uint256 notExpiredIndex = 0;
        uint256 expiredIndex = 0;

        for (uint256 i = 0; i < beAddresses.length; i++) {
            BEData storage be = bes[beAddresses[i]];
            for (uint256 j = 0; j < be.notificationParties.length; j++) {
                if (
                    be.notificationParties[j].notificationPartyAddress ==
                    notificationPartyAddress
                ) {
                    if (hasExpired(beAddresses[i])) {
                        expiredResult[expiredIndex] = beAddresses[i];
                        expiredIndex++;
                    } else {
                        notExpiredResult[notExpiredIndex] = beAddresses[i];
                        notExpiredIndex++;
                    }
                    break;
                }
            }
        }

        return (notExpiredResult, expiredResult);
    }

    // Check if the BE has expired
    function hasExpired(address beAddress) public view returns (bool) {
        uint256 expiryDate = bes[beAddress].expiryDate;
        if (expiryDate == 0) {
            return false;
        }
        uint256 currentTimestamp = block.timestamp;
        return currentTimestamp >= expiryDate;
    }

    /******* INTERNAL FUNCTIONS ********/

    // Function to check if msg.sender is an admin
    function isAdmin(
        address beAddress,
        address account
    ) internal view returns (bool) {
        BEData storage be = bes[beAddress];
        for (uint256 i = 0; i < be.administrators.length; i++) {
            if (be.administrators[i].adminAddress == account) {
                return true;
            }
        }
        return false;
    }

    // Calculate the total shares from the owners' shares
    function calculateTotalShares(
        Owner[] storage owners
    ) internal view returns (uint256) {
        uint256 totalShares = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            totalShares += owners[i].ownerShares;
        }
        return totalShares;
    }

    // Recalculate percentages for all owners based on new total shares
    function recalculatePercentages(
        Owner[] storage owners,
        uint256 newTotalShares
    ) internal {
        for (uint256 i = 0; i < owners.length; i++) {
            owners[i].ownerShares =
                (owners[i].ownerShares * 100) /
                newTotalShares;
        }
    }

    // Assign role to each BE (creator, admin, owner, notification party)
    function assignRole(
        address[] memory beAddres,
        string memory role
    ) internal pure returns (BEInfo[] memory) {
        BEInfo[] memory beInfos = new BEInfo[](beAddres.length);
        for (uint256 i = 0; i < beAddres.length; i++) {
            beInfos[i].beAddress = beAddres[i];
            beInfos[i].role = role;
        }
        return beInfos;
    }

    // Merge the roles with the BE array
    function mergeRoles(
        BEInfo[] memory arr1,
        BEInfo[] memory arr2
    ) internal pure returns (BEInfo[] memory) {
        BEInfo[] memory merged = new BEInfo[](arr1.length + arr2.length);
        uint256 index = 0;

        for (uint256 i = 0; i < arr1.length; i++) {
            merged[index] = arr1[i];
            index++;
        }

        for (uint256 i = 0; i < arr2.length; i++) {
            merged[index] = arr2[i];
            index++;
        }

        return merged;
    }

    // Find the notification party index
    function getNotificationPartyIndex(
        BEData storage be,
        address _partyAddress
    ) internal view returns (uint256) {
        for (uint256 i = 0; i < be.notificationParties.length; i++) {
            if (
                be.notificationParties[i].notificationPartyAddress ==
                _partyAddress
            ) {
                return i;
            }
        }
        revert("Notification party not found.");
    }
}
