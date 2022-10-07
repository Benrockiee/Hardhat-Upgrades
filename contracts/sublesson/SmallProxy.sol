// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/Proxy.sol";

//To deal with proxies, we really dont wanna have anything in storage because if we do
//delegate call and that delegate call changes some storage, we are gonna screw up our
//contracts storage but we still need to store that implementations address somewhere so
//we can call it so EIP-1976 is called the standard proxy storage slots which is an EIP
//for having certain storage slots specifically used for proxies.

//so down below we set bytes32 implementation slot to that location in storage and whatever
//is in that storage slot is going to be our implementation address so the way this is going to work
//is that any contract that calls this proxy contract, if its not this set implementation function,
//its going to pass it over to what is inside the implementation slot address.

contract SmallProxy is Proxy {
    // This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    //This will change where those delegate calls are gonna be sending
    //This can be equivalent with upgrading your smart contracts
    function setImplementation(address newImplementation) public {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    //Then we have implementation here to read where that implementation contract is
    function _implementation() internal view override returns (address implementationAddress) {
        assembly {
            implementationAddress := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // helper function
    function getDataToTransact(uint256 numberToUpdate) public pure returns (bytes memory) {
        return abi.encodeWithSignature("setValue(uint256)", numberToUpdate);
    }

    function readStorage() public view returns (uint256 valueAtStorageSlotZero) {
        assembly {
            valueAtStorageSlotZero := sload(0)
        }
    }
}

contract ImplementationA {
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue;
    }
}

contract ImplementationB {
    uint256 public value;

    function setValue(uint256 newValue) public {
        value = newValue + 2;
    }
}

// function setImplementation(){}
// Transparent Proxy -> Ok, only admins can call functions on the proxy
// anyone else ALWAYS gets sent to the fallback contract.

// UUPS -> Where all upgrade logic is in the implementation contract, and
// you can't have 2 functions with the same function selector.
