// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  // Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  mapping(address => uint256) public balances;

  event Stake(address indexed staker, uint256 amount);

  uint256 public constant threshold = 1 ether;

  function stake() public payable {
//
    require(block.timestamp < deadline, "Staking period is over");  // Ensure staking happens before the deadline
    balances[msg.sender] += msg.value;  // Track individual balances
    emit Stake(msg.sender, msg.value);  // Emit the Stake event for frontend display
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  uint256 public deadline = block.timestamp + 72 hours;

bool public openForWithdraw;
bool public executed;

// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function execute() public {
//
    require(block.timestamp >= deadline, "Deadline has not been reached yet");
    require(!executed, "Already executed");  // Ensure execute is called only once
    executed = true;  // Mark the execution as complete

    if (address(this).balance >= threshold) {
        // If the balance is greater than or equal to the threshold, call complete()
        exampleExternalContract.complete{value: address(this).balance}();
    } else {
        // If the threshold is not met, allow withdrawals
        openForWithdraw = true;
    }
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `withdraw()` function to let users withdraw their balance
  function withdraw() public {
//
    require(openForWithdraw, "Withdrawals are not allowed");
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "No balance to withdraw");

    balances[msg.sender] = 0;  // Reset the balance to avoid re-entrancy attacks
    (bool success, ) = msg.sender.call{value: userBalance}("");
    require(success, "Withdrawal failed");
  }

  // Add the `receive()` special function that receives eth and calls stake()
receive() external payable {
    stake();  // Automatically call the stake function
}

}
