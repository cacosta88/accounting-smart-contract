// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//Prototype of business accounting system for a services company with multiple owners
//Owners can deposit capital, propose capital adjustments, propose expenses, vote on expenses, and vote to close accounting periods
//Profit is distributed to owners based on their ownership percentage at the time of closing the accounting period

//This is a work-in-progress prototype project and is not intended to be used in production

//open items:
// for each type of proposal, make sure owner can not vote more than once



contract YourContract {
    struct Owner {
        uint256 capital;
        uint256 capitalRequirement;
        bool isAdded;
        bool canDeposit;
        uint256 index;
    }

    struct CapitalAdjustmentProposal {
        address proposedAddress;
        uint256 proposedCapital;
        uint256 votes;
        bool isIncrease;
    }

    struct ExpenseProposal {
        string description;
        address recipient;
        uint256 amount;
        uint256 votes;
        bool approved;
        uint256 settlementDate;
    }

    struct Invoice {
        address payable payor;
        uint256 amount;
        uint256 recognitionPeriod; 
        uint256 dueDate; 
        uint256 startRecognitionDate; 
        bool isPaid;
    }

    struct CloseAccountingPeriodProposal {
        uint256 earnedRevenuePercentage;
        uint256 votes;
        bool approved;
    }


    error OnlyAdmin();
    error OnlyOwners();
    error MismatchOwnersCapitalRequirements();
    error OwnerNotFound();
    error OwnerCannotDeposit();
    error ProposalNotFound();
    error CanOnlyVoteOnce();
    error InsufficientOwnershipPercentage();
    error ExpenseProposalNotFound();
    error CannotSettleBeforeDate();
    error ExpenseNotApproved();
    error TransferFailed();
    error IncorrectAmountSent();
    error InvoiceAlreadyPaid();
    error ClosePeriodProposalNotFound();
	error OnlyPayorCanPayInvoice();
    


    event CapitalDeposited(address indexed ownerAddress, uint256 amount);
    event CapitalAdjustmentProposed(address indexed proposedAddress, uint256 proposedCapital, bool isIncrease);
    event CapitalAdjustmentVoted(address indexed owner, uint256 proposalID);
    event ExpenseProposed(uint256 indexed expenseID, string description, address recipient, uint256 amount);
    event ExpenseVoted(address indexed owner, uint256 expenseID,uint256 voteWeight);
    event ExpenseApproved(uint256 indexed expenseID);
    event ExpenseSettled(uint256 indexed expenseID, bool toSettle);
	event InvoiceIssued(uint256 indexed invoiceID, address payor, uint256 amount, uint256 dueDate);
    event InvoicePaid(uint256 indexed invoiceID, address payor, uint256 amount);
    event ClosePeriodProposed(uint256 indexed proposalID, uint256 earnedRevenuePercentage);
    event ClosePeriodVoted(address indexed owner, uint256 proposalID);
    event AccountingPeriodClosed(uint256 indexed proposalID, uint256 earnedRevenuePercentage, uint256 distributableIncome, uint256 earnedGrossReceipts, uint256 totalExpenses, uint256 grossReceipts);
	event ClearedExpiredExpenseProposal(uint256 indexed proposalID, uint256 amount);

    address public admin;
    uint256 public totalCapital;
    uint256 public earmarkedFunds;
    mapping(address => Owner) public owners;
    address[] public ownerAddresses;
    mapping(uint256 => CapitalAdjustmentProposal) public capitalAdjustmentProposals;
    mapping(uint256 => ExpenseProposal) public expenseProposals;
    uint256[] public expenseProposalIDs;
    mapping(uint256 => uint256) public expenseProposalIndex;
    mapping(uint256 => Invoice) public invoices;
    uint256[] public invoiceIDs;
    uint256 public grossReceipts;
    uint256 public totalExpenses;
    mapping(uint256 => CloseAccountingPeriodProposal) public closePeriodProposals;
    uint256[] public closePeriodProposalIDs;
    mapping(uint256 => uint256) public closePeriodProposalIndex;


    uint256 public capitalAdjustmentProposalCounter = 0;
    uint256 public expenseProposalCounter = 0;
    uint256 public closePeriodProposalCounter = 0;


    mapping(uint256 => mapping(address => bool)) public capitalAdjustmentProposalVoters;
    mapping(uint256 => mapping(address => bool)) public expenseProposalVoters;
    mapping(uint256 => mapping(address => bool)) public closePeriodProposalVoters;


    constructor(
        address[] memory initialOwners,
        uint256[] memory capitalRequirements
    ) {

		if (initialOwners.length != capitalRequirements.length) revert MismatchOwnersCapitalRequirements();

        admin = msg.sender;
        for (uint i = 0; i < initialOwners.length; i++) {
            owners[initialOwners[i]] = Owner(
                0,
                capitalRequirements[i],
                true,
                true,
                i
            );
            ownerAddresses.push(initialOwners[i]);
        }
	
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;

		
    }

    modifier onlyOwners() {
        if (owners[msg.sender].isAdded == false) revert OwnerNotFound();
        _;
    }

    function calculateOwnershipPercentage(uint256 ownerCapital) private view returns (uint256) {
    return (ownerCapital * 100) / totalCapital;
}
    
    function depositCapital(
        address ownerAddress,
        uint256 amount
    ) external payable onlyOwners {
		if (owners[ownerAddress].isAdded == false) revert OwnerNotFound();
		if (owners[ownerAddress].canDeposit == false) revert OwnerCannotDeposit();

        owners[ownerAddress].capital += amount;
        totalCapital += amount;

        owners[ownerAddress].canDeposit = false;
    emit CapitalDeposited(ownerAddress, amount);
	}
	


    function createCapitalAdjustmentProposal(
        address _proposedAddress,
        uint256 _proposedCapital,
        bool _isIncrease
    ) external onlyOwners {
        capitalAdjustmentProposalCounter++;
        CapitalAdjustmentProposal storage proposal = capitalAdjustmentProposals[capitalAdjustmentProposalCounter];
        proposal.proposedAddress = _proposedAddress;
        proposal.proposedCapital = _proposedCapital;
        proposal.votes = calculateOwnershipPercentage(_proposedCapital);
        proposal.isIncrease = _isIncrease;

        if (calculateOwnershipPercentage(owners[msg.sender].capital) > 50) {
            owners[proposal.proposedAddress].canDeposit = true;
            delete capitalAdjustmentProposals[capitalAdjustmentProposalCounter];
            return;
        }

        if (owners[_proposedAddress].isAdded == false) {
            owners[_proposedAddress] = Owner(
                0,
                _proposedCapital,
                true,
                false,
                ownerAddresses.length
            );
            ownerAddresses.push(_proposedAddress);
        } else {
            owners[_proposedAddress].canDeposit = true;
        }
	emit CapitalAdjustmentProposed(_proposedAddress, _proposedCapital, _isIncrease);
    }

    function voteForCapitalProposal(
        uint256 proposalID
    ) external onlyOwners {
		if (capitalAdjustmentProposals[proposalID].proposedAddress == address(0)) revert ProposalNotFound();
        if (capitalAdjustmentProposalVoters[proposalID][msg.sender]) revert CanOnlyVoteOnce();

        CapitalAdjustmentProposal storage proposal = capitalAdjustmentProposals[proposalID];
        proposal.votes += calculateOwnershipPercentage(owners[msg.sender].capital);

        if (
            proposal.votes > 50
        ) {
            owners[proposal.proposedAddress].canDeposit = true;
            delete capitalAdjustmentProposals[proposalID];
        }
		emit CapitalAdjustmentVoted(msg.sender, proposalID);
    }

    function createExpenseProposal(
        string memory description,
        address recipient,
        uint256 amount
    ) external onlyOwners {
        expenseProposalCounter++;
        ExpenseProposal storage expenseProposal = expenseProposals[expenseProposalCounter];
        expenseProposal.description = description;
        expenseProposal.recipient = recipient;
        expenseProposal.amount = amount;
        expenseProposal.settlementDate = block.timestamp;
        uint256 initialExpenseProposalVotes = calculateOwnershipPercentage(owners[msg.sender].capital);
        expenseProposal.votes = initialExpenseProposalVotes ;


        if (initialExpenseProposalVotes  > 50) {
            expenseProposal.approved = true;
        } else {
            expenseProposal.approved = false;
        }

        expenseProposalIDs.push(expenseProposalCounter);
        expenseProposalIndex[expenseProposalCounter] = expenseProposalIDs.length - 1;

		emit ExpenseProposed(expenseProposalCounter, description, recipient, amount);
    }

    function voteForExpenseProposal(
        uint256 expenseID
    ) external onlyOwners {
        if (expenseProposalVoters[expenseID][msg.sender]) revert CanOnlyVoteOnce();
        ExpenseProposal storage expenseProposal = expenseProposals[expenseID];
		if (expenseProposal.recipient == address(0)) revert ExpenseProposalNotFound();


        uint256 votescast = calculateOwnershipPercentage(owners[msg.sender].capital);
        expenseProposal.votes += votescast;


        if (votescast > 50) {
            expenseProposal.approved = true;
            emit ExpenseApproved(expenseID);

        }

		emit ExpenseVoted(msg.sender, expenseID, votescast);
    }

    function settleExpense(uint256 expenseID, bool toSettle) external onlyOwners {
    ExpenseProposal storage expenseProposal = expenseProposals[expenseID];
    if (expenseProposal.recipient == address(0)) revert ExpenseProposalNotFound();
    if (!expenseProposal.approved) revert ExpenseNotApproved();
    if (block.timestamp < expenseProposal.settlementDate) revert CannotSettleBeforeDate();

    if (toSettle) {
        (bool success,) = payable(expenseProposal.recipient).call{value: expenseProposal.amount}("");
        require(success, "TransferFailed");

        totalExpenses += expenseProposal.amount;
    } else {
        earmarkedFunds -= expenseProposal.amount;
    }

    uint256 lastExpenseID = expenseProposalIDs[expenseProposalIDs.length - 1];
    uint256 expenseIndex = expenseProposalIndex[expenseID];
    expenseProposalIDs[expenseIndex] = lastExpenseID;
    expenseProposalIndex[lastExpenseID] = expenseIndex;
    expenseProposalIDs.pop();

    delete expenseProposals[expenseID];
    emit ExpenseSettled(expenseID, toSettle);
}

    function clearExpiredProposals() external onlyAdmin {
        for (uint256 i = 0; i < expenseProposalIDs.length; i++) {
            uint256 expenseID = expenseProposalIDs[i];
            ExpenseProposal storage proposal = expenseProposals[expenseID];

            if (
                block.timestamp > proposal.settlementDate + 1 days &&
                !proposal.approved
            ) {
                earmarkedFunds -= proposal.amount;
                delete expenseProposals[expenseID];


                for (uint256 j = i; j < expenseProposalIDs.length - 1; j++) {
                    expenseProposalIDs[j] = expenseProposalIDs[j + 1];
                }


                expenseProposalIDs.pop();
                i--; 
            }
        emit ClearedExpiredExpenseProposal(expenseID, proposal.amount);
        }
		
    }

	function issueInvoice(
        address payable _payor,
        uint256 _amount,
        uint256 _recognitionPeriod,
        uint256 _dueDate
    ) external onlyOwners {
        Invoice memory newInvoice;
        newInvoice.payor = _payor;
        newInvoice.amount = _amount;
        newInvoice.recognitionPeriod = _recognitionPeriod;
        newInvoice.dueDate = _dueDate;
        newInvoice.startRecognitionDate = block.timestamp;
        newInvoice.isPaid = false;

        invoiceIDs.push(invoiceIDs.length);
        invoices[invoiceIDs.length] = newInvoice;

        emit InvoiceIssued(invoiceIDs.length, _payor, _amount, _dueDate);
    }
    
	function payInvoice(uint256 invoiceID) external payable {
        Invoice storage invoice = invoices[invoiceID];
        if (invoice.payor != msg.sender) revert OnlyPayorCanPayInvoice();
		if (invoice.amount != msg.value) revert IncorrectAmountSent();
		if (invoice.isPaid) revert InvoiceAlreadyPaid();

        invoice.isPaid = true;
        grossReceipts += msg.value;
		emit InvoicePaid(invoiceID, msg.sender, msg.value);
    }

    function proposeCloseAccountingPeriod(uint256 earnedRevenuePercentage) external onlyOwners {
        closePeriodProposalCounter++;
        CloseAccountingPeriodProposal storage proposal = closePeriodProposals[closePeriodProposalCounter];
        proposal.earnedRevenuePercentage = earnedRevenuePercentage;
        uint256 initialOwnershipPercentage = calculateOwnershipPercentage(owners[msg.sender].capital);
        proposal.votes = initialOwnershipPercentage;

        if (initialOwnershipPercentage > 50) {
            proposal.approved = true;
        } 

        closePeriodProposalIDs.push(closePeriodProposalCounter);

		emit ClosePeriodProposed(closePeriodProposalCounter, earnedRevenuePercentage);
    }


    function voteForClosePeriodProposal(uint256 proposalID) external onlyOwners {
        if (closePeriodProposalVoters[proposalID][msg.sender]) revert CanOnlyVoteOnce();
        CloseAccountingPeriodProposal storage proposal = closePeriodProposals[proposalID];
        if (proposal.earnedRevenuePercentage == 0) revert ClosePeriodProposalNotFound();

        uint256 voteCast = calculateOwnershipPercentage(owners[msg.sender].capital);
        proposal.votes += voteCast;


        if (voteCast > 50) {
            proposal.approved = true;
        }

		emit ClosePeriodVoted(msg.sender, proposalID);
    }

    function executeCloseAccountingPeriod(uint256 proposalID) external onlyOwners {
        CloseAccountingPeriodProposal storage proposal = closePeriodProposals[proposalID];
		if (proposal.approved == false) revert ClosePeriodProposalNotFound();

        uint256 earnedGrossReceipts = (grossReceipts * proposal.earnedRevenuePercentage) / 100;
        uint256 distributableIncome = 0;
        if (earnedGrossReceipts > totalExpenses) {
            distributableIncome = earnedGrossReceipts - totalExpenses;
        }

        grossReceipts -= earnedGrossReceipts;
        totalExpenses = 0;

        if (distributableIncome > 0) {
            for (uint i = 0; i < ownerAddresses.length; i++) {
                address currentOwnerAddress = ownerAddresses[i];
                uint256 ownershipPercentage = calculateOwnershipPercentage(owners[currentOwnerAddress].capital);
                uint256 ownerShare = (distributableIncome * ownershipPercentage) / 100;
                if (ownerShare > 0) {
                    (bool success, ) = payable(currentOwnerAddress).call{value: ownerShare}("");
					if (!success) revert TransferFailed();
                }
            }}
        
		emit AccountingPeriodClosed(proposalID, proposal.earnedRevenuePercentage, distributableIncome, earnedGrossReceipts, totalExpenses, grossReceipts);


        uint256 lastProposalID = closePeriodProposalIDs[closePeriodProposalIDs.length - 1];
        uint256 proposalIndex = closePeriodProposalIndex[proposalID];
        closePeriodProposalIDs[proposalIndex] = lastProposalID;
        closePeriodProposalIndex[lastProposalID] = proposalIndex;
        closePeriodProposalIDs.pop();


		delete closePeriodProposals[proposalID];
        emit AccountingPeriodClosed(proposalID, proposal.earnedRevenuePercentage, distributableIncome, earnedGrossReceipts, totalExpenses, grossReceipts);
    
} 



    function getOwnerAddresses() external view returns (address[] memory) {
        return ownerAddresses;
    }


    function getOwnerDetails(address _address   ) external view returns (uint256[] memory) {
        uint256[] memory ownerDetails = new uint256[](5);
        ownerDetails[0] = owners[_address  ].capital;
        ownerDetails[1] = owners[_address  ].capitalRequirement;
        ownerDetails[3] = owners[_address  ].isAdded ? 1 : 0;
        ownerDetails[4] = owners[_address  ].canDeposit ? 1 : 0;
        return ownerDetails;
    }

    function getExpenseProposalIDs() external view returns (uint256[] memory) {
        return expenseProposalIDs;
    }

    function getInvoiceIDs() external view returns (uint256[] memory) {
        return invoiceIDs;
    }

    function getClosePeriodProposalIDs() external view returns (uint256[] memory) {
        return closePeriodProposalIDs;
    }

    function getCapitalAdjustmentProposal(uint256 proposalID) external view returns (address, uint256, uint256, bool) {
        CapitalAdjustmentProposal storage proposal = capitalAdjustmentProposals[proposalID];
        return (proposal.proposedAddress, proposal.proposedCapital, proposal.votes, proposal.isIncrease);
    }

    function getExpenseProposal(uint256 expenseID) external view returns (string memory, address, uint256, uint256, bool) {
        ExpenseProposal storage proposal = expenseProposals[expenseID];
        return (proposal.description, proposal.recipient, proposal.amount, proposal.votes, proposal.approved);
    }

}
