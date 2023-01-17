// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
interface Swapper {
    function convertV1(address _to, uint256 _amount) external;
}
