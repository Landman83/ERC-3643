// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";

import "../../roles/AgentRoleUpgradeable.sol";
import "../interface/IIdentityRegistryStorage.sol";
import "../storage/IRSStorage.sol";

contract IdentityRegistryStorage is IIdentityRegistryStorage, AgentRoleUpgradeable, IRSStorage {

    function init() external initializer {
        __Ownable_init();
    }

    /**
     *  @dev See {IIdentityRegistryStorage-addIdentityToStorage}.
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country,
        bool _isAccredited,
        bool _isQIB,
        uint256 _accreditationExpiry
    ) external override onlyAgent {
        require(
            _userAddress != address(0)
            && address(_identity) != address(0)
        , "invalid argument - zero address");
        require(address(_identities[_userAddress].identityContract) == address(0), "address stored already");
        require(_accreditationExpiry > block.timestamp, "invalid expiry time");
        _identities[_userAddress].identityContract = _identity;
        _identities[_userAddress].investorCountry = _country;
        
        _accreditationStatus[_userAddress].isAccredited = _isAccredited;
        _accreditationStatus[_userAddress].isQIB = _isQIB;
        _accreditationStatus[_userAddress].expiryTime = _accreditationExpiry;

        emit IdentityStored(_userAddress, _identity);
        emit AccreditationStored(_userAddress, _isAccredited, _isQIB, _accreditationExpiry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredIdentity}.
     */
    function modifyStoredIdentity(address _userAddress, IIdentity _identity) external override onlyAgent {
        require(
            _userAddress != address(0)
            && address(_identity) != address(0)
        , "invalid argument - zero address");
        require(address(_identities[_userAddress].identityContract) != address(0), "address not stored yet");
        IIdentity oldIdentity = _identities[_userAddress].identityContract;
        _identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-modifyStoredInvestorCountry}.
     */
    function modifyStoredInvestorCountry(address _userAddress, uint16 _country) external override onlyAgent {
        require(_userAddress != address(0), "invalid argument - zero address");
        require(address(_identities[_userAddress].identityContract) != address(0), "address not stored yet");
        _identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-removeIdentityFromStorage}.
     */
    function removeIdentityFromStorage(address _userAddress) external override onlyAgent {
        require(_userAddress != address(0), "invalid argument - zero address");
        require(address(_identities[_userAddress].identityContract) != address(0), "address not stored yet");
        IIdentity oldIdentity = _identities[_userAddress].identityContract;
        delete _identities[_userAddress];
        delete _accreditationStatus[_userAddress];
        emit IdentityUnstored(_userAddress, oldIdentity);
        emit AccreditationRemoved(_userAddress);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-bindIdentityRegistry}.
     */
    function bindIdentityRegistry(address _identityRegistry) external override {
        require(_identityRegistry != address(0), "invalid argument - zero address");
        require(_identityRegistries.length < 300, "cannot bind more than 300 IR to 1 IRS");
        addAgent(_identityRegistry);
        _identityRegistries.push(_identityRegistry);
        emit IdentityRegistryBound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-unbindIdentityRegistry}.
     */
    function unbindIdentityRegistry(address _identityRegistry) external override {
        require(_identityRegistry != address(0), "invalid argument - zero address");
        require(_identityRegistries.length > 0, "identity registry is not stored");
        uint256 length = _identityRegistries.length;
        for (uint256 i = 0; i < length; i++) {
            if (_identityRegistries[i] == _identityRegistry) {
                _identityRegistries[i] = _identityRegistries[length - 1];
                _identityRegistries.pop();
                break;
            }
        }
        removeAgent(_identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }

    /**
     *  @dev See {IIdentityRegistryStorage-linkedIdentityRegistries}.
     */
    function linkedIdentityRegistries() external view override returns (address[] memory) {
        return _identityRegistries;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedIdentity}.
     */
    function storedIdentity(address _userAddress) external view override returns (IIdentity) {
        return _identities[_userAddress].identityContract;
    }

    /**
     *  @dev See {IIdentityRegistryStorage-storedInvestorCountry}.
     */
    function storedInvestorCountry(address _userAddress) external view override returns (uint16) {
        return _identities[_userAddress].investorCountry;
    }

    /**
     * @dev See {IIdentityRegistryStorage-modifyStoredAccreditation}.
     */
    function modifyStoredAccreditation(
        address _userAddress,
        bool _isAccredited,
        bool _isQIB,
        uint256 _expiryTime
    ) external override onlyAgent {
        require(_userAddress != address(0), "invalid argument - zero address");
        require(_expiryTime > block.timestamp, "invalid expiry time");
        
        _accreditationStatus[_userAddress].isAccredited = _isAccredited;
        _accreditationStatus[_userAddress].isQIB = _isQIB;
        _accreditationStatus[_userAddress].expiryTime = _expiryTime;
        
        emit AccreditationStored(_userAddress, _isAccredited, _isQIB, _expiryTime);
    }

    /**
     * @dev See {IIdentityRegistryStorage-removeStoredAccreditation}.
     */
    function removeStoredAccreditation(address _userAddress) external override onlyAgent {
        require(_userAddress != address(0), "invalid argument - zero address");
        
        delete _accreditationStatus[_userAddress];
        
        emit AccreditationRemoved(_userAddress);
    }

    /**
     * @dev See {IIdentityRegistryStorage-storedAccreditation}.
     */
    function storedAccreditation(address _userAddress) external view override returns (
        bool isAccredited,
        bool isQIB,
        uint256 expiryTime
    ) {
        AccreditationStatus memory status = _accreditationStatus[_userAddress];
        return (status.isAccredited, status.isQIB, status.expiryTime);
    }
}
