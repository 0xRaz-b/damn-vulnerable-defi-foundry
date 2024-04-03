// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A simple pool to get flash loans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    error NotEnoughTokensInPool();
    error FlashLoanHasNotBeenPaidBack();
    error BorrowerMustBeAContract();

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));
        if (amount > balanceBefore) revert NotEnoughTokensInPool();
        if (!msg.sender.isContract()) revert BorrowerMustBeAContract();

        liquidityToken.transfer(msg.sender, amount);

        msg.sender.functionCall(abi.encodeWithSignature("receiveFlashLoan(uint256)", amount));

        if (liquidityToken.balanceOf(address(this)) < balanceBefore) {
            revert FlashLoanHasNotBeenPaidBack();
        }
    }
}
/*
Get a flashLoan of liquidityToken

call deposit to mint some accToken and it gonna check if we have liquidityToken which is provided from the flashLoan

call DistributedRewards which will get you reward token based to your accToken 

Give back the liquidityToken 
*/