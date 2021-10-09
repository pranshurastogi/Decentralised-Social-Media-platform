// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract RegisterUser is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    CountersUpgradeable.Counter private _idCounter;

    struct User {
        uint256 userId;
        address userAddress;
        string profilePic;
        string Alias;
        bool exists;
    }

    mapping(address => User[]) userDetails;
    mapping(string=>bool) private userAlias;

    event UserAdded(uint256, address);

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }


    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function incrementAndGet() internal returns (uint256) {
        _idCounter.increment();
        return _idCounter.current();
    }

    function RegisterUsers(string memory _profilePic, string memory _alias)
        external
    {
        require(!userAlias[_alias],"Not avaliable");
        userAlias[_alias]=true;
        uint256 userId = incrementAndGet();
        userDetails[msg.sender].push(
            User(userId, msg.sender, _profilePic, _alias, true)
        );
        emit UserAdded(userId, msg.sender);
    }

    function isUserExists(address _userAddress) external view returns (bool) {
        User[] memory details = userDetails[_userAddress];
        for (uint256 i = 0; i < details.length; i++) {
            if (details[i].exists == true) return (true);
        }
        return (false);
    }

    function deleteStruct() public {
        User[] storage details = userDetails[msg.sender];
        User memory deleteUser;

        for (uint256 i = 0; i < details.length; i++) {
            deleteUser = details[i];
            details[i] = details[details.length - 1];
            details[details.length - 1] = deleteUser;
        }

        details.pop();
    }

    function suspendUser() public {}
}