// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC165
/// @notice Standard interface detection
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @title IERC721
/// @notice Standard ERC-721 interface
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/// @title IERC721Metadata
/// @notice Optional metadata extension
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title IERC721Receiver
/// @notice Interface for contracts that can receive ERC-721 tokens
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @title ERC721
/// @notice Gas-optimized ERC-721 implementation
contract ERC721 is IERC721, IERC721Metadata {
    /// @notice Token name
    string private _name;

    /// @notice Token symbol
    string private _symbol;

    /// @notice Token ID to owner
    mapping(uint256 => address) private _owners;

    /// @notice Owner to token count
    mapping(address => uint256) private _balances;

    /// @notice Token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    /// @notice Owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /// @notice Errors
    error NonExistentToken(uint256 tokenId);
    error NotOwnerOrApproved(address caller, uint256 tokenId);
    error TransferToZeroAddress();
    error MintToZeroAddress();
    error TokenAlreadyMinted(uint256 tokenId);
    error TransferToNonReceiver(address to);
    error ApproveToCurrentOwner();
    error InvalidOwner();

    /// @notice ERC721Receiver magic value
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IERC721Metadata
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert NonExistentToken(tokenId);
        return "";
    }

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert InvalidOwner();
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert NonExistentToken(tokenId);
        return owner;
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApproveToCurrentOwner();

        if (msg.sender != owner && !_operatorApprovals[owner][msg.sender]) {
            revert NotOwnerOrApproved(msg.sender, tokenId);
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (_owners[tokenId] == address(0)) revert NonExistentToken(tokenId);
        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved(msg.sender, tokenId);
        }
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        transferFrom(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Check if address is owner or approved
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @notice Internal transfer logic
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        if (ownerOf(tokenId) != from) revert NotOwnerOrApproved(from, tokenId);
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @notice Internal mint logic
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (_owners[tokenId] != address(0)) revert TokenAlreadyMinted(tokenId);

        unchecked {
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Internal safe mint with receiver check
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Internal burn logic
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[owner] -= 1;
        }

        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /// @notice Check if receiver can accept ERC-721
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length == 0) {
            return true;
        }

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
            return retval == _ERC721_RECEIVED;
        } catch {
            return false;
        }
    }

    /// @notice Check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
}

/// @title ERC721Enumerable
/// @notice ERC-721 with enumeration extension
contract ERC721Enumerable is ERC721 {
    /// @notice All token IDs
    uint256[] private _allTokens;

    /// @notice Token ID to index in _allTokens
    mapping(uint256 => uint256) private _allTokensIndex;

    /// @notice Owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    /// @notice Token ID to index in owner's list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @notice Get total supply
    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    /// @notice Get token by global index
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _allTokens.length, "Index out of bounds");
        return _allTokens[index];
    }

    /// @notice Get token of owner by index
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < _ownedTokens[owner].length, "Index out of bounds");
        return _ownedTokens[owner][index];
    }

    /// @notice Override transfer to update enumeration
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        super._transfer(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /// @notice Override mint to update enumeration
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /// @notice Override burn to update enumeration
    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);

        super._burn(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _allTokens[lastTokenIndex];
            _allTokens[tokenIndex] = lastTokenId;
            _allTokensIndex[lastTokenId] = tokenIndex;
        }

        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }
}

/// @title ERC721URIStorage
/// @notice ERC-721 with per-token URI storage
contract ERC721URIStorage is ERC721 {
    /// @notice Token ID to URI
    mapping(uint256 => string) private _tokenURIs;

    /// @notice Base URI for all tokens
    string private _baseURI;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    /// @notice Set base URI
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI = baseURI_;
    }

    /// @notice Get base URI
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /// @notice Override tokenURI to use storage or base
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken(tokenId);

        string memory _uri = _tokenURIs[tokenId];
        if (bytes(_uri).length > 0) {
            return _uri;
        }

        if (bytes(_baseURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _toString(tokenId)));
        }

        return "";
    }

    /// @notice Set token URI
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        if (!_exists(tokenId)) revert NonExistentToken(tokenId);
        _tokenURIs[tokenId] = uri;
    }

    /// @notice Override burn to clean up URI
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete _tokenURIs[tokenId];
    }

    /// @notice Convert uint to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

/// @title SimpleNFT
/// @notice Simple NFT collection with minting
contract SimpleNFT is ERC721URIStorage {
    uint256 private _nextTokenId;
    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(string memory name_, string memory symbol_) ERC721URIStorage(name_, symbol_) {
        owner = msg.sender;
    }

    /// @notice Mint a new NFT
    function mint(address to, string memory uri) external onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId, "");
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    /// @notice Set base URI for all tokens
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Get total minted
    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }
}
