// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract LogicTempBE {
    using Strings for string;
    using Counters for Counters.Counter;

    address[] private beAddresses;

    mapping(address => BEData) private bes;
    mapping(address => BEData) private pendingBes;
    mapping(address => mapping(address => Approval)) public approvals;

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

    struct Approval {
        bool isApproved;
        uint256 timestamp;
    }

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

    function registerBE(uint256 _id, BEData memory _beData) public {
        bytes32 hashInput = keccak256(
            abi.encodePacked(msg.sender, _beData.beName, block.timestamp)
        );
        address beAddress = address(uint160(uint256(hashInput)));

        bes[beAddress].beName = _beData.beName;
        bes[beAddress].creator = msg.sender;
        bes[beAddress].status = "Live";
        bes[beAddress].privacyStatus = "Anonymous";
        bes[beAddress].documentsFiled = _beData.documentsFiled;
        bes[beAddress].hasAgent = _beData.hasAgent;
        bes[beAddress].agent = _beData.agent;
        bes[beAddress].reservePeriod = _beData.reservePeriod;
        bes[beAddress].adminRights = _beData.adminRights;
        bes[beAddress].hasOwners = _beData.hasOwners;
        bes[beAddress].hasNotificationParties = _beData.hasNotificationParties;
        bes[beAddress].hasExpiryDate = _beData.hasExpiryDate;
        bes[beAddress].expiryDate = _beData.expiryDate;
        bes[beAddress].createdAt = block.timestamp;
        bes[beAddress].updatedAt = block.timestamp;
        bes[beAddress].archived = false;
        bes[beAddress].isPending = false;

        for (uint256 i = 0; i < _beData.administrators.length; i++) {
            bes[beAddress].administrators.push(_beData.administrators[i]);
        }
        for (uint256 i = 0; i < _beData.reserveAdministrators.length; i++) {
            bes[beAddress].reserveAdministrators.push(
                _beData.reserveAdministrators[i]
            );
        }
        for (uint256 i = 0; i < _beData.owners.length; i++) {
            bes[beAddress].owners.push(_beData.owners[i]);
        }
        for (uint256 i = 0; i < _beData.notificationParties.length; i++) {
            bes[beAddress].notificationParties.push(
                _beData.notificationParties[i]
            );
        }
        for (uint256 i = 0; i < _beData.documents.length; i++) {
            bes[beAddress].documents.push(_beData.documents[i]);
        }
        beAddresses.push(beAddress);
    }

    // Update a BE
    function updateBE(address beAddress, BEData memory _beData)
        public
        onlyAdministrator(beAddress)
    {
        // Check if the sender has already approved this transaction
        require(
            !approvals[beAddress][msg.sender].isApproved,
            "Administrator already approved"
        );

        // Mark the sender as approved for this transaction
        approvals[beAddress][msg.sender] = Approval(true, block.timestamp);

        if (bes[beAddress].isPending == false) {
            bes[beAddress].isPending = true;

            pendingBes[beAddress].updatedAt = block.timestamp;
            pendingBes[beAddress].beName = _beData.beName;
            pendingBes[beAddress].creator = msg.sender;
            pendingBes[beAddress].status = _beData.status;
            pendingBes[beAddress].privacyStatus = _beData.privacyStatus;
            pendingBes[beAddress].documentsFiled = _beData.documentsFiled;
            pendingBes[beAddress].hasOwners = _beData.hasOwners;
            pendingBes[beAddress].hasAgent = _beData.hasAgent;
            pendingBes[beAddress].hasNotificationParties = _beData
                .hasNotificationParties;
            pendingBes[beAddress].adminRights = _beData.adminRights;
            pendingBes[beAddress].agent = _beData.agent;
            pendingBes[beAddress].hasExpiryDate = _beData.hasExpiryDate;
            pendingBes[beAddress].expiryDate = _beData.expiryDate;
            pendingBes[beAddress].createdAt = _beData.createdAt;
            pendingBes[beAddress].updatedAt = block.timestamp;
            pendingBes[beAddress].archived = _beData.archived;
            pendingBes[beAddress].isPending = true;

            delete pendingBes[beAddress].administrators;
            for (uint256 i = 0; i < _beData.administrators.length; i++) {
                pendingBes[beAddress].administrators.push(
                    _beData.administrators[i]
                );
            }

            delete pendingBes[beAddress].reserveAdministrators;
            for (uint256 i = 0; i < _beData.reserveAdministrators.length; i++) {
                pendingBes[beAddress].reserveAdministrators.push(
                    _beData.reserveAdministrators[i]
                );
            }

            delete pendingBes[beAddress].owners;
            for (uint256 i = 0; i < _beData.owners.length; i++) {
                pendingBes[beAddress].owners.push(_beData.owners[i]);
            }

            delete pendingBes[beAddress].notificationParties;
            for (uint256 i = 0; i < _beData.notificationParties.length; i++) {
                pendingBes[beAddress].notificationParties.push(
                    _beData.notificationParties[i]
                );
            }

            delete pendingBes[beAddress].documents;
            for (uint256 i = 0; i < _beData.documents.length; i++) {
                pendingBes[beAddress].documents.push(_beData.documents[i]);
            }
        }

        if (adminRightsCheck(beAddress)) {
            bes[beAddress] = pendingBes[beAddress];
            bes[beAddress].isPending = false;

            for (uint256 i = 0; i < bes[beAddress].administrators.length; i++) {
                approvals[beAddress][
                    bes[beAddress].administrators[i].adminAddress
                ].isApproved = false;
            }
            emit BEUpdated(beAddress, bes[beAddress].beName, msg.sender);
        }
    }

    // Change BE Status
    function changeBEStatus(address beAddress, string memory newStatus)
        public
        onlyAdministrator(beAddress)
        expirationCheck(beAddress)
        noReentrant
    {
        require(beAddress != address(0), "Invalid BE address.");
        require(
            keccak256(abi.encodePacked(newStatus)) ==
                keccak256(abi.encodePacked("Live")) ||
                keccak256(abi.encodePacked(newStatus)) ==
                keccak256(abi.encodePacked("Deregistered")) ||
                keccak256(abi.encodePacked(newStatus)) ==
                keccak256(abi.encodePacked("Purged")),
            "Invalid new status."
        );

        BEData storage be = bes[beAddress];

        // Disallow changing to the current status
        require(
            keccak256(abi.encodePacked(be.status)) !=
                keccak256(abi.encodePacked(newStatus)),
            "Cannot change to the current status."
        );

        // Set new beStatus
        be.status = newStatus;

        // Update the updatedAt timestamp
        be.updatedAt = block.timestamp;

        emit BEStatusChanged(beAddress, msg.sender, newStatus);
    }

    // Archive the BE
    function archiveBE(address beAddress)
        public
        onlyAdministrator(beAddress)
        expirationCheck(beAddress)
        noReentrant
    {
        require(beAddress != address(0), "Invalid BE address.");

        BEData storage be = bes[beAddress];

        be.archived = true;
        be.archivedAt = block.timestamp;

        emit BEArchived(beAddress, msg.sender);
    }

    // Delete a BE by BE address ⛔️ This is a hard delete! (data will be erased)
    function deleteBE(address beAddress)
        public
        onlyAdministrator(beAddress)
        expirationCheck(beAddress)
        noReentrant
    {
        BEData storage be = bes[beAddress];
        require(bytes(be.beName).length != 0, "BE does not exist");

        delete bes[beAddress];
        emit BEDeleted(beAddress, msg.sender);
    }

    /******* APPROVALS FUNCTIONS *******/
    function handleExpiredApprovals() external {
        for (uint256 i = 0; i < beAddresses.length; i++) {
            address beAddress = beAddresses[i];
            BEData storage be = bes[beAddress];

            for (uint256 j = 0; j < be.administrators.length; j++) {
                Administrator storage admin = be.administrators[j];
                address adminAddress = admin.adminAddress;

                Approval memory approval = approvals[beAddress][adminAddress];
                if (
                    !approval.isApproved &&
                    approval.timestamp + 90 days < block.timestamp
                ) {
                    // Expired approval found
                    address reserveAdmin = be
                        .reserveAdministrators[j]
                        .reserveAdminAddress;
                    if (reserveAdmin != address(0)) {
                        // Swap admin and reserve
                        for (uint256 k = 0; k < be.administrators.length; k++) {
                            if (
                                be.administrators[k].adminAddress ==
                                adminAddress
                            ) {
                                address oldAdmin = be
                                    .administrators[k]
                                    .adminAddress;
                                be
                                    .administrators[k]
                                    .adminAddress = reserveAdmin;
                                be
                                    .reserveAdministrators[j]
                                    .reserveAdminAddress = oldAdmin;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    function testHandleExpiredApprovals() external {
        for (uint256 i = 0; i < beAddresses.length; i++) {
            address beAddress = beAddresses[i];
            BEData storage be = bes[beAddress];

            for (uint256 j = 0; j < be.administrators.length; j++) {
                Administrator storage admin = be.administrators[j];
                address adminAddress = admin.adminAddress;

                Approval memory approval = approvals[beAddress][adminAddress];
                if (
                    !approval.isApproved &&
                    approval.timestamp + 1 < block.timestamp
                ) {
                    // Expired approval found

                    address reserveAdmin = be
                        .reserveAdministrators[j]
                        .reserveAdminAddress;
                    if (reserveAdmin != address(0)) {
                        // Swap admin and reserve
                        for (uint256 k = 0; k < be.administrators.length; k++) {
                            if (
                                be.administrators[k].adminAddress ==
                                adminAddress
                            ) {
                                address oldAdmin = be
                                    .administrators[k]
                                    .adminAddress;
                                be
                                    .administrators[k]
                                    .adminAddress = reserveAdmin;
                                be
                                    .reserveAdministrators[j]
                                    .reserveAdminAddress = oldAdmin;
                                break;
                            }
                        }
                    }
                }
            }
        }
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

    // Check the admin rights for multisig transactions
    function adminRightsCheck(address beAddress) internal view returns (bool) {
        BEData storage be = bes[beAddress];
        uint256 numAdmins = be.administrators.length;

        if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("ANY_ONE"))
        ) {
            return approvals[beAddress][msg.sender].isApproved;
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("FIRST_AND_ANY_ONE"))
        ) {
            if (
                numAdmins >= 3 &&
                approvals[beAddress][be.administrators[0].adminAddress]
                    .isApproved &&
                (approvals[beAddress][be.administrators[1].adminAddress]
                    .isApproved ||
                    approvals[beAddress][be.administrators[2].adminAddress]
                        .isApproved)
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("FIRST_AND_SECOND"))
        ) {
            if (
                numAdmins >= 2 &&
                approvals[beAddress][be.administrators[0].adminAddress]
                    .isApproved &&
                approvals[beAddress][be.administrators[1].adminAddress]
                    .isApproved
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("FIRST_AND_THIRD"))
        ) {
            if (
                numAdmins >= 3 &&
                approvals[beAddress][be.administrators[0].adminAddress]
                    .isApproved &&
                approvals[beAddress][be.administrators[2].adminAddress]
                    .isApproved
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("SECOND_AND_ANY_ONE"))
        ) {
            if (
                numAdmins >= 3 &&
                approvals[beAddress][be.administrators[1].adminAddress]
                    .isApproved &&
                (approvals[beAddress][be.administrators[0].adminAddress]
                    .isApproved ||
                    approvals[beAddress][be.administrators[2].adminAddress]
                        .isApproved)
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("SECOND_AND_THIRD"))
        ) {
            if (
                numAdmins >= 3 &&
                approvals[beAddress][be.administrators[1].adminAddress]
                    .isApproved &&
                approvals[beAddress][be.administrators[2].adminAddress]
                    .isApproved
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("THIRD_AND_ANY_ONE"))
        ) {
            if (
                numAdmins >= 3 &&
                approvals[beAddress][be.administrators[2].adminAddress]
                    .isApproved &&
                (approvals[beAddress][be.administrators[0].adminAddress]
                    .isApproved ||
                    approvals[beAddress][be.administrators[1].adminAddress]
                        .isApproved)
            ) {
                return true;
            }
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("MAJORITY"))
        ) {
            uint256 requiredApprovals = (numAdmins + 1) / 2;
            uint256 approvedCount;
            for (uint256 i = 0; i < numAdmins; i++) {
                if (
                    approvals[beAddress][be.administrators[i].adminAddress]
                        .isApproved
                ) {
                    approvedCount++;
                }
            }
            return approvedCount >= requiredApprovals;
        } else if (
            keccak256(abi.encodePacked(be.adminRights)) ==
            keccak256(abi.encodePacked("ALL"))
        ) {
            for (uint256 i = 0; i < numAdmins; i++) {
                if (
                    !approvals[beAddress][be.administrators[i].adminAddress]
                        .isApproved
                ) {
                    return false;
                }
            }
            return true;
        }

        return false;
    }

    // Function to check if msg.sender is an admin
    function isAdmin(address beAddress, address account)
        internal
        view
        returns (bool)
    {
        BEData storage be = bes[beAddress];
        for (uint256 i = 0; i < be.administrators.length; i++) {
            if (be.administrators[i].adminAddress == account) {
                return true;
            }
        }
        return false;
    }
}
