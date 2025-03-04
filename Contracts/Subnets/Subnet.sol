// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title StakingInterface
 * @dev Interface for interacting with the Staking contract
 */
interface StakingInterface {
    function getStake(address account) external view returns (uint256);
}

/**
 * @title Subnet
 * @dev Manages provider registration and verification for a subnet
 */
contract Subnet {
    // Structs
    struct ResourceRequirements {
        uint32 minCpuCores;
        uint32 minMemory;  // in MB
        uint32 minStorage; // in GB
        uint32 minBandwidth; // in Mbps
    }
    
    struct Provider {
        ResourceRequirements resources;
        uint256 joinedAt;
    }
    
    // State variables
    address public king;
    string public title;
    string public description;
    ResourceRequirements public requirements;
    mapping(address => Provider) public providers;
    address[] public providersList; // Only contains verified and active providers
    
    // Staking-related variables
    StakingInterface public stakingContract;
    uint256 public immutable minKingStake; // Minimum stake required for the king
    
    // Events
    event ProviderRegistered(address indexed provider, ResourceRequirements resources);
    event ProviderRemoved(address indexed provider);
    
    // Modifiers
    modifier onlyKing() {
        require(msg.sender == king, "Only king can call this function");
        _;
    }
    
    modifier kingHasEnoughStake() {
        require(stakingContract.getStake(king) >= minKingStake, 
                "King does not have enough stake");
        _;
    }
    
    /**
     * @dev Constructor to create a new subnet
     * @param _stakingContract Address of the staking contract
     * @param _king Address of the subnet king
     * @param _title Name of the subnet
     * @param _description Description of the subnet purpose
     * @param _requirements Resource requirements for providers
     * @param _minKingStake Minimum stake required for the king
     */
    constructor(
        address _stakingContract,
        address _king,
        string memory _title, 
        string memory _description, 
        ResourceRequirements memory _requirements,
        uint256 _minKingStake
    ) {
        require(_stakingContract != address(0), "Invalid staking contract address");
        require(_king != address(0), "Invalid king address");
        
        stakingContract = StakingInterface(_stakingContract);
        king = _king;
        title = _title;
        description = _description;
        requirements = _requirements;
        minKingStake = _minKingStake;
    }
    
    /**
     * @dev King registers and verifies a provider
     * @param provider Address of the provider to register and verify
     * @param resources The resources the provider is offering
     */
    function registerAndVerifyProvider(address provider, ResourceRequirements memory resources) 
        external 
        onlyKing 
        kingHasEnoughStake 
        returns (bool) 
    {
        require(meetsRequirements(resources), "Resources do not meet minimum requirements");
        
        // Add provider to mapping
        providers[provider] = Provider({
            resources: resources,
            joinedAt: block.timestamp
        });
        
        // Add to active providers list
        providersList.push(provider);
        
        emit ProviderRegistered(provider, resources);
        return true;
    }
    
    /**
     * @dev King removes a provider
     * @param provider Address of the provider to remove
     */
    function removeProvider(address provider) external onlyKing returns (bool) {
        require(providers[provider].joinedAt > 0, "Not a registered provider");
        
        // Remove provider from list
        for (uint256 i = 0; i < providersList.length; i++) {
            if (providersList[i] == provider) {
                // Swap with the last element and then pop
                providersList[i] = providersList[providersList.length - 1];
                providersList.pop();
                break;
            }
        }
        
        // Clear provider data
        delete providers[provider];
        
        emit ProviderRemoved(provider);
        return true;
    }
    
    /**
     * @dev Get all active providers for this subnet
     * @return Array of provider addresses
     */
    function getAllProviders() external view returns (address[] memory) {
        return providersList;
    }
    
    /**
     * @dev Get count of active providers
     * @return Number of active providers
     */
    function getProviderCount() external view returns (uint256) {
        return providersList.length;
    }
    
    
    /**
     * @dev Check if resources meet minimum requirements
     * @param resources Resources to check
     * @return true if resources meet requirements
     */
    function meetsRequirements(ResourceRequirements memory resources) internal view returns (bool) {
        return resources.minCpuCores >= requirements.minCpuCores &&
               resources.minMemory >= requirements.minMemory &&
               resources.minStorage >= requirements.minStorage &&
               resources.minBandwidth >= requirements.minBandwidth;
    }
}