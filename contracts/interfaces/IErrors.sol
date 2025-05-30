// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Errors only interface for the {GPU} implementations.
 */
interface IErrors 
{
  /**
   * @dev Displayed when transfer failed 
   */
  error TransferFailed();

  /**
    * @dev Displayed when a wrong functionType is passed as a parameter
   */
  error wrongFunctionType();

  /**
    * @dev Displayed there's a mismatch in the arrays length that's passed 
   */
  error incorrectArraySize();

  /**
    * @dev Displayed when createSubnet() isn't yet available for users
   */
  error createSubnetsNotYetAvailable();   

  /**
    * @dev Displayed when deleteSubnet() isn't yet available for users
   */
  error deleteSubnetsNotYetAvailable();  
  
   /**
    * @dev Displayed when the user isn't the king of the subnet
   */
  error unauthorizedKing();

  /**
    * @dev Displayed when the subnet is either already deleted or doesn't exist
   */
  error subnetDeletedOrDoesntExist();

  /**
    * @dev Displayed when the users can't create multiple subnets 
   */
  error cannotCreateMultipleSubnets();

  /**
    * @dev Displayed when the users don't have sufficient vote balance 
   */
  error insufficientBalanceToCastVotes();  

  /**
    * @dev Displayed when the users are trying to revoke votes more than what they've already cast  
   */
  error insufficientBalanceToRemoveVotes();  

  /**
    * @dev Displayed when the users is trying to claim more than their current pending rewards  
   */
  error exceedesPendingRewards();  

  /**
    * @dev Displayed when there's no sufficient balance of $GP's in the contract 
   */
  error inSufficientBalanceInContract();  

  /**
    * @dev Displayed when claimRewards() isn't yet available for users
   */
  error claimRewardsNotYetAvailable();  

  /**
    * @dev Displayed when castVotes() isn't yet available for users
   */
  error castVotesNotYetAvailable();  

  /**
    * @dev Displayed when unCastVotes() isn't yet available for users
   */
  error unCastVotesNotYetAvailable();  

   /**
    * @dev Displayed when thre's insufficient nodes avaiable 
   */
  error insufficientNodes();  

   /**
    * @dev Displayed when user isn't the owner of the node
   */
  error unAuthorizedOwner();  

  /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error incorrectAmount(); 

    /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error sellNodesNotYetAvailable(); 

   /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error buyNodesNotYetAvailable(); 

   /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error cancelSellOrderNotYetAvailable(); 

  /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error contractNotApproved(); 

  /**
    * @dev Displayed when node buyer has sent the incorrect amount
   */
  error incorrectUnCastVoteValue(); 

   /**
    * @dev Displayed when a funcion isn't available yet
   */
  error notYetAvailable(); 

  /**
    * @dev Displayed when a funcion isn't available yet
   */
  error providerExists(); 

  error NothingToClaim();
}