// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract IcoBootCampW3 is
    AccessControl,
    Pausable,
    IERC777Sender,
    IERC777Recipient
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    IERC777 public _bootCampToken;
    IERC20 public _USDCToken;

    uint256 private _exchangeRateUsdcToBootCamp;
    address private _walletForFunds;

    uint256 private _totalUsdcRaised;
    uint256 private _totalBW3TSold;

    event TokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokensSent(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes userData,
        bytes operatorData
    );

    event TokenPurchased(
        address purchaser,
        uint256 usdcAmount,
        uint256 TokenPurchased
    );

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(address admin, address walletForFunds) {
        _walletForFunds = walletForFunds;
        _setupRole(ADMIN_ROLE, admin);
    }

    function totalUsdcRaised() public view returns (uint256) {
        return _totalUsdcRaised;
    }

    function totalBW3TSold() public view returns (uint256) {
        return _totalBW3TSold;
    }

    function exchangeRateUsdcToBootCamp(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _exchangeRateUsdcToBootCamp = amount;
    }

    function setWalletForFunds(address walletForFunds)
        public
        onlyRole(ADMIN_ROLE)
        whenNotPaused
    {
        _walletForFunds = walletForFunds;
    }

    function purchaseBW3WithUsdc(uint256 _usdcAmount) public whenNotPaused {
        
        // verify if approved
        uint256 usdcAllowance = _USDCToken.allowance(
            _msgSender(),
            address(this)
        );
        
        require(
            usdcAllowance >= _usdcAmount,
            "Public Sale: Not enough USDC allowance"
        );

        // verify usdc balance
        uint256 usdcBalance = _USDCToken.balanceOf(_msgSender());
        require(
            usdcBalance >= _usdcAmount,
            "Public Sale: Not enough USDC balance"
        );

        // transfer usdc to funds wallet
        bool success = _USDCToken.transferFrom(
            _msgSender(),
            _walletForFunds,
            _usdcAmount
        );
        require(success, "Public Sale: Failed to transfer USDC");
        _totalUsdcRaised += _usdcAmount;

        // total PCUY to transfer
        uint256 bw3tToTransfer = _usdcAmount * _exchangeRateUsdcToBootCamp;

        // verify PCUY balance
        uint256 bw3tBalance = _bootCampToken.balanceOf(address(this));
        require(
            bw3tBalance >= bw3tToTransfer,
            "Public Sale: Not enough token to sell"
        );

        // transfer BW3Token to customer
        _bootCampToken.send(_msgSender(), bw3tToTransfer, "");
        _totalBW3TSold += bw3tToTransfer;

        emit TokenPurchased(_msgSender(), _usdcAmount, bw3tToTransfer);
    }

    ////

    function setBootCampTokenAddress(address bootCampToken)
        public
        onlyRole(ADMIN_ROLE)
    {
        _bootCampToken = IERC777(bootCampToken);
    }

    function setUsdcTokenAddress(address uSDCTokenAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        _USDCToken = IERC20(uSDCTokenAddress);
    }

    function setExchangeRateUsdcToBCW3(uint256 amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        _exchangeRateUsdcToBootCamp = amount;
    }

    ////STARDART FUNCTIONS

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensReceived(operator, from, to, amount, userData, operatorData);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        emit TokensSent(operator, from, to, amount, userData, operatorData);
    }

    function version() public pure virtual returns (string memory) {
        return "1.0.0";
    }
}
