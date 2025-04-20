// SPDX-License-Identifier: MIT
// This line specifies the license for this code - MIT is an open-source license

pragma solidity ^0.8.0;

/**
 * these type of comments are called NatSpec comments
 * NatSpec comments are used to provide detailed documentation for smart contracts
 */

/**
 * @title ExpenseTracker
 * @dev A decentralized application (DApp) for college students to track and split expenses
 * All data is stored on-chain, making it transparent and immutable
 */

// This contract allows users to register, add expenses, and settle debts
contract ExpenseTracker {
    /**
     * @dev Person struct represents a user in the system
     * @param name The user's name
     * @param walletAddress The Ethereum address of the user's wallet
     */
    struct Person {
        string name;
        address walletAddress;
    }

    /**
     * @dev Expense struct represents a shared expense
     * @param id Unique identifier for the expense
     * @param label Description of what the expense was for
     * @param timestamp When the expense was recorded (in Unix time)
     * @param amountPaid Mapping of addresses to amounts each person paid
     * @param amountOwed Mapping of addresses to amounts each person owes
     * @param participants Array of addresses of people involved in this expense
     */
    struct Expense {
        uint256 id;
        string label;
        uint256 timestamp;
        mapping(address => uint256) amountPaid; // What each person actually paid
        mapping(address => uint256) amountOwed; // What each person should have paid (their fair share)
        address[] participants; // List of people involved in this expense
    }

    // Storage for all expenses, mapped by their unique ID
    mapping(uint256 => Expense) private expenses;

    // Storage for all registered people, mapped by their wallet address
    mapping(address => Person) private people;

    // Array to keep track of all registered wallet addresses
    address[] private registeredPeople;

    // Counter for expense IDs, also gives us the total number of expenses
    uint256 public expenseCount;

    // Events - these help front-end applications react to changes in the contract
    // Emitted when a new person registers
    event PersonRegistered(address indexed walletAddress, string name);

    // Emitted when a new expense is added
    event ExpenseAdded(uint256 indexed expenseId, string label);

    // Emitted when someone settles a debt
    event DebtSettled(address indexed from, address indexed to, uint256 amount);
    event NameUpdated(address indexed user, string newName);
    /**
     * @dev Register a new person in the expense tracker
     * @param _name The name of the person
     */
    function registerPerson(string memory _name) public {
        // Validate that the name isn't empty
        require(bytes(_name).length > 0, "Name cannot be empty");

        // Check if this address has already been registered
        require(
            people[msg.sender].walletAddress == address(0),
            "Person already registered"
        );

        // Create and store the new person
        people[msg.sender] = Person(_name, msg.sender);

        // Add to the list of registered people
        registeredPeople.push(msg.sender);

        // Emit event for front-end apps
        emit PersonRegistered(msg.sender, _name);
    }

    /**
     * @dev Add a new shared expense to the tracker
     * @param _label Description of the expense
     * @param _participants Array of addresses of people involved in this expense
     * @param _amountsPaid Array of amounts each participant paid
     * @param _amountsOwed Array of amounts each participant owes (their fair share)
     */
    function addExpense(
        string memory _label,
        address[] memory _participants,
        uint256[] memory _amountsPaid,
        uint256[] memory _amountsOwed
    ) public {
        // Validate inputs
        require(bytes(_label).length > 0, "Label cannot be empty");
        require(_participants.length > 0, "No participants");
        require(
            _participants.length == _amountsPaid.length,
            "Participants and amounts paid must have the same length"
        );
        require(
            _participants.length == _amountsOwed.length,
            "Participants and amounts owed must have the same length"
        );

        // Create new expense with the next ID
        uint256 expenseId = expenseCount++;
        Expense storage newExpense = expenses[expenseId];

        // Set the basic expense information
        newExpense.id = expenseId;
        newExpense.label = _label;
        newExpense.timestamp = block.timestamp; // Current block time in Unix timestamp format

        // Add each participant's data to the expense
        for (uint256 i = 0; i < _participants.length; i++) {
            require(
                _participants[i] != address(0),
                "Invalid participant address"
            );

            // Store the participant, what they paid, and what they owe
            newExpense.participants.push(_participants[i]);
            newExpense.amountPaid[_participants[i]] = _amountsPaid[i];
            newExpense.amountOwed[_participants[i]] = _amountsOwed[i];
        }

        // Emit event for front-end apps
        emit ExpenseAdded(expenseId, _label);
    }

    /**
     * @dev Get information about a person
     * @param _addr Address of the person to look up
     * @return name The person's name
     * @return walletAddress The person's wallet address
     */
    function getPerson(
        address _addr
    ) public view returns (string memory name, address walletAddress) {
        Person storage p = people[_addr];
        return (p.name, p.walletAddress);
    }

    /**
     * @dev Get the list of participants in a specific expense
     * @param _expenseId ID of the expense
     * @return Array of participant addresses
     */
    function getExpenseParticipants(
        uint256 _expenseId
    ) public view returns (address[] memory) {
        require(_expenseId < expenseCount, "Expense does not exist");
        return expenses[_expenseId].participants;
    }

    /**
     * @dev Get basic information about an expense
     * @param _expenseId ID of the expense
     * @return id The expense ID
     * @return label The expense description
     * @return timestamp When the expense was created
     */
    function getExpenseBasicInfo(
        uint256 _expenseId
    ) public view returns (uint256, string memory, uint256) {
        require(_expenseId < expenseCount, "Expense does not exist");
        Expense storage expense = expenses[_expenseId];
        return (expense.id, expense.label, expense.timestamp);
    }

    /**
     * @dev Get the amount a participant paid for a specific expense
     * @param _expenseId ID of the expense
     * @param _participant Address of the participant
     * @return Amount paid by the participant
     */
     
    function getAmountPaid(
        uint256 _expenseId,
        address _participant
    ) public view returns (uint256) {
        require(_expenseId < expenseCount, "Expense does not exist");
        return expenses[_expenseId].amountPaid[_participant];
    }

    /**
     * @dev Get the amount a participant owes for a specific expense
     * @param _expenseId ID of the expense
     * @param _participant Address of the participant
     * @return Amount owed by the participant
     */

    function getAmountOwed(
        uint256 _expenseId,
        address _participant
    ) public view returns (uint256) {
        require(_expenseId < expenseCount, "Expense does not exist");
        return expenses[_expenseId].amountOwed[_participant];
    }

    /**
     * @dev Calculate the net balance for a person across all expenses
     * Positive balance means they are owed money
     * Negative balance means they owe money
     * @param _person Address of the person
     * @return netBalance The calculated net balance
     */
    function getNetBalance(address _person) public view returns (int256) {
        int256 netBalance = 0;

        // Loop through all expenses
        for (uint256 i = 0; i < expenseCount; i++) {
            // Add what they paid (increases their balance)
            netBalance += int256(expenses[i].amountPaid[_person]);

            // Subtract what they owed (decreases their balance)
            netBalance -= int256(expenses[i].amountOwed[_person]);
        }

        return netBalance;
    }

    /**
     * @dev Settle a debt by sending ETH to another person
     * @param _to Address of the person to pay
     * Note: The actual ETH amount is sent with the transaction (msg.value)
     */
    function settleDebt(address _to) public payable {
        // Validate recipient address
        require(_to != address(0), "Invalid recipient address");

        // Prevent sending to yourself
        require(_to != msg.sender, "Cannot settle debt with yourself");

        // Record the settlement as an event
        // The actual ETH transfer happens automatically with the transaction
        emit DebtSettled(msg.sender, _to, msg.value);
    }

    /**
     * @dev Get a list of all registered users' addresses
     * @return Array of all registered wallet addresses
     */
    function getAllRegisteredPeople() public view returns (address[] memory) {
        return registeredPeople;
    }

    // function to update name of user
    function updateName(string memory _newName) public {
        people[msg.sender].name = _newName;
        emit NameUpdated(msg.sender, _newName);
    }
}
