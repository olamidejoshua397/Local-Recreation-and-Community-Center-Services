;; Recreation Center Equipment Rental Contract
;; Handles equipment inventory, rentals, and maintenance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-EQUIPMENT-NOT-FOUND (err u301))
(define-constant ERR-EQUIPMENT-UNAVAILABLE (err u302))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u303))
(define-constant ERR-RENTAL-NOT-FOUND (err u304))
(define-constant ERR-INVALID-DURATION (err u305))
(define-constant ERR-EQUIPMENT-DAMAGED (err u306))
(define-constant ERR-OVERDUE-RENTAL (err u307))

;; Equipment categories
(define-constant CATEGORY-SPORTS u1)
(define-constant CATEGORY-FITNESS u2)
(define-constant CATEGORY-AQUATIC u3)
(define-constant CATEGORY-OUTDOOR u4)
(define-constant CATEGORY-AUDIO-VISUAL u5)

;; Equipment conditions
(define-constant CONDITION-EXCELLENT u1)
(define-constant CONDITION-GOOD u2)
(define-constant CONDITION-FAIR u3)
(define-constant CONDITION-POOR u4)
(define-constant CONDITION-MAINTENANCE u5)

;; Rental durations (in blocks)
(define-constant HOURLY-RENTAL u144)     ;; 1 hour
(define-constant DAILY-RENTAL u4320)     ;; 1 day
(define-constant WEEKLY-RENTAL u30240)   ;; 1 week
(define-constant MAX-RENTAL-DURATION u120960) ;; 1 month

;; Security deposits (in microSTX)
(define-constant SPORTS-DEPOSIT u5000000)      ;; 5 STX
(define-constant FITNESS-DEPOSIT u10000000)    ;; 10 STX
(define-constant AQUATIC-DEPOSIT u3000000)     ;; 3 STX
(define-constant OUTDOOR-DEPOSIT u15000000)    ;; 15 STX
(define-constant AV-DEPOSIT u20000000)         ;; 20 STX

;; Data structures
(define-map equipment-inventory
  { equipment-id: uint }
  {
    name: (string-ascii 50),
    category: uint,
    condition: uint,
    hourly-rate: uint,
    daily-rate: uint,
    weekly-rate: uint,
    security-deposit: uint,
    available: bool,
    last-maintenance: uint,
    next-maintenance: uint,
    total-rentals: uint,
    description: (string-ascii 200)
  }
)

(define-map equipment-rentals
  { rental-id: uint }
  {
    equipment-id: uint,
    renter: principal,
    start-time: uint,
    duration: uint,
    rental-type: uint, ;; 1=hourly, 2=daily, 3=weekly
    total-cost: uint,
    security-deposit: uint,
    status: (string-ascii 15),
    return-condition: (optional uint),
    damage-report: (optional (string-ascii 300)),
    created-at: uint
  }
)

(define-map equipment-maintenance
  { equipment-id: uint, maintenance-id: uint }
  {
    maintenance-type: (string-ascii 50),
    scheduled-date: uint,
    completed-date: (optional uint),
    cost: uint,
    notes: (string-ascii 300),
    technician: (optional principal)
  }
)

(define-map damage-reports
  { report-id: uint }
  {
    equipment-id: uint,
    rental-id: uint,
    reporter: principal,
    damage-description: (string-ascii 300),
    severity: uint, ;; 1=minor, 2=moderate, 3=major, 4=total-loss
    repair-cost: uint,
    reported-at: uint,
    resolved: bool
  }
)

;; Data variables
(define-data-var next-equipment-id uint u1)
(define-data-var next-rental-id uint u1)
(define-data-var next-maintenance-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var total-rental-revenue uint u0)
(define-data-var total-deposits-held uint u0)

;; Private functions
(define-private (get-category-deposit (category uint))
  (if (is-eq category CATEGORY-SPORTS)
    SPORTS-DEPOSIT
    (if (is-eq category CATEGORY-FITNESS)
      FITNESS-DEPOSIT
      (if (is-eq category CATEGORY-AQUATIC)
        AQUATIC-DEPOSIT
        (if (is-eq category CATEGORY-OUTDOOR)
          OUTDOOR-DEPOSIT
          (if (is-eq category CATEGORY-AUDIO-VISUAL)
            AV-DEPOSIT
            u0
          )
        )
      )
    )
  )
)

(define-private (calculate-rental-cost (equipment-data (tuple (name (string-ascii 50)) (category uint) (condition uint) (hourly-rate uint) (daily-rate uint) (weekly-rate uint) (security-deposit uint) (available bool) (last-maintenance uint) (next-maintenance uint) (total-rentals uint) (description (string-ascii 200)))) (duration uint) (rental-type uint))
  (if (is-eq rental-type u1) ;; Hourly
    (* (get hourly-rate equipment-data) (/ duration HOURLY-RENTAL))
    (if (is-eq rental-type u2) ;; Daily
      (* (get daily-rate equipment-data) (/ duration DAILY-RENTAL))
      (if (is-eq rental-type u3) ;; Weekly
        (* (get weekly-rate equipment-data) (/ duration WEEKLY-RENTAL))
        u0
      )
    )
  )
)

(define-private (apply-member-discount (base-cost uint) (member-tier uint))
  (let (
    (discount-rate (if (is-eq member-tier u1)
      u5  ;; 5% for basic
      (if (is-eq member-tier u2)
        u15 ;; 15% for premium
        (if (is-eq member-tier u3)
          u10 ;; 10% for family
          u0
        )
      )
    ))
  )
    (- base-cost (/ (* base-cost discount-rate) u100))
  )
)

;; Public functions

;; Add equipment to inventory (admin only)
(define-public (add-equipment
  (name (string-ascii 50))
  (category uint)
  (hourly-rate uint)
  (daily-rate uint)
  (weekly-rate uint)
  (description (string-ascii 200))
)
  (let (
    (equipment-id (var-get next-equipment-id))
    (security-deposit (get-category-deposit category))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (> category u0) (<= category u5)) ERR-EQUIPMENT-NOT-FOUND)

    (map-set equipment-inventory
      { equipment-id: equipment-id }
      {
        name: name,
        category: category,
        condition: CONDITION-EXCELLENT,
        hourly-rate: hourly-rate,
        daily-rate: daily-rate,
        weekly-rate: weekly-rate,
        security-deposit: security-deposit,
        available: true,
        last-maintenance: block-height,
        next-maintenance: (+ block-height u43200), ;; 300 days
        total-rentals: u0,
        description: description
      }
    )

    (var-set next-equipment-id (+ equipment-id u1))
    (ok equipment-id)
  )
)

;; Rent equipment
(define-public (rent-equipment
  (equipment-id uint)
  (duration uint)
  (rental-type uint)
  (member-tier uint)
)
  (let (
    (rental-id (var-get next-rental-id))
    (equipment-data (unwrap! (map-get? equipment-inventory { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
    (base-cost (calculate-rental-cost equipment-data duration rental-type))
    (final-cost (if (> member-tier u0)
      (apply-member-discount base-cost member-tier)
      base-cost
    ))
    (security-deposit (get security-deposit equipment-data))
    (total-payment (+ final-cost security-deposit))
    (renter tx-sender)
  )
    ;; Validate rental request
    (asserts! (get available equipment-data) ERR-EQUIPMENT-UNAVAILABLE)
    (asserts! (>= (get condition equipment-data) CONDITION-FAIR) ERR-EQUIPMENT-DAMAGED)
    (asserts! (and (> duration u0) (<= duration MAX-RENTAL-DURATION)) ERR-INVALID-DURATION)
    (asserts! (and (> rental-type u0) (<= rental-type u3)) ERR-INVALID-DURATION)

    ;; Process payment (rental cost + security deposit)
    (try! (stx-transfer? total-payment tx-sender (as-contract tx-sender)))

    ;; Create rental record
    (map-set equipment-rentals
      { rental-id: rental-id }
      {
        equipment-id: equipment-id,
        renter: renter,
        start-time: block-height,
        duration: duration,
        rental-type: rental-type,
        total-cost: final-cost,
        security-deposit: security-deposit,
        status: "active",
        return-condition: none,
        damage-report: none,
        created-at: block-height
      }
    )

    ;; Mark equipment as unavailable
    (map-set equipment-inventory
      { equipment-id: equipment-id }
      (merge equipment-data {
        available: false,
        total-rentals: (+ (get total-rentals equipment-data) u1)
      })
    )

    ;; Update financial tracking
    (var-set next-rental-id (+ rental-id u1))
    (var-set total-rental-revenue (+ (var-get total-rental-revenue) final-cost))
    (var-set total-deposits-held (+ (var-get total-deposits-held) security-deposit))

    (ok rental-id)
  )
)

;; Return equipment
(define-public (return-equipment
  (rental-id uint)
  (return-condition uint)
  (damage-notes (optional (string-ascii 300)))
)
  (let (
    (rental-data (unwrap! (map-get? equipment-rentals { rental-id: rental-id }) ERR-RENTAL-NOT-FOUND))
    (equipment-id (get equipment-id rental-data))
    (equipment-data (unwrap! (map-get? equipment-inventory { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
    (renter (get renter rental-data))
    (security-deposit (get security-deposit rental-data))
    (rental-end-time (+ (get start-time rental-data) (get duration rental-data)))
    (is-overdue (> block-height rental-end-time))
    (condition-penalty (if (< return-condition CONDITION-GOOD)
      (/ security-deposit u4) ;; 25% penalty for poor condition
      u0
    ))
    (overdue-penalty (if is-overdue
      (/ security-deposit u10) ;; 10% penalty for being overdue
      u0
    ))
    (total-penalties (+ condition-penalty overdue-penalty))
    (refund-amount (- security-deposit total-penalties))
  )
    ;; Validate return
    (asserts! (is-eq tx-sender renter) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status rental-data) "active") ERR-RENTAL-NOT-FOUND)
    (asserts! (and (> return-condition u0) (<= return-condition u5)) ERR-EQUIPMENT-DAMAGED)

    ;; Update rental record
    (map-set equipment-rentals
      { rental-id: rental-id }
      (merge rental-data {
        status: "returned",
        return-condition: (some return-condition),
        damage-report: damage-notes
      })
    )

    ;; Update equipment status
    (map-set equipment-inventory
      { equipment-id: equipment-id }
      (merge equipment-data {
        available: (>= return-condition CONDITION-FAIR),
        condition: return-condition
      })
    )

    ;; Process refund
    (if (> refund-amount u0)
      (try! (as-contract (stx-transfer? refund-amount tx-sender renter)))
      true
    )

    ;; Update deposits tracking
    (var-set total-deposits-held (- (var-get total-deposits-held) security-deposit))

    (ok refund-amount)
  )
)

;; Report equipment damage
(define-public (report-damage
  (equipment-id uint)
  (rental-id uint)
  (damage-description (string-ascii 300))
  (severity uint)
  (estimated-repair-cost uint)
)
  (let (
    (report-id (var-get next-report-id))
    (rental-data (unwrap! (map-get? equipment-rentals { rental-id: rental-id }) ERR-RENTAL-NOT-FOUND))
  )
    ;; Validate damage report
    (asserts! (is-eq (get equipment-id rental-data) equipment-id) ERR-EQUIPMENT-NOT-FOUND)
    (asserts! (and (> severity u0) (<= severity u4)) ERR-EQUIPMENT-DAMAGED)

    ;; Create damage report
    (map-set damage-reports
      { report-id: report-id }
      {
        equipment-id: equipment-id,
        rental-id: rental-id,
        reporter: tx-sender,
        damage-description: damage-description,
        severity: severity,
        repair-cost: estimated-repair-cost,
        reported-at: block-height,
        resolved: false
      }
    )

    ;; Update equipment condition based on severity
    (let (
      (equipment-data (unwrap! (map-get? equipment-inventory { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
      (new-condition (if (>= severity u3) CONDITION-MAINTENANCE CONDITION-POOR))
    )
      (map-set equipment-inventory
        { equipment-id: equipment-id }
        (merge equipment-data {
          condition: new-condition,
          available: false
        })
      )
    )

    (var-set next-report-id (+ report-id u1))
    (ok report-id)
  )
)

;; Schedule maintenance (admin only)
(define-public (schedule-maintenance
  (equipment-id uint)
  (maintenance-type (string-ascii 50))
  (scheduled-date uint)
  (estimated-cost uint)
  (notes (string-ascii 300))
)
  (let (
    (maintenance-id (var-get next-maintenance-id))
    (equipment-data (unwrap! (map-get? equipment-inventory { equipment-id: equipment-id }) ERR-EQUIPMENT-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set equipment-maintenance
      { equipment-id: equipment-id, maintenance-id: maintenance-id }
      {
        maintenance-type: maintenance-type,
        scheduled-date: scheduled-date,
        completed-date: none,
        cost: estimated-cost,
        notes: notes,
        technician: none
      }
    )

    ;; Mark equipment as unavailable for maintenance
    (map-set equipment-inventory
      { equipment-id: equipment-id }
      (merge equipment-data {
        available: false,
        condition: CONDITION-MAINTENANCE,
        next-maintenance: (+ scheduled-date u43200) ;; Next maintenance in 300 days
      })
    )

    (var-set next-maintenance-id (+ maintenance-id u1))
    (ok maintenance-id)
  )
)

;; Read-only functions

;; Get equipment details
(define-read-only (get-equipment (equipment-id uint))
  (map-get? equipment-inventory { equipment-id: equipment-id })
)

;; Get rental details
(define-read-only (get-rental (rental-id uint))
  (map-get? equipment-rentals { rental-id: rental-id })
)

;; Check equipment availability
(define-read-only (is-equipment-available (equipment-id uint))
  (match (map-get? equipment-inventory { equipment-id: equipment-id })
    equipment-data (and
      (get available equipment-data)
      (>= (get condition equipment-data) CONDITION-FAIR)
    )
    false
  )
)

;; Get available equipment by category
(define-read-only (get-available-equipment-by-category (category uint))
  ;; This would require additional indexing in a real implementation
  ;; For now, return a placeholder
  (list)
)

;; Calculate rental quote
(define-read-only (get-rental-quote
  (equipment-id uint)
  (duration uint)
  (rental-type uint)
  (member-tier uint)
)
  (match (map-get? equipment-inventory { equipment-id: equipment-id })
    equipment-data
      (let (
        (base-cost (calculate-rental-cost equipment-data duration rental-type))
        (final-cost (if (> member-tier u0)
          (apply-member-discount base-cost member-tier)
          base-cost
        ))
        (security-deposit (get security-deposit equipment-data))
      )
        (some {
          rental-cost: final-cost,
          security-deposit: security-deposit,
          total-payment: (+ final-cost security-deposit)
        })
      )
    none
  )
)

;; Get damage report
(define-read-only (get-damage-report (report-id uint))
  (map-get? damage-reports { report-id: report-id })
)

;; Get maintenance schedule
(define-read-only (get-maintenance-schedule (equipment-id uint) (maintenance-id uint))
  (map-get? equipment-maintenance { equipment-id: equipment-id, maintenance-id: maintenance-id })
)

;; Get overdue rentals (admin only)
(define-read-only (get-overdue-count)
  (if (is-eq tx-sender CONTRACT-OWNER)
    ;; This would require additional indexing in a real implementation
    (some u0)
    none
  )
)

;; Get total revenue (admin only)
(define-read-only (get-rental-revenue)
  (if (is-eq tx-sender CONTRACT-OWNER)
    (some (var-get total-rental-revenue))
    none
  )
)

;; Get total deposits held (admin only)
(define-read-only (get-deposits-held)
  (if (is-eq tx-sender CONTRACT-OWNER)
    (some (var-get total-deposits-held))
    none
  )
)
