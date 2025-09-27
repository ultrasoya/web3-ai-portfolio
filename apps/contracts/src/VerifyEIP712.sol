// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract VerifyEIP712 {
    using ECDSA for bytes32;

    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address from,address to,uint256 amount)");

    constructor(address _verifyingContract) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("MyToken")),
                keccak256(bytes("1")),
                block.chainid,
                _verifyingContract
            )
        );
    }

    function verify(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(TRANSFER_TYPEHASH, _from, _to, _amount))
            )
        );

        address signer = digest.recover(_signature);
        return signer == _from;
    }
}
