// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct IpfsCID {
        bytes32 hashDigest;
        uint8 hashFunction;
        uint8 size;
    }
}
