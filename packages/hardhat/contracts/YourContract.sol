// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//Prototype of business accounting system for a services company with multiple owners
//Owners can deposit capital, propose capital adjustments, propose expenses, vote on expenses, and vote to close accounting periods
//Profit is distributed to owners based on their ownership percentage at the time of closing the accounting period

//This is a work-in-progress prototype project and is not intended to be used in production

contract YourContract {
	struct Owner {
		uint256 capital;
		uint256 capitalRequirement;
		uint256 ownershipPercentage;
		bool isAdded;
		bool canDeposit;
		uint256 index;
	}

	struct CapitalAdjustmentProposal {
		address proposedAddress;
		uint256 proposedCapital;
		uint256 votes;
		uint256 totalOwnershipPercentageAtTimeOfProposal;
		bool isIncrease;
		mapping(address => uint256) votesByOwner;
	}

	struct ExpenseProposal {
		string description;
		address recipient;
		uint256 amount;
		uint256 votes;
		bool approved;
		uint256 settlementDate;
		mapping(address => uint256) votesByOwner;
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
		mapping(address => uint256) votesByOwner;
	}

	error OnlyAdmin();
	error OnlyOwners();
	error MismatchOwnersCapitalRequirements();
	error OwnerNotFound();
	error OwnerCannotDeposit();
	error ProposalNotFound();
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
	event CapitalAdjustmentProposed(
		address indexed proposedAddress,
		uint256 proposedCapital,
		bool isIncrease
	);
	event CapitalAdjustmentVoted(
		address indexed owner,
		uint256 proposalID,
		uint256 voteWeight
	);
	event ExpenseProposed(
		uint256 indexed expenseID,
		string description,
		address recipient,
		uint256 amount
	);
	event ExpenseVoted(
		address indexed owner,
		uint256 expenseID,
		uint256 voteWeight
	);
	event ExpenseSettled(uint256 indexed expenseID, bool toSettle);
	event InvoiceIssued(
		uint256 indexed invoiceID,
		address payor,
		uint256 amount,
		uint256 dueDate
	);
	event InvoicePaid(uint256 indexed invoiceID, address payor, uint256 amount);
	event ClosePeriodProposed(
		uint256 indexed proposalID,
		uint256 earnedRevenuePercentage
	);
	event ClosePeriodVoted(
		address indexed owner,
		uint256 proposalID,
		uint256 voteWeight
	);
	event AccountingPeriodClosed(
		uint256 indexed proposalID,
		uint256 earnedRevenuePercentage,
		uint256 distributableIncome,
		uint256 earnedGrossReceipts,
		uint256 totalExpenses,
		uint256 grossReceipts
	);
	event ClearedExpiredExpenseProposal(
		uint256 indexed proposalID,
		uint256 amount
	);

	address public admin;
	uint256 public totalCapital;
	uint256 public earmarkedFunds;
	mapping(address => Owner) public owners;
	address[] public ownerAddresses;
	mapping(uint256 => CapitalAdjustmentProposal)
		public capitalAdjustmentProposals;
	mapping(uint256 => ExpenseProposal) public expenseProposals;
	uint256[] public expenseProposalIDs;
	mapping(uint256 => Invoice) public invoices;
	uint256[] public invoiceIDs;
	uint256 public grossReceipts;
	uint256 public totalExpenses;
	mapping(uint256 => CloseAccountingPeriodProposal)
		public closePeriodProposals;
	uint256[] public closePeriodProposalIDs;

	uint256 public capitalAdjustmentProposalCounter = 0;
	uint256 public expenseProposalCounter = 0;
	uint256 public closePeriodProposalCounter = 0;

	constructor(
		address[] memory initialOwners,
		uint256[] memory capitalRequirements
	) {
		if (initialOwners.length != capitalRequirements.length)
			revert MismatchOwnersCapitalRequirements();

		admin = msg.sender;
		for (uint i = 0; i < initialOwners.length; i++) {
			owners[initialOwners[i]] = Owner(
				0,
				capitalRequirements[i],
				0,
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

	function depositCapital(
		address ownerAddress,
		uint256 amount
	) external payable onlyOwners {
		if (owners[ownerAddress].isAdded == false) revert OwnerNotFound();
		if (owners[ownerAddress].canDeposit == false)
			revert OwnerCannotDeposit();

		owners[ownerAddress].capital += amount;
		totalCapital += amount;

		for (uint i = 0; i < ownerAddresses.length; i++) {
			address currentOwnerAddress = ownerAddresses[i];
			if (owners[currentOwnerAddress].capital > 0) {
				owners[currentOwnerAddress].ownershipPercentage =
					(owners[currentOwnerAddress].capital * 100) /
					totalCapital;
			}
		}
		owners[ownerAddress].canDeposit = false;
		emit CapitalDeposited(ownerAddress, amount);
	}

	function createCapitalAdjustmentProposal(
		address _proposedAddress,
		uint256 _proposedCapital,
		bool _isIncrease
	) external onlyOwners {
		capitalAdjustmentProposalCounter++;
		CapitalAdjustmentProposal storage proposal = capitalAdjustmentProposals[
			capitalAdjustmentProposalCounter
		];
		proposal.proposedAddress = _proposedAddress;
		proposal.proposedCapital = _proposedCapital;
		proposal.votes = owners[msg.sender].ownershipPercentage;
		proposal.totalOwnershipPercentageAtTimeOfProposal = totalCapital;
		proposal.isIncrease = _isIncrease;

		if (owners[msg.sender].ownershipPercentage > 50) {
			owners[proposal.proposedAddress].canDeposit = true;
			delete capitalAdjustmentProposals[capitalAdjustmentProposalCounter];
			return;
		}

		if (owners[_proposedAddress].isAdded == false) {
			owners[_proposedAddress] = Owner(
				0,
				_proposedCapital,
				0,
				true,
				false,
				ownerAddresses.length
			);
			ownerAddresses.push(_proposedAddress);
		} else {
			owners[_proposedAddress].canDeposit = true;
		}
		emit CapitalAdjustmentProposed(
			_proposedAddress,
			_proposedCapital,
			_isIncrease
		);
	}

	function voteForCapitalProposal(
		uint256 proposalID,
		uint256 voteWeight
	) external onlyOwners {
		if (
			capitalAdjustmentProposals[proposalID].proposedAddress == address(0)
		) revert ProposalNotFound();
		if (owners[msg.sender].ownershipPercentage < voteWeight)
			revert InsufficientOwnershipPercentage();

		CapitalAdjustmentProposal storage proposal = capitalAdjustmentProposals[
			proposalID
		];
		proposal.votes += voteWeight;
		proposal.votesByOwner[msg.sender] = voteWeight;

		if (
			proposal.votes * 2 >
			proposal.totalOwnershipPercentageAtTimeOfProposal
		) {
			owners[proposal.proposedAddress].canDeposit = true;
			delete capitalAdjustmentProposals[proposalID];
		}
		emit CapitalAdjustmentVoted(msg.sender, proposalID, voteWeight);
	}

	function createExpenseProposal(
		string memory description,
		address recipient,
		uint256 amount
	) external onlyOwners {
		expenseProposalCounter++;
		ExpenseProposal storage expenseProposal = expenseProposals[
			expenseProposalCounter
		];
		expenseProposal.description = description;
		expenseProposal.recipient = recipient;
		expenseProposal.amount = amount;
		expenseProposal.settlementDate = block.timestamp;
		expenseProposal.votes = owners[msg.sender].ownershipPercentage;

		if (owners[msg.sender].ownershipPercentage > 50) {
			expenseProposal.approved = true;
		} else {
			expenseProposal.approved = false;
		}

		expenseProposalIDs.push(expenseProposalCounter);

		emit ExpenseProposed(
			expenseProposalCounter,
			description,
			recipient,
			amount
		);
	}

	function voteForExpenseProposal(
		uint256 expenseID,
		uint256 voteWeight
	) external onlyOwners {
		ExpenseProposal storage expenseProposal = expenseProposals[expenseID];
		if (expenseProposal.recipient == address(0))
			revert ExpenseProposalNotFound();
		if (owners[msg.sender].ownershipPercentage < voteWeight)
			revert InsufficientOwnershipPercentage();

		expenseProposal.votes += voteWeight;
		expenseProposal.votesByOwner[msg.sender] = voteWeight;

		if (expenseProposal.votes * 2 > totalCapital) {
			expenseProposal.approved = true;
		}

		emit ExpenseVoted(msg.sender, expenseID, voteWeight);
	}

	function settleExpense(uint256 expenseID, bool toSettle) external {
		ExpenseProposal storage expenseProposal = expenseProposals[expenseID];
		if (expenseProposal.recipient == address(0))
			revert ExpenseProposalNotFound();

		if (block.timestamp < expenseProposal.settlementDate)
			revert CannotSettleBeforeDate();

		if (toSettle) {
			if (expenseProposal.approved == false) revert ExpenseNotApproved();
			(bool success, ) = payable(expenseProposal.recipient).call{
				value: expenseProposal.amount
			}("");
			if (!success) revert TransferFailed();

			totalExpenses += expenseProposal.amount;
		} else {
			earmarkedFunds -= expenseProposal.amount;
		}

		for (uint256 i = 0; i < expenseProposalIDs.length; i++) {
			if (expenseProposalIDs[i] == expenseID) {
				for (uint256 j = i; j < expenseProposalIDs.length - 1; j++) {
					expenseProposalIDs[j] = expenseProposalIDs[j + 1];
				}

				expenseProposalIDs.pop();
				break;
			}
		}

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

	function proposeCloseAccountingPeriod(
		uint256 earnedRevenuePercentage
	) external onlyOwners {
		closePeriodProposalCounter++;
		CloseAccountingPeriodProposal storage proposal = closePeriodProposals[
			closePeriodProposalCounter
		];
		proposal.earnedRevenuePercentage = earnedRevenuePercentage;
		proposal.votes = owners[msg.sender].ownershipPercentage;

		if (owners[msg.sender].ownershipPercentage > 50) {
			proposal.approved = true;
		} else {
			proposal.approved = false;
		}

		closePeriodProposalIDs.push(closePeriodProposalCounter);

		emit ClosePeriodProposed(
			closePeriodProposalCounter,
			earnedRevenuePercentage
		);
	}

	function voteForClosePeriodProposal(
		uint256 proposalID,
		uint256 voteWeight
	) external onlyOwners {
		CloseAccountingPeriodProposal storage proposal = closePeriodProposals[
			proposalID
		];
		if (proposal.earnedRevenuePercentage == 0)
			revert ClosePeriodProposalNotFound();
		if (owners[msg.sender].ownershipPercentage < voteWeight)
			revert InsufficientOwnershipPercentage();

		proposal.votes += voteWeight;
		proposal.votesByOwner[msg.sender] = voteWeight;

		if (proposal.votes * 2 > totalCapital) {
			proposal.approved = true;
		}

		emit ClosePeriodVoted(msg.sender, proposalID, voteWeight);
	}

	function executeCloseAccountingPeriod(
		uint256 proposalID
	) external onlyOwners {
		CloseAccountingPeriodProposal storage proposal = closePeriodProposals[
			proposalID
		];
		if (proposal.approved == false) revert ClosePeriodProposalNotFound();

		uint256 earnedGrossReceipts = (grossReceipts *
			proposal.earnedRevenuePercentage) / 100;
		uint256 distributableIncome = 0;
		if (earnedGrossReceipts > totalExpenses) {
			distributableIncome = earnedGrossReceipts - totalExpenses;
		}

		grossReceipts -= earnedGrossReceipts;
		totalExpenses = 0;

		if (distributableIncome > 0) {
			for (uint i = 0; i < ownerAddresses.length; i++) {
				address currentOwnerAddress = ownerAddresses[i];
				uint256 ownershipPercentage = owners[currentOwnerAddress]
					.ownershipPercentage;
				uint256 ownerShare = (distributableIncome *
					ownershipPercentage) / 100;
				if (ownerShare > 0) {
					(bool success, ) = payable(currentOwnerAddress).call{
						value: ownerShare
					}("");
					if (!success) revert TransferFailed();
				}
			}
		}

		emit AccountingPeriodClosed(
			proposalID,
			proposal.earnedRevenuePercentage,
			distributableIncome,
			earnedGrossReceipts,
			totalExpenses,
			grossReceipts
		);

		for (uint256 i = 0; i < closePeriodProposalIDs.length; i++) {
			if (closePeriodProposalIDs[i] == proposalID) {
				for (
					uint256 j = i;
					j < closePeriodProposalIDs.length - 1;
					j++
				) {
					closePeriodProposalIDs[j] = closePeriodProposalIDs[j + 1];
				}

				closePeriodProposalIDs.pop();
				break;
			}
		}

		delete closePeriodProposals[proposalID];
	}
}
