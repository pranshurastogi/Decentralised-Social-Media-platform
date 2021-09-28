//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract DSocailMedia {
    enum currentStatus {
        active,
        suspended
    } //status should be deleted or not ?
    struct User {
        string usrName;
        string name;
        string profileImage;
        address userAddress;
        currentStatus status;
        bool exists;
    }

    mapping(address => User) users;

    function registerUsers(
        string memory _usrName,
        string memory _name,
        string memory _profileImage,
        address _userAddress,
        currentStatus _status
    ) public {
        User memory userDetails = User({
            usrName: _usrName,
            name: _name,
            profileImage: _profileImage,
            userAddress: _userAddress,
            status: _status,
            exists: true //user account created
        });
        users[msg.sender] = userDetails;
    }

    function verify(address _userAddress) public view returns (bool) {
        return
            users[_userAddress].userAddress ==
            0x0000000000000000000000000000000000000000;
    }
}
