// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingAndGovernance {
    
    using SafeMath for uint256;
    IERC20 public DSMT;
    uint256 percent;
    address[] public admins;
    mapping(address => uint256) public stakes;

    struct Vote {
        uint256 id;
        uint256 upVote;
        uint256 downVote;
    }
    mapping(uint256 => Vote) votes;

    function isAdmin(address _address) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (_address == admins[i]) return (true);
        }
        return (false);
    }

    function removeAdmin(address _adminAddress) internal {
        
    }
    function setAdmin(address _adminAddress) internal {
        bool _isAdmin = isAdmin(_adminAddress);
        if (!_isAdmin) admins.push(_adminAddress);
    }

    
    function StakeToken(uint256 _stakeAmount, address _userAddress) public {
        if (_stakeAmount >= percent.div(100).mul(_stakeAmount)) {
            DSMT.transferFrom(_userAddress, address(this), _stakeAmount);
            stakes[_userAddress] = stakes[_userAddress].add(_stakeAmount);
            isAdmin(_userAddress);
        } else {
            DSMT.transferFrom(_userAddress, address(this), _stakeAmount);
            stakes[_userAddress] = stakes[_userAddress].add(_stakeAmount);
        }
    }

    function unstakeToken(uint256 _stakeAmount, address _userAddress) public {
        bool _isAdmin = isAdmin(_userAddress);
        if (_isAdmin) {
            stakes[_userAddress] = stakes[_userAddress].sub(_stakeAmount);
            DSMT.transfer(_userAddress, _stakeAmount);
            //  deleteAdmin(_userAddress)  function yet to define
        } else {
            stakes[_userAddress] = stakes[_userAddress].sub(_stakeAmount);
            DSMT.transfer(_userAddress, _stakeAmount);
        }
    }

    function getStakeBalance(address _StakeAddress)
        public
        view
        returns (uint256)
    {
        return stakes[_StakeAddress];
    }

    function upVote(uint256 _id) public {
        
    votes[_id].upVote = votes[_id].upVote.add(1);
        
    }

    function downVote(uint256 _id) public {
       
    votes[_id].downVote = votes[_id].downVote.sub(1);
        
    }


}
