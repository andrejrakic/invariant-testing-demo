// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract Handler {
    struct AddressSet {
        address[] accounts;
        mapping(address => bool) contains;
    }

    uint256 public ghost_mintedTokens;

    AddressSet internal _actors;

    MyToken public myToken;

    constructor(MyToken _myToken) {
        myToken = _myToken;
    }

    function mint(address to, uint256 amount) public {
        createActor(to);
        ghost_mintedTokens += amount;
        myToken.mint(to, amount);
    }

    function createActor(address account) public {
        if (!_actors.contains[account]) {
            _actors.accounts.push(account);
            _actors.contains[account] = true;
        }
    }

    function getAllActors() public view returns (address[] memory) {
        return _actors.accounts;
    }
}

contract MyTokenTest is Test {
    MyToken public myToken;
    Handler public handler;

    function setUp() public {
        myToken = new MyToken();
        handler = new Handler(myToken);

        excludeContract(address(myToken));
    }

    // INVARIANT: Owner can never be zero address
    function invariantOwnerCannotBeZero() external {
        assertTrue(myToken.owner() != address(0));
    }

    // INVARIANT: No one can hold more tokens than total supply
    function invariantTotalSupply() external {
        uint256 totalSupply = myToken.totalSupply();
        uint256 balanceOfCurrentCaller = myToken.balanceOf(msg.sender);

        assertTrue(balanceOfCurrentCaller <= totalSupply);
    }

    // INVARIANT: Sum of all balances must equal to total supply
    function invariantSumBalances() external {
        uint256 totalSupply = myToken.totalSupply();
        uint256 sumBalances = 0;

        address[] memory actors = handler.getAllActors();
        for (uint256 i = 0; i < actors.length; i++) {
            sumBalances += myToken.balanceOf(actors[i]);
        }

        assertEq(sumBalances, totalSupply);
    }

    function invariantSum() external {
        uint256 totalSupply = myToken.totalSupply();
        assertEq(totalSupply, handler.ghost_mintedTokens());
    }
}
