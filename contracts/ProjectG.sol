// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ProjectG is ERC721, ERC721Burnable, AccessControl {
    // Roles
    bytes32 public constant CUSTOMER = keccak256("CUSTOMER");
    bytes32 public constant SUPPLIER = keccak256("SUPPLIER");
    bytes32 public constant SHIPMENT_PROVIDER = keccak256("SHIPMENT_PROVIDER");

    // Order Status
    string public constant ORDER_CREATED = "ORDER_CREATED";
    string public constant ORDER_ACCEPTED = "ORDER_ACCEPTED";
    string public constant ORDER_SHIPPED = "ORDER_SHIPPED";
    string public constant ORDER_CANCELLED = "ORDER_CANCELLED";
    string public constant ORDER_REJECTED = "ORDER_REJECTED";
    string public constant ORDER_DELIVERED = "ORDER_DELIVERED";


    mapping(string => address) private orders;
    mapping(string => uint256) private orderAmounts;

    event AddUser(bytes32 role, address account);

    event OrderCreated(address indexed to, uint256 amount, string orderId);
    event OrderCancelled(
        string orderId,
        uint256 amount,
        address indexed customer
    );
    event OrderUpdated(string orderId, string status);
    event OrderStatusMessage(string orderId, string statusMessage);

    constructor() ERC721("ProjectG", "G") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addUser(
        bytes32 role,
        address account
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
        emit AddUser(role, account);
    }

    function createOrder(
        address to,
        uint256 amount,
        string memory orderId
    ) public payable onlyRole(CUSTOMER) {
        require(
            orders[orderId] == address(0),
            "ProjectG: order already exists"
        );
        require(msg.value == amount, "ProjectG: incorrect amount");
        orders[orderId] = to;
        _safeMint(to, uint256(keccak256(abi.encodePacked(orderId))));
        orderAmounts[orderId] = amount;
        emit OrderCreated(to, amount, orderId);
    }

    function cancelOrder(string memory orderId) public onlyRole(CUSTOMER) {
        require(
            orders[orderId] != address(0),
            "ProjectG: order does not exist"
        );
        uint256 amount = orderAmounts[orderId];
        address payable customer = payable(msg.sender);
        _burn(uint256(keccak256(abi.encodePacked(orderId))));
        delete orders[orderId];
        delete orderAmounts[orderId];
        customer.transfer(amount);
    }

    function rejectOrder(string memory orderId) public onlyRole(SUPPLIER) {
        require(
            orders[orderId] != address(0),
            "ProjectG: order does not exist"
        );
        _burn(uint256(keccak256(abi.encodePacked(orderId))));
        delete orders[orderId];
        delete orderAmounts[orderId];
        emit OrderCancelled(orderId, orderAmounts[orderId], msg.sender);
    }

    function updateOrderStatus(string memory orderId, string memory status) public onlyRole(SUPPLIER) {
        require(
            orders[orderId] != address(0),
            "ProjectG: order does not exist"
        );
        require(
            keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(ORDER_ACCEPTED)) ||
            keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(ORDER_REJECTED)) ||
            keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(ORDER_SHIPPED)) ||
            keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(ORDER_DELIVERED)),
            "ProjectG: invalid status"
        );
        emit OrderUpdated(orderId, status);
    }

    function updateOrderStatusMessage(string memory orderId, string memory statusMessage) public onlyRole(SHIPMENT_PROVIDER) {
        require(
            orders[orderId] != address(0),
            "ProjectG: order does not exist"
        );
        emit OrderStatusMessage(orderId, statusMessage);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
