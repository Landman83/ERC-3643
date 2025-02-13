// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../modules/Lockup.sol";
import "../modules/AccInv_QIB.sol";

/**
 * @title Base Regulation 506(c) Compliance Module
 * @dev Base implementation for Reg 506(c) securities compliance
 * Can be used directly or inherited for customization
 */
contract Reg506c is Lockup, AccInv_QIB {
    // 1 year lockup period for Reg 506(c)
    uint256 public constant LOCKUP_DURATION = 183 days;

    /**
     * @dev Initialize the Reg 506(c) module
     * @param _compliance Address of the compliance contract
     * @param _identityRegistry Address of the identity registry
     * @param _deploymentTime Timestamp of token deployment
     */
    function initialize(
        address _compliance,
        address _identityRegistry,
        uint256 _deploymentTime
    ) external virtual {
        // Set identity registry for AI/QIB verification
        setIdentityRegistry(_compliance, _identityRegistry);
        
        // Set lockup parameters
        setTokenDeploymentTime(_compliance, _deploymentTime);
        setLockupPeriod(_compliance, LOCKUP_DURATION);
    }

    // Add extension points for custom behavior
    function _beforeTransferCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) internal virtual returns (bool) {
        return true;
    }

    /**
     * @dev Checks if transfer complies with both lockup and AI/QIB requirements
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens being transferred
     * @param _compliance Address of compliance contract
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 _value,
        address _compliance
    ) external view virtual override(Lockup, AccInv_QIB) returns (bool) {
        // Base checks
        if (!super.moduleCheck(_from, _to, _value, _compliance)) return false;
        
        // Custom checks
        return _beforeTransferCheck(_from, _to, _value, _compliance);
    }

    /**
     * @dev Combined transfer action (currently no action needed)
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override(Lockup, AccInv_QIB) onlyComplianceCall {
        Lockup.moduleTransferAction(_from, _to, _value);
        AccInv_QIB.moduleTransferAction(_from, _to, _value);
    }

    /**
     * @dev Combined mint action (currently no action needed)
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override(Lockup, AccInv_QIB) onlyComplianceCall {
        Lockup.moduleMintAction(_to, _value);
        AccInv_QIB.moduleMintAction(_to, _value);
    }

    /**
     * @dev Combined burn action (currently no action needed)
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override(Lockup, AccInv_QIB) onlyComplianceCall {
        Lockup.moduleBurnAction(_from, _value);
        AccInv_QIB.moduleBurnAction(_from, _value);
    }

    /**
     * @dev Checks if compliance can bind to this module
     */
    function canComplianceBind(address _compliance) external view override(Lockup, AccInv_QIB) returns (bool) {
        return Lockup.canComplianceBind(_compliance) && AccInv_QIB.canComplianceBind(_compliance);
    }

    /**
     * @dev This module requires configuration before binding
     */
    function isPlugAndPlay() external pure override(Lockup, AccInv_QIB) returns (bool) {
        return false;
    }

    /**
     * @dev Name of the module
     */
    function name() public pure override(Lockup, AccInv_QIB) returns (string memory) {
        return "Reg506c";
    }
}

// IMPLEMENTATION CHECKLIST
//
// 1. DEPLOYMENT & CONFIGURATION
//    - Deploy Reg506c contract
//    - Call ModularCompliance.addModule() to bind module
//    - Call initialize() with:
//      * Compliance contract address
//      * Identity Registry address
//      * Token deployment timestamp
//
// 2. IDENTITY REGISTRY SETUP
//    - Ensure Identity Registry is configured with:
//      * Claim topic 5 for Accredited Investor status
//      * Claim topic 6 for QIB status
//    - Configure trusted claim issuers
//
// 3. TESTING REQUIREMENTS
//    - Test transfers during lockup (should fail)
//    - Test transfers after lockup:
//      * Between AIs (should succeed)
//      * Between QIBs (should succeed)
//      * Between AI and QIB (should succeed)
//      * With non-AI/QIB (should fail)
//    - Test minting:
//      * To AI/QIB (should succeed)
//      * To non-AI/QIB (should fail)
//    - Test burning (should succeed)
//    - Test with expired claims
//    - Test with different lockup scenarios
//
// 4. MONITORING & MAINTENANCE
//    - Monitor both:
//      * Lockup period expiration
//      * AI/QIB claim expirations
//    - Document procedures for:
//      * Claim renewals
//      * Status verification
//      * Emergency responses
//
// 5. DOCUMENTATION
//    - Reg 506(c) compliance requirements
//    - Technical integration steps
//    - Lockup period details
//    - AI/QIB verification process
//    - Transfer restriction details
