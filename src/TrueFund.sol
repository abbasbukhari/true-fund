// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title TrueFund
 * @author abbasbukhari
 * @notice Transparent, multi-currency donation contract for verified recipients.
 * @dev Donations are sent directly to recipient wallets, tracked on-chain with events. Admin can manage recipients and supported currencies.
 */

contract TrueFund {
    // Event emitted when a recipient is removed from the registry
    event RecipientRemoved(address indexed recipientAddress);

    // The admin address that controls recipient and price feed management
    address public admin;

    // Mapping from recipient address to organization name
    // Used to verify and lookup registered recipients
    mapping(address => string) public recipientsAddressToOrgName;

    constructor() {
        // Set the admin to the contract deployer
        admin = msg.sender;
    }

    function registerRecipientWithOrg(
        address recipientAddress,
        string memory recipientOrgName
    ) external {
        // Only the admin can register a new recipient organization.
        // 'recipientAddress' is the wallet address of the organization or individual who will receive donations.
        // 'recipientOrgName' is the name of the organization associated with the recipient address.
        require(msg.sender == admin, "Only admin can register recipients");
        // Register the recipient by mapping their address to their organization name.
        recipientsAddressToOrgName[recipientAddress] = recipientOrgName;
    }

    function removeRecipientWithOrg(address recipientAddress) external {
        // Only the admin can remove a recipient from the registry
        require(msg.sender == admin, "Only admin can remove recipients");
        // Remove the recipient by deleting their address from the mapping
        delete recipientsAddressToOrgName[recipientAddress];
        // Emit an event for transparency
        emit RecipientRemoved(recipientAddress);
    }
}
