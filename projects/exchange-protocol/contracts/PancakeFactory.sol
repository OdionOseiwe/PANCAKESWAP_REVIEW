// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

import './interfaces/IPancakeFactory.sol';
import './PancakePair.sol';

// --this contracts creates new pairs 
// --also handles setting address feeto

contract PancakeFactory is IPancakeFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(PancakePair).creationCode));

    // panckeswap collects 0.3% fees for every trade
    // pancakeswap in future wil collect 0.5% for every trade and it will go to pancakeswap treasury

    address public feeTo;  // address to send the 0.05% percent to

    address public feeToSetter; // address that sets the feeto address

    //[tokenA][tokenB] = newpair
    mapping(address => mapping(address => address)) public getPair; // a mapping of tokenA , tokenB keys to give a new pair

    // stores all the pairs the factory creates
    address[] public allPairs;

    // emited when a new pair is created
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);


    // intialises the state variable feesToSetter
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    // get the length the number of all pairs
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // using createPair, inputing tokenA , tokenB which the tokens you want to use to create the pair
    function createPair(address tokenA, address tokenB) external returns (address pair) {

        // checks that they are not the same . its doesnt make sense to create a pair with the same tokens
        require(tokenA != tokenB, 'Pancake: IDENTICAL_ADDRESSES');

        // geeting the greater one of the address when coverted to hex to know comes first
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // quick question why are they checking for just token0 not address0 and not the both?
        // --because token0 is the smallet when checked and token1 is graetest and cant be address0 ,
        // --so they want to be sure that the smallest is not address0
        require(token0 != address(0), 'Pancake: ZERO_ADDRESS');

        // checking if the a pair which this two two tokens exits before
        require(getPair[token0][token1] == address(0), 'Pancake: PAIR_EXISTS'); // single check is sufficient   
        
        //gets the btyecode for for the contract to be created
        bytes memory bytecode = type(PancakePair).creationCode;

        // gets a random salt , because they want to use create2 
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        //get the address of the new contract
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // deployed the contract and calls the intialize function
        IPancakePair(pair).initialize(token0, token1);

        // populates the mapping in two ways so that in any way you input the address it will give you the same address
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction

        // pushes it to the array of all pairs 
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Pancake: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
