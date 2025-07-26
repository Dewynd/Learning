// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ERC4626 Vault Implementation
/// @author Dewine
contract ERC4626Vault is ERC20 {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint8 private immutable _decimals;

    constructor(IERC20 _asset, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        asset = _asset;
        _decimals = ERC20(address(_asset)).decimals();
    }
    function assetAddress() external view returns (address) {
        return address(asset);
    }

    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function previewDeposit(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) external view returns (uint256 assets) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function previewWithdraw(uint256 assets) external view returns (uint256 shares) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        require(assets > 0, "Invalid amount");
        shares = convertToShares(assets);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
    }

    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        require(shares > 0, "Invalid amount");
        assets = previewMint(shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        require(assets > 0, "Invalid amount");
        shares = convertToShares(assets);
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        require(shares > 0, "Invalid amount");
        assets = convertToAssets(shares);
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        asset.safeTransfer(receiver, assets);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
