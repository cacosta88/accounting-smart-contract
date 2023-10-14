# 🏗 Prototype For Business Entity Accounting

## Overview

This smart contract prototype mimics the bookkeeping functions of a service-oriented business with multiple owners. Owners can manage capital, propose expenses, issue invoices, and conclude accounting periods. After each accounting period, profit gets distributed based on each owner's stake at that time.

The accrual method of accounting recognizes financial events when they occur, regardless of when the eth transaction takes place. This smart contract is designed to closely emulate the accrual method by capturing economic events independently of the related eth flows. This ensures a more accurate reflection of the business's financial health over specific accounting periods.

### How It Works

1. **Expense Recognition**: Through the `createExpenseProposal()` function, expenses are recognized when they are incurred, not when they are paid. For instance, if an owner proposes a new business expense for services already received but not yet paid for, the expense is recorded in the system pending approval.

2. **Revenue Recognition**: This smart contract recognizes revenue based on a percentage of gross receipts upon closing of the accounting period. The actual eth flow might have occurred earlier, but revenue is recognized based on the deemed earned percentage when the `proposeCloseAccountingPeriod()` function is invoked.

3. **Accounting Period Closure**: The `proposeCloseAccountingPeriod()` function enables owners to close out an accounting period. This captures all the recognized revenues and expenses for that period and determines the net income or loss. This reflects the essence of the accrual method as it gives a comprehensive view of financial activities over the period, irrespective of eth movement.

4. **Capital Adjustments**: Capital-related functions such as `depositCapital()` and `createCapitalAdjustmentProposal()` allow owners to contribute or adjust their capital without immediately impacting the profit or loss for the period. This ensures that owner contributions or withdrawals don't distort the true operational performance of the business.

### Advantages

By emulating the accrual method, this smart contract offers a more holistic view of the business's financial health. Owners can make informed decisions based on the actual financial performance and not just eth flows.

### Considerations

While the accrual method provides a clearer picture of financial health, it's crucial for owners to also monitor eth flows to ensure the business remains solvent. Future iterations of this smart contract may include more sophisticated eth flow tracking and reporting mechanisms.


## Motivation

Traditional bookkeeping systems rely heavily on segregation of duties, ensuring that no single individual can control all aspects of any critical financial transaction. This segregation ensures accuracy, reliability, and reduces the risk of fraud. However, it comes with overheads:

1. **Complexity**: Establishing a multi-tier approval mechanism.
2. **Time-consuming**: Multiple approvals lead to process delays.
3. **Operational Costs**: Requires multiple employees or teams for different roles.

Smart contracts on blockchain inherently bring transparency, immutability, and auditability. By shifting to this Smart Business Accounting System:

- We **eliminate the need for segregation** of duties without compromising on reliability.
- All transactions are **transparent and verifiable** by all stakeholders.
- It offers **cost savings** as processes get automated without multiple handovers.
- **Reduces potential points of failure** due to human errors or malintent.

## Features

1. **Capital Management**: Owners can deposit and adjust their capital.
2. **Expense Proposals**: Any owner can propose an expense which can be voted upon.
3. **Revenue Management**: Invoices can be created and managed.
4. **Accounting Period Closure**: Owners can propose and vote to close accounting periods.

## Quick Note

This is a work-in-progress prototype and is not intended for production use.

## Contract Functions

### Capital

- `depositCapital()`: Deposit funds into the business.
- `createCapitalAdjustmentProposal()`: Propose changes in capital allocation.
- `voteForCapitalProposal()`: Vote on capital adjustment proposals.

### Expenses

- `createExpenseProposal()`: Propose a new business expense.
- `voteForExpenseProposal()`: Vote on proposed expenses.
- `settleExpense()`: Settle or reject an approved expense.

### Invoices

- `issueInvoice()`: Allows owners to issue invoices.
- `payInvoice()`: Allows external entities to pay invoices.

### Accounting Period

- `proposeCloseAccountingPeriod()`: Propose closing the current accounting period.
- `voteForClosePeriodProposal()`: Vote on proposals to close accounting periods.
- `executeCloseAccountingPeriod()`: Execute the closing of an accounting period.

## Contribution

Feel free to contribute to the project by raising issues or proposing pull requests.
