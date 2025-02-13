// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./AbstractModule.sol";
import "../../../token/IToken.sol";

/**
 * @title Base Lockup Module
 * @dev Abstract compliance module enforcing a lockup period for token transfers
 * Lockup period starts when token is deployed
 * Specific lockup duration to be set by inheriting contracts
 */
abstract contract Lockup is AbstractModule {
    // Mapping of compliance contract address to token deployment timestamp
    mapping(address => uint256) private _tokenDeploymentTime;
    
    // Mapping of compliance contract to lockup duration (in seconds)
    mapping(address => uint256) private _lockupPeriod;

    /**
     * @dev Emitted when lockup period is set for a compliance
     */
    event LockupSet(address indexed compliance, uint256 duration);

    /**
     * @dev Sets the lockup period for a specific compliance contract
     * Can only be called by the compliance contract
     * @param _compliance Address of the compliance contract
     * @param _duration Duration of lockup in seconds
     */
    function setLockupPeriod(address _compliance, uint256 _duration) external onlyComplianceCall {
        require(_duration > 0, "invalid lockup duration");
        _lockupPeriod[_compliance] = _duration;
        emit LockupSet(_compliance, _duration);
    }

    /**
     * @dev Sets the token deployment time for a compliance contract
     * @param _compliance Address of the compliance contract
     * @param _deploymentTime Timestamp of token deployment
     */
    function setTokenDeploymentTime(address _compliance, uint256 _deploymentTime) external onlyComplianceCall {
        require(_tokenDeploymentTime[_compliance] == 0, "deployment time already set");
        require(_deploymentTime <= block.timestamp, "invalid deployment time");
        _tokenDeploymentTime[_compliance] = _deploymentTime;
    }

    /**
     * @dev Checks if the lockup period has expired
     * @param _compliance Address of compliance contract
     */
    function isLockupPeriodExpired(address _compliance) public view returns (bool) {
        if (_tokenDeploymentTime[_compliance] == 0) return false;
        return block.timestamp >= _tokenDeploymentTime[_compliance] + _lockupPeriod[_compliance];
    }

    /**
     * @dev Returns remaining lockup time in seconds
     * @param _compliance Address of compliance contract
     */
    function remainingLockupTime(address _compliance) external view returns (uint256) {
        if (isLockupPeriodExpired(_compliance)) return 0;
        return _tokenDeploymentTime[_compliance] + _lockupPeriod[_compliance] - block.timestamp;
    }

    /**
     * @dev Checks if transfer is compliant with lockup rules
     * Allows transfers only after lockup period expires
     */
    function moduleCheck(
        address _from,
        address _to,
        uint256 /*_value*/,
        address _compliance
    ) external view override returns (bool) {
        // Allow minting and burning operations during lockup
        if (_from == address(0) || _to == address(0)) return true;
        
        // Block transfers until lockup period expires
        return isLockupPeriodExpired(_compliance);
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
     * @dev Module requires configuration before binding
     */
    function isPlugAndPlay() external pure returns (bool) {
        return false;
    }

    /**
     * @dev Checks if compliance can bind to this module
     */
    function canComplianceBind(address _compliance) external view returns (bool) {
        return _tokenDeploymentTime[_compliance] != 0 && _lockupPeriod[_compliance] != 0;
    }

    /**
     * @dev Name of the module
     */
    function name() public pure virtual returns (string memory) {
        return "Lockup";
    }
}

// IMPLEMENTATION CHECKLIST
//
// 1. DEPLOYMENT & CONFIGURATION
//    - Deploy specific lockup contract that inherits from this base contract
//    - Call ModularCompliance.addModule() to bind module
//    - Set token deployment time via ModularCompliance.callModuleFunction()
//    - Set lockup period via ModularCompliance.callModuleFunction()
//
// 2. TESTING REQUIREMENTS
//    - Test transfers during lockup period (should fail)
//    - Test transfers after lockup period (should succeed)
//    - Test minting during lockup (should succeed)
//    - Test burning during lockup (should succeed)
//    - Verify lockup period calculation
//    - Test with different lockup durations
//
// 3. MONITORING & MAINTENANCE
//    - Monitor lockup expiration
//    - Document procedures for:
//      * Verifying lockup status
//      * Handling emergency situations
//      * Communicating lockup status to token holders
//
// 4. DOCUMENTATION
//    - Technical integration guide
//    - Lockup period details
//    - Transfer restriction details
//    - User guides for:
//      * Checking remaining lockup time
//      * Understanding transfer restrictions
