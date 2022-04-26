// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Timelock{
    address public owner; 
    mapping(bytes32 => bool) public queue_status;
    uint public constant min_time = 1;
    uint public constant max_time = 10000;
    bytes32[] public ids;
    event Queue(bytes32 indexed txId, address indexed target, uint value, string  func, bytes  data, uint timestamp);
    event Execute(bytes32 indexed txId, address indexed target, uint value, string  func, bytes  data, uint timestamp);
    event Cancel(bytes32 indexed txId);
    modifier restrictAccess(){
     require(owner == msg.sender);
  _;
}

 receive () external payable{}
 constructor(){
     owner = msg.sender;
 }
 function queue_txn(address _target, uint _value, string calldata func, bytes calldata _data, uint _timestamp) external restrictAccess{
  bytes32 txId = keccak256(abi.encode(_target, func, _data, _timestamp));
    require (!queue_status[txId], "Already queued");
    queue_status[txId] = true;
    require (block.timestamp > block.timestamp + min_time || block.timestamp < block.timestamp + max_time, "not within timer" );
    ids.push(txId);
    emit Queue (txId, _target,  _value,  func,   _data,  _timestamp);

}
function execute_txn(address _target, uint _value, string calldata func, bytes calldata _data, uint _timestamp) external payable restrictAccess returns (bytes memory){
    require(block.timestamp > block.timestamp + min_time || block.timestamp < block.timestamp + max_time);
    bytes32 txId = keccak256(abi.encode(_target, func, _data, _timestamp));
    require(queue_status[txId]);
    queue_status[txId] = false;
     bytes memory data;
        if (bytes(func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(bytes4(keccak256(bytes(func))), _data);
        } else {
            // call fallback with data
            data = _data;
        }

        // call target
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
       require (ok);

        emit Execute(txId, _target, _value, func, _data, _timestamp);

        return res;
}
function cancel_txn(bytes32 _txId) external restrictAccess{
    require(queue_status[_txId]);
    queue_status[_txId] = false;

        emit Cancel(_txId);
}
function getTimestamp() public view returns(uint){
    return block.timestamp;
}

}
contract liquidity{
    address public owner;
    uint public minAmt;
    event CreateLiquidityPool(address indexed owner, uint minAmt);
constructor (address _owner){
    owner = _owner;
}
modifier restrictAccess(){
     require(owner == msg.sender);
  _;
}
function createLiquidityPool(address _owner, uint  _minAmt)  external restrictAccess {
    owner = _owner;
    minAmt = _minAmt;
    emit CreateLiquidityPool(owner, minAmt);
}
function contribute() external payable {
  require (msg.value > minAmt, "set the minAmount");

}
}