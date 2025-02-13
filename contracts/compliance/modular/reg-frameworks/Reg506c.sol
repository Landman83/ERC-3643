// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../modules/AbstractModule.sol";
import "../modules/AccInv_QIB.sol";
import "../modules/Lockup.sol";

/**
 * @title Regulation 506(c) Compliance Module
 * @dev Implements full compliance rules for Reg 506(c) securities by composing:
 * 1. AccInv_QIB module for investor verification
 * 2. Lockup module for transfer restriction period (6 months for reporting issuers, 1 year for non-reporting)
 */
contract Reg506c is AbstractModule {
    // Internal module instances
    AccInv_QIB private _accInvQibModule;
    Lockup private _lockupModule;

    // Compliance settings
    uint256 public constant REPORTING_LOCKUP_DURATION = 183 days; // 6 month lockup
    uint256 public constant NONREPORTING_LOCKUP_DURATION = 365 days; // 1 year lockup

    // Issuer status mapping
    mapping(address => bool) private _isReportingIssuer;

    // Events
    event ModulesInitialized(address accInvQibModule, address lockupModule);
    event ComplianceConfigured(address compliance, address identityRegistry, uint256 deploymentTime);
    event IssuerStatusSet(address compliance, bool isReporting);

    /**
     * @dev Initializes the Reg506c module and its submodules
     * @param _compliance Address of the compliance contract
     * @param _identityRegistry Address of the identity registry for AI/QIB verification
     * @param _deploymentTime Token deployment timestamp for lockup calculation
     * @param _isReporting Whether the issuer is a reporting company
     */
    function initialize(
        address _compliance,
        address _identityRegistry,
        uint256 _deploymentTime,
        bool _isReporting
    ) external onlyComplianceCall {
        require(_identityRegistry != address(0), "invalid identity registry");
        require(_deploymentTime <= block.timestamp, "invalid deployment time");

        // Set issuer status
        _isReportingIssuer[_compliance] = _isReporting;
        
        // Deploy and configure AccInv_QIB module
        _accInvQibModule = new AccInv_QIB();
        _accInvQibModule.bindCompliance(_compliance);
        _accInvQibModule.setIdentityRegistry(_compliance, _identityRegistry);

        // Deploy and configure Lockup module with appropriate duration
        _lockupModule = new Lockup();
        _lockupModule.bindCompliance(_compliance);
        _lockupModule.setTokenDeploymentTime(_compliance, _deploymentTime);
        _lockupModule.setLockupPeriod(
            _compliance, 
            _isReporting ? REPORTING_LOCKUP_DURATION : NONREPORTING_LOCKUP_DURATION
        );

        emit ModulesInitialized(address(_accInvQibModule), address(_lockupModule));
        emit ComplianceConfigured(_compliance, _identityRegistry, _deploymentTime);
        emit IssuerStatusSet(_compliance, _isReporting);
    }

    /**
     * @dev Returns the lockup duration based on issuer status
     * @param _compliance Address of the compliance contract
     */
    function getLockupDuration(address _compliance) public view returns (uint256) {
        return _isReportingIssuer[_compliance] ? REPORTING_LOCKUP_DURATION : NONREPORTING_LOCKUP_DURATION;
    }

    /**
     * @dev Returns whether the issuer is a reporting company
     * @param _compliance Address of the compliance contract
     */
    function isReportingIssuer(address _compliance) external view returns (bool) {
        return _isReportingIssuer[_compliance];
    }

    /**
     * @dev Checks if transfer complies with both Reg 506(c) requirements
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
    ) external view override returns (bool) {
        // Check lockup period
        bool lockupCompliant = _lockupModule.moduleCheck(_from, _to, _value, _compliance);
        if (!lockupCompliant) return false;

        // Check AI/QIB status
        bool accreditationCompliant = _accInvQibModule.moduleCheck(_from, _to, _value, _compliance);
        if (!accreditationCompliant) return false;

        return true;
    }

    /**
     * @dev Handles transfer actions for both modules
     */
    function moduleTransferAction(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {
        _lockupModule.moduleTransferAction(_from, _to, _value);
        _accInvQibModule.moduleTransferAction(_from, _to, _value);
    }

    /**
     * @dev Handles mint actions for both modules
     */
    function moduleMintAction(
        address _to,
        uint256 _value
    ) external override onlyComplianceCall {
        _lockupModule.moduleMintAction(_to, _value);
        _accInvQibModule.moduleMintAction(_to, _value);
    }

    /**
     * @dev Handles burn actions for both modules
     */
    function moduleBurnAction(
        address _from,
        uint256 _value
    ) external override onlyComplianceCall {
        _lockupModule.moduleBurnAction(_from, _value);
        _accInvQibModule.moduleBurnAction(_from, _value);
    }

    /**
     * @dev Checks if compliance can bind to this module
     */
    function canComplianceBind(address _compliance) external view returns (bool) {
        return true; // Configuration happens during initialize()
    }

    /**
     * @dev This module requires configuration before use
     */
    function isPlugAndPlay() external pure returns (bool) {
        return false;
    }

    /**
     * @dev Returns the name of the module
     */
    function name() public pure returns (string memory) {
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
