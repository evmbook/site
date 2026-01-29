// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC721
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/// @title IERC20
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title SimpleNFTMarketplace
/// @notice Basic NFT marketplace with listings and offers
/// @dev Educational implementation - demonstrates core marketplace mechanics
contract SimpleNFTMarketplace {
    /// @notice Listing data
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        address paymentToken;   // address(0) for ETH
        uint256 price;
        uint256 expiration;
        bool active;
    }

    /// @notice Offer data
    struct Offer {
        address buyer;
        address nftContract;
        uint256 tokenId;
        address paymentToken;
        uint256 amount;
        uint256 expiration;
        bool active;
    }

    /// @notice Platform fee in basis points (e.g., 250 = 2.5%)
    uint256 public platformFee;
    address public feeRecipient;
    address public owner;

    /// @notice Listings by ID
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId;

    /// @notice Offers by ID
    mapping(uint256 => Offer) public offers;
    uint256 public nextOfferId;

    /// @notice Track listings by NFT
    mapping(address => mapping(uint256 => uint256)) public activeListingId;

    /// @notice Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 expiration
    );
    event ListingCanceled(uint256 indexed listingId);
    event ListingSold(
        uint256 indexed listingId,
        address indexed buyer,
        uint256 price
    );
    event OfferCreated(
        uint256 indexed offerId,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 amount,
        uint256 expiration
    );
    event OfferCanceled(uint256 indexed offerId);
    event OfferAccepted(uint256 indexed offerId, address indexed seller);

    /// @notice Errors
    error NotOwner();
    error NotSeller();
    error NotBuyer();
    error ListingNotActive();
    error OfferNotActive();
    error ListingExpired();
    error OfferExpired();
    error InsufficientPayment();
    error TransferFailed();
    error NotApproved();
    error InvalidPrice();
    error InvalidExpiration();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(uint256 _platformFee, address _feeRecipient) {
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        owner = msg.sender;
    }

    /// @notice Create a new listing
    function createListing(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 duration
    ) external returns (uint256 listingId) {
        if (price == 0) revert InvalidPrice();
        if (duration == 0) revert InvalidExpiration();

        IERC721 nft = IERC721(nftContract);
        if (nft.ownerOf(tokenId) != msg.sender) revert NotOwner();

        // Check approval
        if (nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))) {
            revert NotApproved();
        }

        listingId = nextListingId++;

        listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            paymentToken: paymentToken,
            price: price,
            expiration: block.timestamp + duration,
            active: true
        });

        activeListingId[nftContract][tokenId] = listingId;

        emit ListingCreated(
            listingId,
            msg.sender,
            nftContract,
            tokenId,
            paymentToken,
            price,
            block.timestamp + duration
        );
    }

    /// @notice Cancel a listing
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        if (listing.seller != msg.sender) revert NotSeller();
        if (!listing.active) revert ListingNotActive();

        listing.active = false;
        delete activeListingId[listing.nftContract][listing.tokenId];

        emit ListingCanceled(listingId);
    }

    /// @notice Buy a listed NFT
    function buyListing(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];

        if (!listing.active) revert ListingNotActive();
        if (block.timestamp > listing.expiration) revert ListingExpired();

        listing.active = false;
        delete activeListingId[listing.nftContract][listing.tokenId];

        uint256 fee = (listing.price * platformFee) / 10000;
        uint256 sellerProceeds = listing.price - fee;

        if (listing.paymentToken == address(0)) {
            // ETH payment
            if (msg.value < listing.price) revert InsufficientPayment();

            // Pay seller
            (bool success,) = listing.seller.call{value: sellerProceeds}("");
            if (!success) revert TransferFailed();

            // Pay fee
            if (fee > 0) {
                (success,) = feeRecipient.call{value: fee}("");
                if (!success) revert TransferFailed();
            }

            // Refund excess
            if (msg.value > listing.price) {
                (success,) = msg.sender.call{value: msg.value - listing.price}("");
                if (!success) revert TransferFailed();
            }
        } else {
            // ERC-20 payment
            IERC20 token = IERC20(listing.paymentToken);
            if (!token.transferFrom(msg.sender, listing.seller, sellerProceeds)) {
                revert TransferFailed();
            }
            if (fee > 0 && !token.transferFrom(msg.sender, feeRecipient, fee)) {
                revert TransferFailed();
            }
        }

        // Transfer NFT
        IERC721(listing.nftContract).transferFrom(listing.seller, msg.sender, listing.tokenId);

        emit ListingSold(listingId, msg.sender, listing.price);
    }

    /// @notice Create an offer on an NFT
    function createOffer(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 amount,
        uint256 duration
    ) external payable returns (uint256 offerId) {
        if (amount == 0) revert InvalidPrice();
        if (duration == 0) revert InvalidExpiration();

        if (paymentToken == address(0)) {
            if (msg.value < amount) revert InsufficientPayment();
        }

        offerId = nextOfferId++;

        offers[offerId] = Offer({
            buyer: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            paymentToken: paymentToken,
            amount: amount,
            expiration: block.timestamp + duration,
            active: true
        });

        emit OfferCreated(
            offerId,
            msg.sender,
            nftContract,
            tokenId,
            paymentToken,
            amount,
            block.timestamp + duration
        );
    }

    /// @notice Cancel an offer
    function cancelOffer(uint256 offerId) external {
        Offer storage offer = offers[offerId];
        if (offer.buyer != msg.sender) revert NotBuyer();
        if (!offer.active) revert OfferNotActive();

        offer.active = false;

        // Refund ETH if applicable
        if (offer.paymentToken == address(0)) {
            (bool success,) = msg.sender.call{value: offer.amount}("");
            if (!success) revert TransferFailed();
        }

        emit OfferCanceled(offerId);
    }

    /// @notice Accept an offer (as NFT owner)
    function acceptOffer(uint256 offerId) external {
        Offer storage offer = offers[offerId];

        if (!offer.active) revert OfferNotActive();
        if (block.timestamp > offer.expiration) revert OfferExpired();

        IERC721 nft = IERC721(offer.nftContract);
        if (nft.ownerOf(offer.tokenId) != msg.sender) revert NotOwner();

        offer.active = false;

        // Cancel any active listing for this NFT
        uint256 listingId = activeListingId[offer.nftContract][offer.tokenId];
        if (listings[listingId].active) {
            listings[listingId].active = false;
            delete activeListingId[offer.nftContract][offer.tokenId];
        }

        uint256 fee = (offer.amount * platformFee) / 10000;
        uint256 sellerProceeds = offer.amount - fee;

        if (offer.paymentToken == address(0)) {
            // ETH payment (already held in contract)
            (bool success,) = msg.sender.call{value: sellerProceeds}("");
            if (!success) revert TransferFailed();

            if (fee > 0) {
                (success,) = feeRecipient.call{value: fee}("");
                if (!success) revert TransferFailed();
            }
        } else {
            // ERC-20 payment
            IERC20 token = IERC20(offer.paymentToken);
            if (!token.transferFrom(offer.buyer, msg.sender, sellerProceeds)) {
                revert TransferFailed();
            }
            if (fee > 0 && !token.transferFrom(offer.buyer, feeRecipient, fee)) {
                revert TransferFailed();
            }
        }

        // Transfer NFT
        nft.transferFrom(msg.sender, offer.buyer, offer.tokenId);

        emit OfferAccepted(offerId, msg.sender);
    }

    /// @notice Update platform fee (owner only)
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 1000, "Fee too high"); // Max 10%
        platformFee = _platformFee;
    }

    /// @notice Update fee recipient (owner only)
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    /// @notice Check if listing is valid
    function isListingValid(uint256 listingId) external view returns (bool) {
        Listing storage listing = listings[listingId];
        if (!listing.active) return false;
        if (block.timestamp > listing.expiration) return false;

        IERC721 nft = IERC721(listing.nftContract);
        if (nft.ownerOf(listing.tokenId) != listing.seller) return false;
        if (nft.getApproved(listing.tokenId) != address(this) &&
            !nft.isApprovedForAll(listing.seller, address(this))) return false;

        return true;
    }

    /// @notice Get listing details
    function getListing(uint256 listingId) external view returns (
        address seller,
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 expiration,
        bool active
    ) {
        Listing storage l = listings[listingId];
        return (l.seller, l.nftContract, l.tokenId, l.paymentToken, l.price, l.expiration, l.active);
    }

    /// @notice Get offer details
    function getOffer(uint256 offerId) external view returns (
        address buyer,
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 amount,
        uint256 expiration,
        bool active
    ) {
        Offer storage o = offers[offerId];
        return (o.buyer, o.nftContract, o.tokenId, o.paymentToken, o.amount, o.expiration, o.active);
    }

    /// @notice Receive ETH for offers
    receive() external payable {}
}

/// @title EnglishAuction
/// @notice Simple English auction for NFTs
contract EnglishAuction {
    struct Auction {
        address seller;
        address nftContract;
        uint256 tokenId;
        address paymentToken;
        uint256 startingBid;
        uint256 reservePrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool settled;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;

    uint256 public minBidIncrement = 500; // 5% minimum increase

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionSettled(uint256 indexed auctionId, address indexed winner, uint256 amount);

    error AuctionEnded();
    error AuctionNotEnded();
    error BidTooLow();
    error NotSeller();
    error AlreadySettled();

    function createAuction(
        address nftContract,
        uint256 tokenId,
        address paymentToken,
        uint256 startingBid,
        uint256 reservePrice,
        uint256 duration
    ) external returns (uint256 auctionId) {
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        auctionId = nextAuctionId++;

        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            paymentToken: paymentToken,
            startingBid: startingBid,
            reservePrice: reservePrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            settled: false
        });

        emit AuctionCreated(auctionId, msg.sender, block.timestamp + duration);
    }

    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp >= auction.endTime) revert AuctionEnded();

        uint256 minBid = auction.highestBid == 0
            ? auction.startingBid
            : auction.highestBid + (auction.highestBid * minBidIncrement) / 10000;

        if (msg.value < minBid) revert BidTooLow();

        // Refund previous bidder
        if (auction.highestBidder != address(0)) {
            (bool success,) = auction.highestBidder.call{value: auction.highestBid}("");
            require(success, "Refund failed");
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        // Extend auction if bid in last 10 minutes
        if (auction.endTime - block.timestamp < 10 minutes) {
            auction.endTime = block.timestamp + 10 minutes;
        }

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function settle(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];

        if (block.timestamp < auction.endTime) revert AuctionNotEnded();
        if (auction.settled) revert AlreadySettled();

        auction.settled = true;

        if (auction.highestBid >= auction.reservePrice && auction.highestBidder != address(0)) {
            // Transfer NFT to winner
            IERC721(auction.nftContract).transferFrom(address(this), auction.highestBidder, auction.tokenId);

            // Pay seller
            (bool success,) = auction.seller.call{value: auction.highestBid}("");
            require(success, "Payment failed");

            emit AuctionSettled(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            // Return NFT to seller
            IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);

            // Refund highest bidder if any
            if (auction.highestBidder != address(0)) {
                (bool success,) = auction.highestBidder.call{value: auction.highestBid}("");
                require(success, "Refund failed");
            }

            emit AuctionSettled(auctionId, address(0), 0);
        }
    }
}
