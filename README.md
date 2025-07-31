# Solidity Contract Development Guide

## General Structure to Follow for Contract Development

### Layout of Contract:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 1. version
// 2. imports
// 3. errors
// 4. interfaces, libraries, contracts
// 5. Type declarations
// 6. State variables
// 7. Events
// 8. Modifiers
// 9. Functions
```

### Layout of Functions:
```solidity
// 1. constructor
// 2. receive function (if exists)
// 3. fallback function (if exists)
// 4. external
// 5. public
// 6. internal
// 7. private
// 8. view & pure functions
```

### Quick Tips
- **NatSpec Documentation**: Use `Cmd + Shift + D` for NatSpec generation

---

## 📝 Raffle / Lottery Contract Notes

### (1) Legacy require vs Custom Error
- **Legacy code** uses `require` statements to create errors
- **Best optimization** to save gas is using custom errors:

```solidity
// Instead of: require(condition, "Error message");
// Use:
revert Raffle__ErrorName();
```

### (2) State Variable Reads are Costly
- Reading from state variables on-chain is **costly**
- Modern dApps use **logs** to listen for changes
- Logs can be emitted and used with oracles (e.g., Chainlink)

```solidity
event RaffleEntered(address indexed player, uint256 amount);

emit RaffleEntered(msg.sender, msg.value);
```

**Important Notes:**
- `indexed` logs are easily searchable
- For other logs, you need the ABI

### (3) Enums for State Management
Enums help maintain different states of the system:

```solidity
enum RaffleState {
    OPEN,
    CALCULATING
}
```

**Declaration:**
```solidity
RaffleState private s_raffleState;
```

**Usage:**
```solidity
s_raffleState = RaffleState.OPEN;

// Or access with:
RaffleState[0] // or [1] - More readable
```

### (4) Constructor in Inherited Contracts
If you're inheriting a contract with constructor declarations, you must pass the constructor arguments in your present contract's constructor.

**Example:**
```solidity
// A - contract 1
// B - contract 2
constructor(address winner) B(winner) {
    // other declarations
}
```

### (5) CEI Methodology
**CEI** stands for **Checks, Effects, Interactions**:

- ✅ **Checks**: Errors, validations, etc.
- ⚙️ **Effects**: Internal contract state changes
- 🌐 **Interactions**: External contract calls (events, errors, etc.)

### (6) Custom Errors
**Syntax:**
```solidity
error Raffle__ErrorName(address player, uint256 amount);
```

### (7) Foundry Testing Functions (Cheat Codes)
Essential Foundry VM cheat codes for testing:

**Time Manipulation:**
```solidity
vm.warp(1641070800); // Set block.timestamp to specific time
vm.roll(100); // Set block.number to 100
```

**Address Manipulation:**
```solidity
vm.prank(address); // Sets msg.sender for next call only
vm.startPrank(address); // Sets msg.sender for all subsequent calls
vm.stopPrank(); // Stops the prank

vm.deal(address, amount); // Set ETH balance for address
```

**Expectation Testing:**
```solidity
vm.expectRevert(); // Expect next call to revert
vm.expectRevert("Error message"); // Expect specific revert message
vm.expectRevert(CustomError.selector); // Expect custom error

vm.expectEmit(true, true, false, true); // Expect event emission
// Parameters: (checkTopic1, checkTopic2, checkTopic3, checkData)
```

**State Snapshots:**
```solidity
uint256 snapshot = vm.snapshot(); // Take state snapshot
vm.revertTo(snapshot); // Revert to snapshot
```

**Mock Calls:**
```solidity
vm.mockCall(target, abi.encodeWithSelector(selector), returnData);
vm.clearMockedCalls(); // Clear all mocked calls
```

### (8) Understanding vm.expectEmit() in Detail

The `vm.expectEmit()` function is crucial for testing event emissions in Foundry. Here's how it works:

**Basic Syntax:**
```solidity
vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
// Then call the function that should emit the event
// Then emit the expected event yourself
```

**Parameters Explained:**
- `checkTopic1` (bool): Check the first indexed parameter
- `checkTopic2` (bool): Check the second indexed parameter  
- `checkTopic3` (bool): Check the third indexed parameter
- `checkData` (bool): Check the non-indexed data

**Example Usage:**
```solidity
// Event definition
event RaffleEntered(address indexed player, uint256 indexed amount, string message);

// Test function
function testRaffleEntered() public {
    address player = address(0x123);
    uint256 amount = 1 ether;
    
    // Tell Foundry what to expect
    vm.expectEmit(true, true, false, true);
    // Emit the expected event (what we expect to see)
    emit RaffleEntered(player, amount, "Player entered raffle");
    
    // Call the function that should emit the event
    vm.prank(player);
    raffle.enterRaffle{value: amount}("Player entered raffle");
}
```

**Common Patterns:**
```solidity
// Check all indexed parameters and data
vm.expectEmit(true, true, true, true);

// Check only the event was emitted (ignore all parameters)
vm.expectEmit(false, false, false, false);

// Check only first indexed parameter and data
vm.expectEmit(true, false, false, true);
```

**Important Notes:**
- You must emit the expected event **after** calling `vm.expectEmit()`
- The expected event must match exactly what you're checking for
- Maximum of 3 indexed parameters can be checked (Solidity limitation)
- Always call `vm.expectEmit()` immediately before the function that emits

---

## Best Practices Summary

1. **Use custom errors** instead of `require` statements for gas optimization
2. **Emit events** for off-chain monitoring and oracle integration
3. **Use enums** for clear state management
4. **Follow CEI pattern** for secure contract interactions
5. **Structure contracts** consistently for readability and maintainability
6. **Index important event parameters** for efficient searching
