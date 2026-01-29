// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title IERC1155
/// @notice Standard ERC-1155 interface
interface IERC1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/// @title IERC1155Receiver
/// @notice Interface for contracts that can receive ERC-1155 tokens
interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/// @title IERC1155MetadataURI
/// @notice Metadata extension for ERC-1155
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

/// @title ERC1155
/// @notice Gas-optimized ERC-1155 multi-token implementation
contract ERC1155 is IERC1155, IERC1155MetadataURI {
    /// @notice Token balances: id => account => balance
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /// @notice Operator approvals: account => operator => approved
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /// @notice Base URI for metadata
    string private _uri;

    /// @notice Errors
    error TransferToZeroAddress();
    error InsufficientBalance(address account, uint256 id, uint256 balance, uint256 needed);
    error NotApproved(address caller);
    error LengthMismatch();
    error TransferToNonReceiver(address to);
    error MintToZeroAddress();

    /// @notice Magic values for receiver callbacks
    bytes4 private constant _ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    constructor(string memory uri_) {
        _uri = uri_;
    }

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /// @inheritdoc IERC1155
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        return _balances[id][account];
    }

    /// @inheritdoc IERC1155
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert LengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }
        return batchBalances;
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /// @inheritdoc IERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotApproved(msg.sender);
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /// @inheritdoc IERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotApproved(msg.sender);
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @notice Internal single transfer
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, id, fromBalance, amount);
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (!_checkOnERC1155Received(from, to, id, amount, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Internal batch transfer
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (ids.length != amounts.length) revert LengthMismatch();
        if (to == address(0)) revert TransferToZeroAddress();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) {
                revert InsufficientBalance(from, id, fromBalance, amount);
            }

            unchecked {
                _balances[id][from] = fromBalance - amount;
                _balances[id][to] += amount;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (!_checkOnERC1155BatchReceived(from, to, ids, amounts, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Internal mint
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) revert MintToZeroAddress();

        unchecked {
            _balances[id][to] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (!_checkOnERC1155Received(address(0), to, id, amount, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Internal batch mint
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to == address(0)) revert MintToZeroAddress();
        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < ids.length; i++) {
            unchecked {
                _balances[ids[i]][to] += amounts[i];
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        if (!_checkOnERC1155BatchReceived(address(0), to, ids, amounts, data)) {
            revert TransferToNonReceiver(to);
        }
    }

    /// @notice Internal burn
    function _burn(address from, uint256 id, uint256 amount) internal {
        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert InsufficientBalance(from, id, fromBalance, amount);
        }

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /// @notice Internal batch burn
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal {
        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) {
                revert InsufficientBalance(from, id, fromBalance, amount);
            }

            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    /// @notice Set base URI
    function _setURI(string memory newuri) internal {
        _uri = newuri;
    }

    /// @notice Check receiver callback for single transfer
    function _checkOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length == 0) return true;

        try IERC1155Receiver(to).onERC1155Received(msg.sender, from, id, amount, data) returns (bytes4 response) {
            return response == _ERC1155_RECEIVED;
        } catch {
            return false;
        }
    }

    /// @notice Check receiver callback for batch transfer
    function _checkOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length == 0) return true;

        try IERC1155Receiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) returns (
            bytes4 response
        ) {
            return response == _ERC1155_BATCH_RECEIVED;
        } catch {
            return false;
        }
    }

    /// @notice ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC165
    }
}

/// @title GameItems
/// @notice Example ERC-1155 for game items with fungible and non-fungible tokens
contract GameItems is ERC1155 {
    // Token type IDs
    uint256 public constant GOLD = 0;       // Fungible currency
    uint256 public constant SILVER = 1;     // Fungible currency
    uint256 public constant SWORD = 2;      // Semi-fungible equipment
    uint256 public constant SHIELD = 3;     // Semi-fungible equipment
    // IDs 1000+ are unique NFTs

    address public owner;
    uint256 private _nextUniqueId = 1000;

    /// @notice Token supplies
    mapping(uint256 => uint256) public totalSupply;

    /// @notice Max supplies (0 = unlimited)
    mapping(uint256 => uint256) public maxSupply;

    error NotOwner();
    error MaxSupplyReached(uint256 id);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
        owner = msg.sender;

        // Set max supplies for equipment
        maxSupply[SWORD] = 10000;
        maxSupply[SHIELD] = 10000;
    }

    /// @notice Mint fungible tokens (GOLD, SILVER)
    function mintFungible(address to, uint256 id, uint256 amount) external onlyOwner {
        require(id < 2, "Invalid fungible ID");
        _mint(to, id, amount, "");
        totalSupply[id] += amount;
    }

    /// @notice Mint equipment (capped supply)
    function mintEquipment(address to, uint256 id, uint256 amount) external onlyOwner {
        require(id >= 2 && id < 1000, "Invalid equipment ID");

        if (maxSupply[id] > 0 && totalSupply[id] + amount > maxSupply[id]) {
            revert MaxSupplyReached(id);
        }

        _mint(to, id, amount, "");
        totalSupply[id] += amount;
    }

    /// @notice Mint unique NFT
    function mintUnique(address to) external onlyOwner returns (uint256) {
        uint256 id = _nextUniqueId++;
        _mint(to, id, 1, "");
        totalSupply[id] = 1;
        maxSupply[id] = 1; // Unique items have max supply of 1
        return id;
    }

    /// @notice Batch mint multiple items
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            totalSupply[ids[i]] += amounts[i];
        }
    }

    /// @notice Burn tokens
    function burn(address from, uint256 id, uint256 amount) external {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotApproved(msg.sender);
        }
        _burn(from, id, amount);
        totalSupply[id] -= amount;
    }

    /// @notice Check if token ID is fungible
    function isFungible(uint256 id) external pure returns (bool) {
        return id < 2;
    }

    /// @notice Check if token ID is equipment
    function isEquipment(uint256 id) external pure returns (bool) {
        return id >= 2 && id < 1000;
    }

    /// @notice Check if token ID is unique NFT
    function isUnique(uint256 id) external pure returns (bool) {
        return id >= 1000;
    }

    /// @notice Override URI for per-token metadata
    function uri(uint256 id) external view override returns (string memory) {
        // Could implement custom logic per token type
        return super.uri(id);
    }
}

/// @title ERC1155Supply
/// @notice ERC-1155 with supply tracking
contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    constructor(string memory uri_) ERC1155(uri_) {}

    /// @notice Get total supply of a token
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    /// @notice Check if token exists (has been minted)
    function exists(uint256 id) public view returns (bool) {
        return _totalSupply[id] > 0;
    }

    /// @notice Override mint to track supply
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
        super._mint(to, id, amount, data);
        _totalSupply[id] += amount;
    }

    /// @notice Override batch mint to track supply
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /// @notice Override burn to track supply
    function _burn(address from, uint256 id, uint256 amount) internal override {
        super._burn(from, id, amount);
        _totalSupply[id] -= amount;
    }

    /// @notice Override batch burn to track supply
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal override {
        super._burnBatch(from, ids, amounts);
        for (uint256 i = 0; i < ids.length; i++) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}
