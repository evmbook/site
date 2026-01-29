// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ERC721Token.sol";

/// @title MockERC721Receiver
/// @notice Mock contract that can receive ERC-721 tokens
contract MockERC721Receiver is IERC721Receiver {
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bool public shouldReject;

    function setReject(bool _reject) external {
        shouldReject = _reject;
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        view
        override
        returns (bytes4)
    {
        if (shouldReject) {
            return bytes4(0);
        }
        return _ERC721_RECEIVED;
    }
}

contract ERC721Test is Test {
    SimpleNFT public nft;
    address public owner;
    address public alice;
    address public bob;
    MockERC721Receiver public receiver;

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        receiver = new MockERC721Receiver();

        nft = new SimpleNFT("Test NFT", "TNFT");
    }

    function test_Metadata() public view {
        assertEq(nft.name(), "Test NFT");
        assertEq(nft.symbol(), "TNFT");
    }

    function test_Mint() public {
        uint256 tokenId = nft.mint(alice, "ipfs://token1");

        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(tokenId, 0);
    }

    function test_MintMultiple() public {
        nft.mint(alice, "ipfs://1");
        nft.mint(alice, "ipfs://2");
        nft.mint(bob, "ipfs://3");

        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.totalMinted(), 3);
    }

    function test_TokenURI() public {
        uint256 tokenId = nft.mint(alice, "ipfs://metadata.json");
        assertEq(nft.tokenURI(tokenId), "ipfs://metadata.json");
    }

    function test_Transfer() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_TransferEmitsEvent() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.expectEmit(true, true, true, false);
        emit IERC721.Transfer(alice, bob, tokenId);

        vm.prank(alice);
        nft.transferFrom(alice, bob, tokenId);
    }

    function test_Approve() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.approve(bob, tokenId);

        assertEq(nft.getApproved(tokenId), bob);
    }

    function test_ApproveEmitsEvent() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.expectEmit(true, true, true, false);
        emit IERC721.Approval(alice, bob, tokenId);

        vm.prank(alice);
        nft.approve(bob, tokenId);
    }

    function test_TransferFromWithApproval() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.approve(bob, tokenId);

        vm.prank(bob);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
        // Approval should be cleared
        assertEq(nft.getApproved(tokenId), address(0));
    }

    function test_SetApprovalForAll() public {
        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        assertTrue(nft.isApprovedForAll(alice, bob));
    }

    function test_TransferFromWithOperator() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.setApprovalForAll(bob, true);

        vm.prank(bob);
        nft.transferFrom(alice, bob, tokenId);

        assertEq(nft.ownerOf(tokenId), bob);
    }

    function test_SafeTransferFrom() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.safeTransferFrom(alice, address(receiver), tokenId);

        assertEq(nft.ownerOf(tokenId), address(receiver));
    }

    function test_RevertSafeTransferToNonReceiver() public {
        uint256 tokenId = nft.mint(alice, "");
        receiver.setReject(true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            ERC721.TransferToNonReceiver.selector,
            address(receiver)
        ));
        nft.safeTransferFrom(alice, address(receiver), tokenId);
    }

    function test_RevertTransferNotOwnerOrApproved() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(
            ERC721.NotOwnerOrApproved.selector,
            bob,
            tokenId
        ));
        nft.transferFrom(alice, bob, tokenId);
    }

    function test_RevertTransferToZeroAddress() public {
        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        nft.transferFrom(alice, address(0), tokenId);
    }

    function test_RevertNonExistentToken() public {
        vm.expectRevert(abi.encodeWithSelector(
            ERC721.NonExistentToken.selector,
            999
        ));
        nft.ownerOf(999);
    }

    function test_SupportsInterface() public view {
        // ERC-165
        assertTrue(nft.supportsInterface(0x01ffc9a7));
        // ERC-721
        assertTrue(nft.supportsInterface(0x80ac58cd));
        // ERC-721 Metadata
        assertTrue(nft.supportsInterface(0x5b5e139f));
        // Random interface
        assertFalse(nft.supportsInterface(0x12345678));
    }

    function testFuzz_MintAndTransfer(address to) public {
        vm.assume(to != address(0) && to.code.length == 0);

        uint256 tokenId = nft.mint(alice, "");

        vm.prank(alice);
        nft.transferFrom(alice, to, tokenId);

        assertEq(nft.ownerOf(tokenId), to);
    }
}

contract ERC721EnumerableTest is Test {
    ERC721Enumerable public nft;
    address public alice;
    address public bob;

    function setUp() public {
        nft = new ERC721Enumerable("Enumerable NFT", "ENFT");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
    }

    function test_TotalSupply() public {
        // Mint through internal function would require a derived contract
        // This tests the enumerable infrastructure
        assertEq(nft.totalSupply(), 0);
    }
}
