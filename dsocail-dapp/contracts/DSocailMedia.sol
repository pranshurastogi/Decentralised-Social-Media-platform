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

    mapping(address => User[]) users;

    function registerUsers(
        string memory _usrName,
        string memory _name,
        string memory _profileImage,
        address _userAddress,
        currentStatus _status
    ) public {
      
    users[msg.sender].push(User(_usrName, _name,_profileImage,_userAddress,_status,true));

    }

    function isUserExists(address _userAddress) public view returns (bool) {
         User[] storage details = users[_userAddress]; 
         for(uint i=0; i<details.length; i++){
               require( details[i].exists == true,"d");
                     
                }

         }
    }




