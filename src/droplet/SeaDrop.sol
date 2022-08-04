// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { ISeaDrop } from "./ISeaDrop.sol";

import {
    PublicDrop,
    AllowListMint,
    AllowListData,
    UserData
} from "./SeaDropStructs.sol";
import { ERC20, SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { DropEventsAndErrors } from "../DropEventsAndErrors.sol";
import { IERC721SeaDrop } from "./IERC721SeaDrop.sol";
import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";

contract SeaDrop is ISeaDrop, DropEventsAndErrors {
    mapping(address => PublicDrop) public _publicDrops;
    mapping(address => ERC20) public _saleTokens;
    mapping(address => address) public _creatorPayoutAddresses;
    mapping(address => bytes32) public _merkleRoots;
    mapping(address => mapping(address => bool)) public _allowedFeeRecipients;
    // mapping(address => mapping(address => UserData)) public _userData;

    modifier isActive(PublicDrop memory publicDrop) {
        {
            if (block.timestamp < publicDrop.startTime) {
                revert NotActive(
                    block.timestamp,
                    publicDrop.startTime,
                    type(uint64).max
                );
            }
        }
        _;
    }

    modifier includesCorrectPayment(uint256 numberToMint, uint256 mintPrice) {
        {
            if (numberToMint * mintPrice != msg.value) {
                revert IncorrectPayment(msg.value, numberToMint * mintPrice);
            }
        }
        _;
    }

    /**
     * @notice Modifier that checks numberToMint against maxPerTransaction and publicDrop.maxMintsPerWallet
     */
    modifier checkNumberToMint(
        IERC721SeaDrop nftToken,
        uint256 numberToMint,
        PublicDrop memory publicDrop // todo: we may be able to trust AllowListMint's maxTotalMintsForWallet - but we might not want to
    ) {
        {
            // if (numberToMint > publicDrop.maxMintsPerTransaction) {
            //     revert AmountExceedsMaxPerTransaction(
            //         numberToMint,
            //         publicDrop.maxMintsPerTransaction
            //     );
            // }
            if (
                (numberToMint + nftToken.numberMinted(msg.sender) >
                    publicDrop.maxMintsPerWallet)
            ) {
                revert AmountExceedsMaxPerWallet(
                    numberToMint + nftToken.numberMinted(msg.sender),
                    publicDrop.maxMintsPerWallet
                );
            }
        }
        _;
    }

    modifier isAllowListed(
        bytes32 leaf,
        bytes32 merkleRoot,
        bytes32[] calldata proof
    ) {
        {
            if (!MerkleProofLib.verify(proof, merkleRoot, leaf)) {
                revert InvalidProof();
            }
        }
        _;
    }

    function mintPublic(
        address nftContract,
        address feeRecipient,
        uint256 amount
    )
        external
        payable
        override
        isActive(_publicDrops[nftContract])
        includesCorrectPayment(amount, _publicDrops[nftContract].mintPrice)
        checkNumberToMint(
            IERC721SeaDrop(nftContract),
            amount,
            _publicDrops[nftContract]
        )
    {
        PublicDrop memory publicDrop = _publicDrops[nftContract];
        _splitPayout(nftContract, feeRecipient, publicDrop.feeBps);
        IERC721SeaDrop(nftContract).mintSeaDrop(msg.sender, amount);
    }

    function mintAllowList(
        address nftContract,
        address feeRecipient,
        AllowListMint calldata mintParams
    )
        external
        payable
        override
        isActive(_publicDrops[nftContract])
        includesCorrectPayment(
            mintParams.numToMint,
            _publicDrops[nftContract].mintPrice
        )
        checkNumberToMint(
            IERC721SeaDrop(nftContract),
            mintParams.numToMint,
            _publicDrops[nftContract]
        )
    {
        _splitPayout(nftContract, feeRecipient, mintParams.feeBps);
        IERC721SeaDrop(nftContract).mintSeaDrop(
            msg.sender,
            mintParams.numToMint
        );
    }

    function _splitPayout(
        address nftContract,
        address feeRecipient,
        uint256 feeBps
    ) internal {
        uint256 feeAmount = (msg.value * feeBps) / 10000;
        uint256 payoutAmount = msg.value - feeAmount;
        ERC20 saleToken = _saleTokens[nftContract];
        if (address(saleToken) == address(0)) {
            SafeTransferLib.safeTransferETH(feeRecipient, feeAmount);
            SafeTransferLib.safeTransferETH(
                _creatorPayoutAddresses[nftContract],
                payoutAmount
            );
        } else {
            SafeTransferLib.safeTransferFrom(
                saleToken,
                msg.sender,
                feeRecipient,
                feeAmount
            );
            SafeTransferLib.safeTransferFrom(
                saleToken,
                msg.sender,
                _creatorPayoutAddresses[nftContract],
                payoutAmount
            );
        }
    }

    function getPublicDrop(address nftContract)
        external
        view
        returns (PublicDrop memory)
    {
        return _publicDrops[nftContract];
    }

    function getSaleToken(address nftContract) external view returns (address) {
        return address(_saleTokens[nftContract]);
    }

    function getCreatorPayoutAddress(address nftContract)
        external
        view
        returns (address)
    {
        return _creatorPayoutAddresses[nftContract];
    }

    function getMerkleRoot(address nftContract)
        external
        view
        returns (bytes32)
    {
        return _merkleRoots[nftContract];
    }

    // function getUserData(address nftContract, address user)
    //     external
    //     view
    //     returns (UserData memory)
    // {
    //     return _userData[nftContract][user];
    // }

    function updatePublicDrop(PublicDrop calldata publicDrop)
        external
        override
    {
        _publicDrops[msg.sender] = publicDrop;
        emit PublicDropUpdated(msg.sender, publicDrop);
    }

    function updateAllowList(AllowListData calldata allowListData)
        external
        override
    {
        _merkleRoots[msg.sender] = allowListData.merkleRoot;
        emit AllowListUpdated(
            msg.sender,
            allowListData.leavesEncryptionPublicKey,
            allowListData.merkleRoot,
            allowListData.leavesHash,
            allowListData.leavesURI
        );
    }

    /// @notice emit DropURIUpdated event
    function updateDropURI(string calldata dropURI) external {
        emit DropURIUpdated(msg.sender, dropURI);
    }

    function updateCreatorPayoutAddress(address _payoutAddress) external {
        _creatorPayoutAddresses[msg.sender] = _payoutAddress;
        emit CreatorPayoutAddressUpdated(msg.sender, _payoutAddress);
    }

    function updateAllowedFeeRecipient(
        address allowedFeeRecipient,
        bool allowed
    ) external {
        _allowedFeeRecipients[msg.sender][allowedFeeRecipient] = allowed;
        emit AllowedFeeRecipientUpdated(
            msg.sender,
            allowedFeeRecipient,
            allowed
        );
    }
}
