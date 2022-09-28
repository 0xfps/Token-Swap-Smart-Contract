// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

import "./Interfaces/IERC20.sol";

/*
 * @title: 
 * @author: Anthony (fps) https://github.com/0xfps.
 * @dev: 
 * The contract below demonstrate a swap of two tokens between two parties at the same time (atomic).
 *
 * Alice owns token 1.
 * Bob owns token 2.
 * The function in contract below will execute successfully only if it can swap both tokens at the same exact time.
 * Think about the future possibilities of this type of exchange. 
 * This contract eliminates the need of trust between two parties.
 *
 *
 * Can we make this contract more open?
*/
contract TokenSwap {
    /*
    * @dev: Struct:: Pair.
    *
    * Data mapped to an address, each address has a unique map.
    * It contains:
    * - The user's `token`.
    * - The users preferred `partners`.
    * - `allowed`, which is true if the `parter` has accepted the pair with the owner.
    */
    struct Pair {
        IERC20 token;
        address partner;
        bool allowed;
    }

    /*
    * @dev: Mapping:: partners.
    *
    * mapping an the `msg.sender`'s address to his own Pair struct.
    */
    mapping(address => Pair) public partners;

    /*
    * @dev: Events.
    *
    * Emitted on specific functions.
    */
    event RegisterPair(address, address, address);  // Owner, token, partner.

    /*
    * @dev: Modifier isValidSender.
    *
    * Requires that the `msg.sender` is not a 0 address.
    */
    modifier isValidSender() {
        require(msg.sender != address(0), "Not a valid sender.");
        _;
    }

    /*
    * @devL initiateToken(address __token).
    *
    * Initialized a new token for the person who choses to register a new pair.
    */
    function initiateToken(address __token) private pure returns(IERC20 initalized_token) {
        require(__token != address(0), "Invalid token");
        initalized_token = IERC20(__token);
    }

    /*
    * @dev: register().
    *
    * Creates a new user with initialized `_token`.
    */
    function register(address _token) public isValidSender {
        IERC20 ini_token = initiateToken(_token);
        partners[msg.sender].token = ini_token;
    }
    
    /*
    * @dev: registerPartner(address _token, address _partner).
    *
    * `msg.sender` creates a new pair with `_token` and choses `_partner` as partners.
    *
    * Conditions:
    *
    * The `msg.sender` has no created pairs yet.
    */
    function registerPartner(address _partner) public isValidSender {
        require(partners[msg.sender].partner == address(0), "You have a pair already, close it.");
        require(_partner != address(0), "Invalid partners address");
        require(msg.sender != _partner, "You cannot be your own partners");
        require(partners[_partner].token != IERC20(address(0)), "Partner inexistent.");
        
        partners[msg.sender].partner = _partner;
    }
    
    /*
    * @dev: acceptPair(address _address).
    *
    * `msg.sender` accepts to be the `partner` proposed by the `_address`.
    * The `_address` here is the person who requested through registerPair().
    * The allowed is set to true.
    */
    function acceptPair(address _address) public isValidSender {
        require(_address != address(0), "Address is invalid");
        require(partners[_address].partner == msg.sender, "You are not partnerss.");

        partners[_address].allowed = true;
    }

    /*
    * @dev: rejectPair(address _address).
    *
    * `msg.sender` rejects to be the `partner` proposed by the `_address`.
    * The `_address` here is the person who requested through registerPair().
    * The allowed is set to false.
    */
    function rejectPair(address _address) public isValidSender {
        require(_address != address(0), "Address is invalid");
        require(partners[_address].partner == msg.sender, "You are not partnerss.");

        partners[_address].allowed = false;
    }

    /*
    * @dev: swap(uint256 _amount1, uint256 _amount2).
    * 
    * Swaps tokens between two persons.
    * `msg.sender` must have a `partner` with the `allowed` set to `true`.
    * The `partner` must have his own `token`.
    * The `allowance` from the both of them wrt to the contract must be greater than the `_amount1` and `_amount2` for `msg.sender` and `partner` respectively.
    * 
    * Make the transferFrom.
    */
    function swap(uint256 _amount1, uint256 _amount2) public isValidSender {
        require(partners[msg.sender].partner != address(0), "You have no partner for this swap.");
        require(partners[msg.sender].allowed, "You are not allowed to.");


        address _partner = partners[msg.sender].partner;
        require(partners[_partner].token != IERC20(address(0)), "Your partner has no tokens.");

        address owner = msg.sender;

        IERC20 token1 = partners[owner].token;
        IERC20 token2 = partners[_partner].token;

        require(token1.allowance(owner, address(this)) >= _amount1, "Token 1 Allowance > amount.");
        require(token2.allowance(_partner, address(this)) >= _amount2, "Token 2 Allowance > amount.");

        bool s1 = token1.transferFrom(owner, _partner, _amount1);
        bool s2 = token2.transferFrom(_partner, owner, _amount1);

        bool sent = s1 && s2;

        require(sent, "Token not sent.");
    }
}
