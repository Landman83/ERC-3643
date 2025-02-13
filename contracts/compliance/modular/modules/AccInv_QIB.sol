// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./AbstractModule.sol";
import "../../../registry/interface/IIdentityRegistry.sol";

/**
 * @title AccInv_QIB Module
 * @dev Compliance module requiring all token holders to be either Accredited Investors or QIBs
 * Uses identity claims to verify status
 */
contract AccInv_QIB is AbstractModule {
    // Claim topics for verification
    uint256 public constant ACCREDITED_INVESTOR_CLAIM = 1; // Example claim topic for Accredited Investor
    uint256 public constant QIB_CLAIM = 2; // Example claim topic for Qualified Institutional Buyer

    // Reference to token's Identity Registry
    mapping(address => IIdentityRegistry) private _identityRegistry;

    /**
     * @dev Checks if an address has valid Accredited Investor or QIB claims
     * @param _userAddress Address to check
     * @param _compliance Address of compliance contract checking
     * @return bool True if address has valid claims
     */
    function _hasValidClaims(address _userAddress, address _compliance) internal view returns (bool) {
        // Get user's Identity from registry
        address identity = _identityRegistry[_compliance].identity(_userAddress);
        if (identity == address(0)) return false;

        // Check for either Accredited Investor OR QIB claim
        return (_identityRegistry[_compliance].hasValidClaim(identity, ACCREDITED_INVESTOR_CLAIM) ||
                _identityRegistry[_compliance].hasValidClaim(identity, QIB_CLAIM));
    }

    /**
     * @dev Sets the identity registry for a specific compliance contract
     * @param _compliance Address of the compliance contract
     * @param _identityRegistry_ Address of the identity registry
     */
    function setIdentityRegistry(address _compliance, address _identityRegistry_) external onlyComplianceCall {
        require(_identityRegistry_ != address(0), "invalid argument - zero address");
        _identityRegistry[_compliance] = IIdentityRegistry(_identityRegistry_);
    }

    /**
     * @dev Checks if transfer is compliant - both parties must have valid claims
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens being transferred (not used in this check)
     * @param _compliance Address of compliance contract
     */
    function moduleCheck(
        address _from, 
        address _to,
        uint256 _value,
        address _compliance
    ) external view override returns (bool) {
        // Skip check if it's a mint operation (transfer from zero address)
        if (_from == address(0)) {
            return _hasValidClaims(_to, _compliance);
        }
        
        // Skip check if it's a burn operation (transfer to zero address)
        if (_to == address(0)) {
            return true;
        }

        // Both parties must have valid claims
        return _hasValidClaims(_from, _compliance) && _hasValidClaims(_to, _compliance);
    }

    /**
     * @dev No transfer action required
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     * @dev No mint action required
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     * @dev No burn action required
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override onlyComplianceCall {}

    /**
     * @dev Checks if a compliance contract can bind to this module
     * @param _compliance Address of compliance contract
     */
    function canComplianceBind(address _compliance) external view returns (bool) {
        return _identityRegistry[_compliance] != IIdentityRegistry(address(0));
    }

    /**
     * @dev This module requires configuration before binding
     */
    function isPlugAndPlay() external pure returns (bool) {
        return false;
    }

    /**
     * @dev Name of the module
     */
    function name() public pure returns (string memory) {
        return "AccInv_QIB";
    }
}

// IMPLEMENTATION CHECKLIST
//
// 1. IDENTITY REGISTRY SETUP
//    - Deploy IdentityRegistry contract if not already deployed
//    - Configure ClaimTopicsRegistry with:
//      * Topic 1 for Accredited Investor claims
//      * Topic 2 for QIB claims
//    - Configure TrustedIssuersRegistry with authorized claim issuers
//    - Link ClaimTopicsRegistry and TrustedIssuersRegistry to IdentityRegistry
//
// 2. IDENTITY & CLAIMS SETUP
//    - Deploy ONCHAINID contracts for each participant from forked repository
//    - Trusted Issuers must add claims to participant identities:
//      * Claim topic 1 for Accredited Investors
//      * Claim topic 2 for Qualified Institutional Buyers
//    - Ensure claims include appropriate expiration dates
//
// 3. MODULE DEPLOYMENT & CONFIGURATION
//    - Deploy this AccInv_QIB module
//    - Call ModularCompliance.addModule() to bind module
//    - Call ModularCompliance.callModuleFunction() to execute setIdentityRegistry()
//      with correct IdentityRegistry address
//
// 4. TOKEN CONFIGURATION
//    - Ensure token is bound to ModularCompliance contract
//    - Configure token with correct IdentityRegistry
//    - Set up appropriate token roles (agent, owner)
//
// 5. TESTING REQUIREMENTS
//    - Test transfer between two valid AIs
//    - Test transfer between AI and QIB
//    - Test transfer with expired claims
//    - Test transfer with invalid participants
//    - Test minting to AI/QIB addresses
//    - Test burning from AI/QIB addresses
//    - Verify claim expiration handling
//    - Test recovery procedures for expired claims
//
// 6. MONITORING & MAINTENANCE
//    - Set up monitoring for claim expirations
//    - Document claim renewal process
//    - Create procedures for:
//      * Adding new trusted issuers
//      * Updating claim topics
//      * Handling compromised identities
//      * Emergency pause procedures
//
// 7. DOCUMENTATION
//    - Technical integration guide
//    - Claim issuance procedures
//    - Compliance requirements for:
//      * Accredited Investor verification
//      * QIB verification
//    - User guides for:
//      * Claim renewal
//      * Identity recovery
//      * Transfer procedures

// NOTES
// - Create a bidding marketplace for KYC/AML providers to keep costs down.



