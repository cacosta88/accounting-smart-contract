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

- `payInvoice()`: Allows external entities to pay invoices.

### Accounting Period

- `proposeCloseAccountingPeriod()`: Propose closing the current accounting period.
- `voteForClosePeriodProposal()`: Vote on proposals to close accounting periods.
- `executeCloseAccountingPeriod()`: Execute the closing of an accounting period.

## Contribution

Feel free to contribute to the project by raising issues or proposing pull requests.




# 🏗 Scaffold-ETH 2

<h4 align="center">
  <a href="https://docs.scaffoldeth.io">Documentation</a> |
  <a href="https://scaffoldeth.io">Website</a>
</h4>

🧪 An open-source, up-to-date toolkit for building decentralized applications (dapps) on the Ethereum blockchain. It's designed to make it easier for developers to create and deploy smart contracts and build user interfaces that interact with those contracts.

⚙️ Built using NextJS, RainbowKit, Hardhat, Wagmi, and Typescript.

- ✅ **Contract Hot Reload**: Your frontend auto-adapts to your smart contract as you edit it.
- 🔥 **Burner Wallet & Local Faucet**: Quickly test your application with a burner wallet and local faucet.
- 🔐 **Integration with Wallet Providers**: Connect to different wallet providers and interact with the Ethereum network.

![Debug Contracts tab](https://github.com/scaffold-eth/scaffold-eth-2/assets/55535804/1171422a-0ce4-4203-bcd4-d2d1941d198b)

## Requirements

Before you begin, you need to install the following tools:

- [Node (v18 LTS)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Clone this repo & install dependencies

```
git clone https://github.com/scaffold-eth/scaffold-eth-2.git
cd scaffold-eth-2
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Hardhat. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `hardhat.config.ts`.

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/hardhat/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/hardhat/deploy` to deploy the contract to the network. You can also customize the deploy script.

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the contract component or the example ui in the frontend. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

Run smart contract test with `yarn hardhat:test`

- Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`
- Edit your frontend in `packages/nextjs/pages`
- Edit your deployment scripts in `packages/hardhat/deploy`

## Documentation

Visit our [docs](https://docs.scaffoldeth.io) to learn how to start building with Scaffold-ETH 2.

To know more about its features, check out our [website](https://scaffoldeth.io).

## Contributing to Scaffold-ETH 2

We welcome contributions to Scaffold-ETH 2!

Please see [CONTRIBUTING.MD](https://github.com/scaffold-eth/scaffold-eth-2/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scaffold-ETH 2.
