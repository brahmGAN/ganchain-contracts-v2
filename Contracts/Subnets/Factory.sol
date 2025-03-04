// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Subnet.sol";

contract SubnetFactory {
    // State variables
    address public stakingContract;
    uint256 public minKingStake;
    address[] public subnets;
    mapping(address => address[]) public kingSubnets; // King address => array of their subnets
    
    // Metrics
    uint256 public totalSubnets;
    uint256 public totalKings;
    mapping(address => bool) public isKing;
    mapping(address => bool) public isSubnet;
    
    // Events
    event SubnetCreated(address indexed king, address indexed subnet, string title);

    constructor(address _stakingContract, uint256 _minKingStake) {
        require(_stakingContract != address(0), "Invalid staking contract address");
        stakingContract = _stakingContract;
        minKingStake = _minKingStake;
    }

    function createSubnet(
        string memory title, 
        string memory description, 
        Subnet.ResourceRequirements memory requirements
    ) external returns (address) {
        Subnet subnet = new Subnet (
            stakingContract,
            msg.sender,
            title,
            description,
            requirements,
            minKingStake
            );

            address subnetAddress = address(subnet);

            subnets.push(subnetAddress);
            kingSubnets[msg.sender].push(subnetAddress);

            emit SubnetCreated(msg.sender, subnetAddress, title);

            return subnetAddress;


    }

    /**
     * @dev Get all subnets created by a specific king
     * @param king Address of the king
     * @return Array of subnet addresses
     */
    function getKingSubnets(address king) external view returns (address[] memory) {
        return kingSubnets[king];
    }

    /**
     * @dev Get all subnets created through this factory
     * @return Array of subnet addresses
     */
    function getAllSubnets() external view returns (address[] memory) {
        return subnets;
    }

}