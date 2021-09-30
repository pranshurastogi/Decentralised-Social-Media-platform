// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking{
    using SafeMath for uint256;
    IERC20 public DSMT;


    mapping(address => uint256) public stakes;

        //need to add set admin functionality
    function StakeToken(uint256 _stakeAmount) public {
        DSMT.transferFrom(msg.sender, address(this), _stakeAmount);
        stakes[msg.sender] = stakes[msg.sender].add(_stakeAmount);
    }
                //need to add delete admin functionality
    function unstakeToken(uint256 _stakeAmount) public {
        stakes[msg.sender] = stakes[msg.sender].sub(_stakeAmount);
        DSMT.transfer(msg.sender, _stakeAmount);
    }

    function getStakeBalance(address _StakeAddress) public view returns (uint256) {
        return stakes[_StakeAddress];
    }

}