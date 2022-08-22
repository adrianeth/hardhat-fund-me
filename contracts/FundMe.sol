//get funds from users
//withdraw
//set a minimum funding value in usd

//SPDX-License-Identifier: MIT

// Pragma
pragma solidity ^0.8.8;

// Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
import "hardhat/console.sol";

// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries

//Contracts

/** @title A contract for crowdfunding
 *  @author Adrian
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    //constant and immutable keywords for gas optimization - in solidity documentation
    // State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //represents doing the rest of the code
    }

    //called immediately when you deploy the contract
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //what happens is someone sends this contract ETH without calling fund function?

    //see fallbackexample.sol

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        //want to be able to set a minimm fund amount in usd
        //1. how do we send eth to this contract?
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 value in wei of 1 eth
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
        //revert - undo any action and send the remaining gas back
    }

    function withdraw() public onlyOwner {
        //require(msg.sender == owner, "Sender is not owner"); //is msg.sender the same as owner?
        //resent amount funded of each address
        /*starting index; ending index; step amount */
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        //reset funders array
        s_funders = new address[](0);

        //withdraw funds

        /*Transfer Method
        payable(msg.sender).transfer(address(this).balance);*/

        /*Send method
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");*/
        // uint256 withdrawnValue = address(this).balance / 1e18;
        /*Call method*/
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");

        // console.log("Owner successfully withdrawn %s ETH", withdrawnValue);
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
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

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
