;; Stellar Impact - Decentralized Social Impact Platform
;; A blockchain-based platform for transparent impact investing with autonomous outcome verification

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-project-inactive (err u106))
(define-constant err-milestone-incomplete (err u107))
(define-constant err-invalid-verification (err u108))
(define-constant err-invalid-status (err u109))
(define-constant err-voting-closed (err u110))
(define-constant err-already-voted (err u111))
(define-constant err-invalid-score (err u112))

;; Token constants
(define-constant impact-token-decimals u6)
(define-constant outcome-token-decimals u6)

;; Project status constants
(define-constant status-proposed u0)
(define-constant status-active u1)
(define-constant status-paused u2)
(define-constant status-completed u3)
(define-constant status-cancelled u4)

;; Data Variables
(define-data-var project-nonce uint u0)
(define-data-var milestone-nonce uint u0)
(define-data-var oracle-nonce uint u0)
(define-data-var impact-quotient-threshold uint u70)
(define-data-var min-verification-score uint u80)

;; Data Maps

;; Projects mapping
(define-map projects
    { project-id: uint }
    {
        creator: principal,
        name: (string-ascii 100),
        description: (string-utf8 500),
        category: (string-ascii 50),
        total-funding-goal: uint,
        total-raised: uint,
        impact-quotient: uint,
        status: uint,
        created-at: uint,
        updated-at: uint,
        verified-outcomes: uint
    }
)

;; Milestones mapping
(define-map milestones
    { milestone-id: uint }
    {
        project-id: uint,
        description: (string-utf8 300),
        funding-amount: uint,
        verification-threshold: uint,
        is-completed: bool,
        is-verified: bool,
        verification-score: uint,
        completed-at: (optional uint)
    }
)

;; Investments mapping
(define-map investments
    { investor: principal, project-id: uint }
    {
        amount-stx: uint,
        impact-tokens: uint,
        outcome-tokens: uint,
        invested-at: uint
    }
)

;; Oracle verifiers mapping
(define-map oracle-verifiers
    { oracle-id: uint }
    {
        verifier: principal,
        reputation-score: uint,
        total-verifications: uint,
        successful-verifications: uint,
        is-active: bool
    }
)

;; Verification records
(define-map verification-records
    { milestone-id: uint, oracle-id: uint }
    {
        verified: bool,
        score: uint,
        data-hash: (buff 32),
        verified-at: uint
    }
)

;; Governance votes
(define-map governance-votes
    { project-id: uint, voter: principal }
    {
        vote-weight: uint,
        vote-for: bool,
        voted-at: uint
    }
)

;; Impact insurance pools
(define-map insurance-pools
    { project-id: uint }
    {
        total-pool: uint,
        claimed-amount: uint,
        contributors: uint
    }
)

;; Carbon credit tracking
(define-map carbon-credits
    { project-id: uint }
    {
        total-credits: uint,
        credits-sold: uint,
        credit-price: uint,
        last-updated: uint
    }
)

;; Read-only functions

;; Get project details
(define-read-only (get-project (project-id uint))
    (map-get? projects { project-id: project-id })
)

;; Get milestone details
(define-read-only (get-milestone (milestone-id uint))
    (map-get? milestones { milestone-id: milestone-id })
)

;; Get investment details
(define-read-only (get-investment (investor principal) (project-id uint))
    (map-get? investments { investor: investor, project-id: project-id })
)

;; Get oracle verifier details
(define-read-only (get-oracle-verifier (oracle-id uint))
    (map-get? oracle-verifiers { oracle-id: oracle-id })
)

;; Get verification record
(define-read-only (get-verification-record (milestone-id uint) (oracle-id uint))
    (map-get? verification-records { milestone-id: milestone-id, oracle-id: oracle-id })
)

;; Calculate impact quotient
(define-read-only (calculate-impact-quotient (verification-reliability uint) (benefit-scale uint) (sustainability-score uint))
    (let
        (
            (weighted-sum (+ (* verification-reliability u40) (* benefit-scale u35) (* sustainability-score u25)))
            (quotient (/ weighted-sum u100))
        )
        (ok quotient)
    )
)

;; Get project funding progress
(define-read-only (get-funding-progress (project-id uint))
    (match (get-project project-id)
        project
        (let
            (
                (goal (get total-funding-goal project))
                (raised (get total-raised project))
            )
            (if (> goal u0)
                (ok (/ (* raised u100) goal))
                (err err-invalid-amount)
            )
        )
        (err err-not-found)
    )
)

;; Get carbon credits for project
(define-read-only (get-carbon-credits (project-id uint))
    (map-get? carbon-credits { project-id: project-id })
)

;; Get insurance pool details
(define-read-only (get-insurance-pool (project-id uint))
    (map-get? insurance-pools { project-id: project-id })
)

;; Public functions

;; Create a new impact project
(define-public (create-project
    (name (string-ascii 100))
    (description (string-utf8 500))
    (category (string-ascii 50))
    (funding-goal uint)
)
    (let
        (
            (project-id (+ (var-get project-nonce) u1))
            (current-time block-height)
        )
        (asserts! (> funding-goal u0) err-invalid-amount)

        (map-set projects
            { project-id: project-id }
            {
                creator: tx-sender,
                name: name,
                description: description,
                category: category,
                total-funding-goal: funding-goal,
                total-raised: u0,
                impact-quotient: u0,
                status: status-proposed,
                created-at: current-time,
                updated-at: current-time,
                verified-outcomes: u0
            }
        )

        (var-set project-nonce project-id)
        (ok project-id)
    )
)

;; Create milestone for project
(define-public (create-milestone
    (project-id uint)
    (description (string-utf8 300))
    (funding-amount uint)
    (verification-threshold uint)
)
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (milestone-id (+ (var-get milestone-nonce) u1))
        )
        (asserts! (is-eq (get creator project) tx-sender) err-unauthorized)
        (asserts! (> funding-amount u0) err-invalid-amount)
        (asserts! (<= verification-threshold u100) err-invalid-score)

        (map-set milestones
            { milestone-id: milestone-id }
            {
                project-id: project-id,
                description: description,
                funding-amount: funding-amount,
                verification-threshold: verification-threshold,
                is-completed: false,
                is-verified: false,
                verification-score: u0,
                completed-at: none
            }
        )

        (var-set milestone-nonce milestone-id)
        (ok milestone-id)
    )
)

;; Invest in project
(define-public (invest-in-project (project-id uint) (amount-stx uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (current-investment (default-to
                { amount-stx: u0, impact-tokens: u0, outcome-tokens: u0, invested-at: u0 }
                (get-investment tx-sender project-id)
            ))
            (impact-tokens (/ (* amount-stx u1000) u1)) ;; 1000 IMPACT per STX
            (current-time block-height)
        )
        (asserts! (is-eq (get status project) status-active) err-project-inactive)
        (asserts! (> amount-stx u0) err-invalid-amount)

        ;; Transfer STX to contract
        (try! (stx-transfer? amount-stx tx-sender (as-contract tx-sender)))

        ;; Update investment record
        (map-set investments
            { investor: tx-sender, project-id: project-id }
            {
                amount-stx: (+ (get amount-stx current-investment) amount-stx),
                impact-tokens: (+ (get impact-tokens current-investment) impact-tokens),
                outcome-tokens: (get outcome-tokens current-investment),
                invested-at: current-time
            }
        )

        ;; Update project total raised
        (map-set projects
            { project-id: project-id }
            (merge project { total-raised: (+ (get total-raised project) amount-stx), updated-at: current-time })
        )

        (ok { invested: amount-stx, impact-tokens: impact-tokens })
    )
)

;; Register as oracle verifier
(define-public (register-oracle)
    (let
        (
            (oracle-id (+ (var-get oracle-nonce) u1))
        )
        (map-set oracle-verifiers
            { oracle-id: oracle-id }
            {
                verifier: tx-sender,
                reputation-score: u50,
                total-verifications: u0,
                successful-verifications: u0,
                is-active: true
            }
        )

        (var-set oracle-nonce oracle-id)
        (ok oracle-id)
    )
)

;; Submit milestone verification
(define-public (submit-verification
    (milestone-id uint)
    (oracle-id uint)
    (verified bool)
    (score uint)
    (data-hash (buff 32))
)
    (let
        (
            (milestone (unwrap! (get-milestone milestone-id) err-not-found))
            (oracle (unwrap! (get-oracle-verifier oracle-id) err-not-found))
            (current-time block-height)
        )
        (asserts! (is-eq (get verifier oracle) tx-sender) err-unauthorized)
        (asserts! (get is-active oracle) err-unauthorized)
        (asserts! (<= score u100) err-invalid-score)

        ;; Record verification
        (map-set verification-records
            { milestone-id: milestone-id, oracle-id: oracle-id }
            {
                verified: verified,
                score: score,
                data-hash: data-hash,
                verified-at: current-time
            }
        )

        ;; Update oracle stats
        (map-set oracle-verifiers
            { oracle-id: oracle-id }
            (merge oracle {
                total-verifications: (+ (get total-verifications oracle) u1),
                successful-verifications: (if verified (+ (get successful-verifications oracle) u1) (get successful-verifications oracle))
            })
        )

        (ok true)
    )
)

;; Complete milestone and release funds
(define-public (complete-milestone (milestone-id uint))
    (let
        (
            (milestone (unwrap! (get-milestone milestone-id) err-not-found))
            (project (unwrap! (get-project (get project-id milestone)) err-not-found))
            (current-time block-height)
        )
        (asserts! (is-eq (get creator project) tx-sender) err-unauthorized)
        (asserts! (not (get is-completed milestone)) err-invalid-status)
        (asserts! (>= (get verification-score milestone) (get verification-threshold milestone)) err-milestone-incomplete)

        ;; Mark milestone as completed
        (map-set milestones
            { milestone-id: milestone-id }
            (merge milestone {
                is-completed: true,
                completed-at: (some current-time)
            })
        )

        ;; Release funds to project creator
        (try! (as-contract (stx-transfer? (get funding-amount milestone) tx-sender (get creator project))))

        ;; Update project verified outcomes
        (map-set projects
            { project-id: (get project-id milestone) }
            (merge project {
                verified-outcomes: (+ (get verified-outcomes project) u1),
                updated-at: current-time
            })
        )

        (ok true)
    )
)

;; Update project status
(define-public (update-project-status (project-id uint) (new-status uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (current-time block-height)
        )
        (asserts! (is-eq (get creator project) tx-sender) err-unauthorized)
        (asserts! (<= new-status status-cancelled) err-invalid-status)

        (map-set projects
            { project-id: project-id }
            (merge project { status: new-status, updated-at: current-time })
        )

        (ok true)
    )
)

;; Contribute to insurance pool
(define-public (contribute-to-insurance (project-id uint) (amount uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (current-pool (default-to
                { total-pool: u0, claimed-amount: u0, contributors: u0 }
                (get-insurance-pool project-id)
            ))
        )
        (asserts! (> amount u0) err-invalid-amount)

        ;; Transfer STX to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

        ;; Update insurance pool
        (map-set insurance-pools
            { project-id: project-id }
            {
                total-pool: (+ (get total-pool current-pool) amount),
                claimed-amount: (get claimed-amount current-pool),
                contributors: (+ (get contributors current-pool) u1)
            }
        )

        (ok true)
    )
)

;; Register carbon credits for environmental projects
(define-public (register-carbon-credits (project-id uint) (credits uint) (price-per-credit uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (current-time block-height)
        )
        (asserts! (is-eq (get creator project) tx-sender) err-unauthorized)
        (asserts! (> credits u0) err-invalid-amount)

        (map-set carbon-credits
            { project-id: project-id }
            {
                total-credits: credits,
                credits-sold: u0,
                credit-price: price-per-credit,
                last-updated: current-time
            }
        )

        (ok true)
    )
)

;; Purchase carbon credits
(define-public (purchase-carbon-credits (project-id uint) (credit-amount uint))
    (let
        (
            (credits (unwrap! (get-carbon-credits project-id) err-not-found))
            (project (unwrap! (get-project project-id) err-not-found))
            (available-credits (- (get total-credits credits) (get credits-sold credits)))
            (total-cost (* credit-amount (get credit-price credits)))
        )
        (asserts! (<= credit-amount available-credits) err-insufficient-funds)
        (asserts! (> credit-amount u0) err-invalid-amount)

        ;; Transfer payment to project creator
        (try! (stx-transfer? total-cost tx-sender (get creator project)))

        ;; Update carbon credits
        (map-set carbon-credits
            { project-id: project-id }
            (merge credits { credits-sold: (+ (get credits-sold credits) credit-amount) })
        )

        (ok { credits-purchased: credit-amount, total-cost: total-cost })
    )
)

;; Cast governance vote
(define-public (cast-vote (project-id uint) (vote-for bool) (vote-weight uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (existing-vote (get-governance-vote project-id tx-sender))
            (current-time block-height)
        )
        (asserts! (is-none existing-vote) err-already-voted)
        (asserts! (is-eq (get status project) status-proposed) err-voting-closed)

        (map-set governance-votes
            { project-id: project-id, voter: tx-sender }
            {
                vote-weight: vote-weight,
                vote-for: vote-for,
                voted-at: current-time
            }
        )

        (ok true)
    )
)

;; Get governance vote
(define-read-only (get-governance-vote (project-id uint) (voter principal))
    (map-get? governance-votes { project-id: project-id, voter: voter })
)

;; Update impact quotient for project
(define-public (update-impact-quotient (project-id uint) (new-quotient uint))
    (let
        (
            (project (unwrap! (get-project project-id) err-not-found))
            (current-time block-height)
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-quotient u100) err-invalid-score)

        (map-set projects
            { project-id: project-id }
            (merge project { impact-quotient: new-quotient, updated-at: current-time })
        )

        (ok true)
    )
)

;; Admin function to update thresholds
(define-public (update-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-threshold u100) err-invalid-score)
        (var-set impact-quotient-threshold new-threshold)
        (ok true)
    )
)