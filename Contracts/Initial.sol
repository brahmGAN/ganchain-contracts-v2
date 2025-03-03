// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// its only to put some initial contract. Remove it later. 
contract SimpleContract {
    // State variable to store the string
    string public message;

    // Constructor that sets the initial message
    constructor() {
        message = "Hi subnets";
    }

    // Function to retrieve the message
    function getMessage() public view returns (string memory) {
        return message;
    }
}
