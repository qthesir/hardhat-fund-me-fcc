// Get funds from users
// Withdraw funds
// Set a minimum funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//imports

import "./PriceConverter.sol";

//error codes

error FundMe__NotOwner();

//interfaces, libraries, contracts

/// @title A contract for crowdfunding
/// @author Q
/// @notice This contract is to demo a sample funding contract
/// @dev This implements price feeds as our library

contract FundMe {
    //Type declarations

    using PriceConverter for uint256;

    //State Variables

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
        //if I put the underscore above the "require" function, it would run all
        //the code in the function calling the modifier first.
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view/pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // Recieve()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // fallback()

    /// @notice This function is to fund the contract
    /// @dev This is the main function to fund the contract

    function fund() public payable {
        //msg.value.getConversionRate();
        // want to be able to set a minimum fund amount
        // 1. how do we send ETH to this contract?
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 = 1 * 10 ** 18 = 10000000000000 (i.e. 1 eth, math in wei)
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
        // 18 decimals
        // What is reverting? undo any action that happened before, and send remaining gas back
    }

    function withdraw() public onlyOwner {
        /*  starting index, endin index, step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);
        // withdraw the funds
        // 0, 10, 1
        // transfer
        // send
        // call
        // payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings cant be in memory. They are always in storage.abi
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (address) {
        return address(s_priceFeed);
    }

    //what happens when people send money without calling fund?
}
