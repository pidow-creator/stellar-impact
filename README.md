# Stellar Impact

## Description

Stellar Impact is a decentralized social impact platform built on the Stacks blockchain that revolutionizes impact investing through autonomous outcome verification and community governance. This Clarity smart contract creates a transparent ecosystem where social impact projects receive funding based on measurable, blockchain-verified results rather than traditional promises or projections.

The contract implements a comprehensive system for creating and managing impact projects with milestone-based funding, oracle-verified outcomes, and automated fund disbursement. It features a dual-token economy concept (IMPACT tokens for governance and OUTCOME tokens representing verified impact units), impact insurance pools, carbon credit marketplace integration, and a proprietary Impact Quotient algorithm for scoring projects.

## Features

- **Project Creation & Management**: Create impact projects with customizable funding goals, categories, and status tracking (proposed, active, paused, completed, cancelled)
- **Milestone-Based Funding**: Define project milestones with specific funding amounts and verification thresholds for transparent progress tracking
- **Investment System**: Investors can fund projects and receive IMPACT tokens (1000 IMPACT per STX) representing their stake in social impact outcomes
- **Oracle Verification Network**: Register as oracle verifiers to validate milestone completion with reputation-based scoring and verification tracking
- **Autonomous Fund Release**: Automated fund disbursement to project creators upon verified milestone completion
- **Impact Quotient Algorithm**: Proprietary scoring system based on verification reliability (40%), benefit scale (35%), and sustainability (25%)
- **Governance Voting**: Community-driven governance using vote-weight mechanisms for project approval
- **Insurance Pools**: Impact insurance pools where contributors can provide safety nets for projects
- **Carbon Credit Marketplace**: Built-in system for environmental projects to register, price, and sell verified carbon credits
- **Real-time Tracking**: Monitor funding progress, verified outcomes, and project status throughout the lifecycle
- **Reputation System**: Oracle verifiers earn reputation scores based on verification accuracy and participation

## Contract Functions

### Read-Only Functions

**get-project** `(project-id uint) -> (optional project-data)`
Retrieves complete project information including creator, funding details, status, and verified outcomes.

**get-milestone** `(milestone-id uint) -> (optional milestone-data)`
Returns milestone details including project association, funding amount, verification status, and completion data.

**get-investment** `(investor principal, project-id uint) -> (optional investment-data)`
Fetches investment records showing STX amount, IMPACT tokens earned, OUTCOME tokens, and investment timestamp.

**get-oracle-verifier** `(oracle-id uint) -> (optional oracle-data)`
Provides oracle verifier information including reputation score, total verifications, and active status.

**get-verification-record** `(milestone-id uint, oracle-id uint) -> (optional verification-data)`
Returns specific verification records with verification score, data hash, and timestamp.

**calculate-impact-quotient** `(verification-reliability uint, benefit-scale uint, sustainability-score uint) -> (response uint)`
Calculates weighted Impact Quotient score using the proprietary algorithm (max score: 100).

**get-funding-progress** `(project-id uint) -> (response uint)`
Computes funding progress percentage based on total raised versus funding goal.

**get-carbon-credits** `(project-id uint) -> (optional carbon-credit-data)`
Retrieves carbon credit information including total credits, sold amount, and pricing.

**get-insurance-pool** `(project-id uint) -> (optional insurance-data)`
Returns insurance pool details with total pool amount, claimed funds, and contributor count.

**get-governance-vote** `(project-id uint, voter principal) -> (optional vote-data)`
Fetches governance vote records for specific voter and project combinations.

### Public Functions

**create-project** `(name string-ascii, description string-utf8, category string-ascii, funding-goal uint) -> (response uint)`
Creates a new impact project with proposed status. Returns project-id on success.

**create-milestone** `(project-id uint, description string-utf8, funding-amount uint, verification-threshold uint) -> (response uint)`
Adds a milestone to an existing project. Only callable by project creator. Returns milestone-id.

**invest-in-project** `(project-id uint, amount-stx uint) -> (response tuple)`
Invests STX in an active project, transfers funds to contract, mints IMPACT tokens, and updates project total raised.

**register-oracle** `() -> (response uint)`
Registers caller as oracle verifier with initial reputation score of 50. Returns oracle-id.

**submit-verification** `(milestone-id uint, oracle-id uint, verified bool, score uint, data-hash buff) -> (response bool)`
Submits milestone verification with score and data hash. Updates oracle statistics and verification records.

**complete-milestone** `(milestone-id uint) -> (response bool)`
Marks milestone as completed and releases funding to project creator when verification threshold is met.

**update-project-status** `(project-id uint, new-status uint) -> (response bool)`
Updates project status (0-4). Only callable by project creator.

**contribute-to-insurance** `(project-id uint, amount uint) -> (response bool)`
Adds STX to project insurance pool for risk mitigation.

**register-carbon-credits** `(project-id uint, credits uint, price-per-credit uint) -> (response bool)`
Registers carbon credits for environmental projects with pricing. Only callable by project creator.

**purchase-carbon-credits** `(project-id uint, credit-amount uint) -> (response tuple)`
Purchases available carbon credits, transfers payment to project creator, and updates credit inventory.

**cast-vote** `(project-id uint, vote-for bool, vote-weight uint) -> (response bool)`
Casts governance vote on proposed projects. Each voter can vote once per project.

**update-impact-quotient** `(project-id uint, new-quotient uint) -> (response bool)`
Updates project Impact Quotient score. Admin-only function.

**update-threshold** `(new-threshold uint) -> (response bool)`
Updates global impact quotient threshold. Admin-only function.

## Usage Examples

### Creating an Impact Project

```clarity
;; Create a clean water access project
(contract-call? .stellar-impact create-project
  "Clean Water Initiative"
  u"Providing clean water access to 1000 families in rural communities through well construction and filtration systems"
  "water-sanitation"
  u50000000000) ;; 50,000 STX funding goal

;; Returns: (ok u1) - project-id
```

### Adding Milestones

```clarity
;; Add milestone for well construction phase
(contract-call? .stellar-impact create-milestone
  u1 ;; project-id
  u"Complete construction of 10 water wells with IoT monitoring sensors"
  u15000000000 ;; 15,000 STX for this milestone
  u85) ;; 85% verification threshold

;; Returns: (ok u1) - milestone-id
```

### Investing in a Project

```clarity
;; Invest 100 STX in project
(contract-call? .stellar-impact invest-in-project
  u1 ;; project-id
  u100000000) ;; 100 STX

;; Returns: (ok {invested: u100000000, impact-tokens: u100000000000})
;; Investor receives 100,000 IMPACT tokens
```

### Oracle Verification

```clarity
;; Register as oracle verifier
(contract-call? .stellar-impact register-oracle)
;; Returns: (ok u1) - oracle-id

;; Submit verification for milestone
(contract-call? .stellar-impact submit-verification
  u1 ;; milestone-id
  u1 ;; oracle-id
  true ;; verified
  u92 ;; verification score
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef) ;; data hash

;; Returns: (ok true)
```

### Completing Milestones

```clarity
;; Project creator completes milestone after verification threshold met
(contract-call? .stellar-impact complete-milestone u1)
;; Releases 15,000 STX to project creator
;; Returns: (ok true)
```

### Carbon Credit Trading

```clarity
;; Register carbon credits for environmental project
(contract-call? .stellar-impact register-carbon-credits
  u5 ;; project-id
  u1000 ;; 1000 carbon credits
  u50000) ;; 0.05 STX per credit

;; Purchase carbon credits
(contract-call? .stellar-impact purchase-carbon-credits
  u5 ;; project-id
  u100) ;; purchase 100 credits
;; Returns: (ok {credits-purchased: u100, total-cost: u5000000})
```

### Governance Voting

```clarity
;; Vote on proposed project
(contract-call? .stellar-impact cast-vote
  u10 ;; project-id
  true ;; vote in favor
  u1000) ;; vote weight based on IMPACT tokens held

;; Returns: (ok true)
```

### Checking Progress

```clarity
;; Get funding progress percentage
(contract-call? .stellar-impact get-funding-progress u1)
;; Returns: (ok u30) - 30% funded

;; Calculate Impact Quotient
(contract-call? .stellar-impact calculate-impact-quotient
  u85 ;; verification reliability
  u90 ;; benefit scale
  u75) ;; sustainability score
;; Returns: (ok u84) - Impact Quotient of 84
```

## Testing

To run tests for the Stellar Impact contract:

```bash
# Install dependencies
npm install

# Run test suite
npm test

# Run clarinet check for contract validation
clarinet check

# Run specific test file
npm test -- stellar-impact.test.ts
```

### Test Coverage Areas

- Project creation and validation
- Milestone management and verification thresholds
- Investment flows and token distribution
- Oracle registration and verification submission
- Fund release mechanisms upon milestone completion
- Status transitions and access control
- Insurance pool contributions and tracking
- Carbon credit registration and trading
- Governance voting mechanisms
- Impact Quotient calculations
- Edge cases and error handling
