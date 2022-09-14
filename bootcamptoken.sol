//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////██████╗░░█████╗░░█████╗░██╗░░██╗░█████╗░░█████╗░███╗░░░███╗██████╗░  ░██╗░░░░░░░██╗███████╗██████╗░██████╗░///////////////
///////////////██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██╔══██╗████╗░████║██╔══██╗  ░██║░░██╗░░██║██╔════╝██╔══██╗╚════██╗///////////////
///////////////██████╦╝██║░░██║██║░░██║█████═╝░██║░░╚═╝███████║██╔████╔██║██████╔╝  ░╚██╗████╗██╔╝█████╗░░██████╦╝░█████╔╝///////////////
///////////////██╔══██╗██║░░██║██║░░██║██╔═██╗░██║░░██╗██╔══██║██║╚██╔╝██║██╔═══╝░  ░░████╔═████║░██╔══╝░░██╔══██╗░╚═══██╗///////////////
///////////////██████╦╝╚█████╔╝╚█████╔╝██║░╚██╗╚█████╔╝██║░░██║██║░╚═╝░██║██║░░░░░  ░░╚██╔╝░╚██╔╝░███████╗██████╦╝██████╔╝///////////////
///////////////╚═════╝░░╚════╝░░╚════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░░░░  ░░░╚═╝░░░╚═╝░░╚══════╝╚═════╝░╚═════╝░///////////////
/////////////////////////////////////////////////////////BW3T////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract BootCampWeb3 is ERC777, AccessControl, Pausable {
    address private _owner;
    address private _collector;
    address[] private _defaultOperators;
    uint256 private _feePercent = 10 * 1e18;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    constructor(
        address owner,
        address collector,
        uint256 initial_suply
    ) ERC777("BOOTCAMP3", "BW3", _defaultOperators) {
        _collector = collector;
        _setupRole(COLLECTOR_ROLE, _collector);
        _setupRole(ADMIN_ROLE, owner);
        _owner = owner;
        _mint(owner, initial_suply, "", "");
    }

    function setupMinter(address minter)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _setupRole(MINTER_ROLE, minter);
    }

    function setFee(uint256 percent) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _feePercent = percent *1e18;
    }





    function setCollector(address collector)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _setupRole(COLLECTOR_ROLE, collector);
        _collector = collector;
    }

    function transferFree(address recipient, uint256 amount)
        public
        onlyRole(COLLECTOR_ROLE)
        whenNotPaused
        returns (bool)
    {
        _send(_msgSender(), recipient, amount, "", "", false);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(amount > 0, "The amount cannot be zero");
        require(
            balanceOf(msg.sender) >= amount,
            "You do not have a balance to send this amount"
        );

        if (_feePercent > 0) {
            uint256 _discount = Math.mulDiv(amount, _feePercent, 100 * 1e18);
            _send(_msgSender(), recipient, amount - _discount, "", "", false);
            _send(_msgSender(), _collector, _discount, "", "", false);
        } else {
            _send(_msgSender(), recipient, amount, "", "", false);
        }

        return true;
    }




    function pause() public onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function mint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _mint(to, amount, "", "");
    }
}
