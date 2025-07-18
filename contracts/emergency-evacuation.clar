;; Emergency Evacuation Contract
;; Manages safety protocols during disasters

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u200))
(define-constant ERR-EMERGENCY-NOT-FOUND (err u201))
(define-constant ERR-ALREADY-ACTIVE (err u202))
(define-constant ERR-NOT-ACTIVE (err u203))

;; Emergency Types
(define-constant EMERGENCY-FIRE u1)
(define-constant EMERGENCY-EARTHQUAKE u2)
(define-constant EMERGENCY-FLOOD u3)
(define-constant EMERGENCY-GAS-LEAK u4)
(define-constant EMERGENCY-SECURITY u5)
(define-constant EMERGENCY-MEDICAL u6)
(define-constant EMERGENCY-OTHER u7)

;; Emergency Status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-RESOLVED u2)
(define-constant STATUS-CANCELLED u3)

;; Data Variables
(define-data-var next-emergency-id uint u1)

;; Data Maps
(define-map emergencies
  { emergency-id: uint }
  {
    building-id: uint,
    emergency-type: uint,
    severity-level: uint,
    description: (string-ascii 200),
    reported-by: principal,
    reported-at: uint,
    status: uint,
    resolved-at: (optional uint),
    resolved-by: (optional principal)
  }
)

(define-map evacuation-routes
  { building-id: uint, route-id: uint }
  {
    route-name: (string-ascii 50),
    start-location: (string-ascii 50),
    end-location: (string-ascii 50),
    capacity: uint,
    estimated-time: uint,
    accessible: bool,
    currently-blocked: bool
  }
)

(define-map personnel-status
  { emergency-id: uint, person: principal }
  {
    status: (string-ascii 20),
    last-location: (string-ascii 50),
    evacuation-route: (optional uint),
    check-in-time: uint,
    safe: bool,
    needs-assistance: bool
  }
)

(define-map emergency-contacts
  { building-id: uint, contact-type: (string-ascii 20) }
  {
    contact-name: (string-ascii 50),
    phone-number: (string-ascii 20),
    email: (string-ascii 50),
    priority: uint,
    active: bool
  }
)

(define-map emergency-equipment
  { building-id: uint, equipment-id: uint }
  {
    equipment-type: (string-ascii 30),
    location: (string-ascii 50),
    last-inspected: uint,
    functional: bool,
    notes: (string-ascii 100)
  }
)

;; Public Functions

;; Declare emergency
(define-public (declare-emergency (building-id uint) (emergency-type uint) (severity-level uint) (description (string-ascii 200)))
  (let ((emergency-id (var-get next-emergency-id)))
    (asserts! (<= emergency-type EMERGENCY-OTHER) ERR-INVALID-INPUT)
    (asserts! (and (>= severity-level u1) (<= severity-level u5)) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)

    (map-set emergencies
      { emergency-id: emergency-id }
      {
        building-id: building-id,
        emergency-type: emergency-type,
        severity-level: severity-level,
        description: description,
        reported-by: tx-sender,
        reported-at: block-height,
        status: STATUS-ACTIVE,
        resolved-at: none,
        resolved-by: none
      }
    )

    (var-set next-emergency-id (+ emergency-id u1))
    (ok emergency-id)
  )
)

;; Register evacuation route
(define-public (register-evacuation-route (building-id uint) (route-id uint) (route-name (string-ascii 50)) (start-location (string-ascii 50)) (end-location (string-ascii 50)) (capacity uint) (estimated-time uint))
  (begin
    (asserts! (> (len route-name) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)

    (map-set evacuation-routes
      { building-id: building-id, route-id: route-id }
      {
        route-name: route-name,
        start-location: start-location,
        end-location: end-location,
        capacity: capacity,
        estimated-time: estimated-time,
        accessible: true,
        currently-blocked: false
      }
    )

    (ok true)
  )
)

;; Check in during emergency
(define-public (emergency-check-in (emergency-id uint) (current-location (string-ascii 50)) (safe bool) (needs-assistance bool))
  (let ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (is-eq (get status emergency) STATUS-ACTIVE) ERR-NOT-ACTIVE)

    (map-set personnel-status
      { emergency-id: emergency-id, person: tx-sender }
      {
        status: (if safe "SAFE" "UNSAFE"),
        last-location: current-location,
        evacuation-route: none,
        check-in-time: block-height,
        safe: safe,
        needs-assistance: needs-assistance
      }
    )

    (ok true)
  )
)

;; Assign evacuation route
(define-public (assign-evacuation-route (emergency-id uint) (person principal) (route-id uint))
  (let ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get reported-by emergency))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status emergency) STATUS-ACTIVE) ERR-NOT-ACTIVE)

    (match (map-get? personnel-status { emergency-id: emergency-id, person: person })
      current-status (map-set personnel-status
        { emergency-id: emergency-id, person: person }
        (merge current-status {
          evacuation-route: (some route-id)
        })
      )
      (map-set personnel-status
        { emergency-id: emergency-id, person: person }
        {
          status: "ASSIGNED_ROUTE",
          last-location: "UNKNOWN",
          evacuation-route: (some route-id),
          check-in-time: block-height,
          safe: false,
          needs-assistance: false
        }
      )
    )

    (ok true)
  )
)

;; Block evacuation route
(define-public (block-evacuation-route (building-id uint) (route-id uint) (blocked bool))
  (let ((route (unwrap! (map-get? evacuation-routes { building-id: building-id, route-id: route-id }) ERR-EMERGENCY-NOT-FOUND)))
    (map-set evacuation-routes
      { building-id: building-id, route-id: route-id }
      (merge route {
        currently-blocked: blocked
      })
    )

    (ok true)
  )
)

;; Add emergency contact
(define-public (add-emergency-contact (building-id uint) (contact-type (string-ascii 20)) (contact-name (string-ascii 50)) (phone-number (string-ascii 20)) (email (string-ascii 50)) (priority uint))
  (begin
    (asserts! (> (len contact-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len phone-number) u0) ERR-INVALID-INPUT)

    (map-set emergency-contacts
      { building-id: building-id, contact-type: contact-type }
      {
        contact-name: contact-name,
        phone-number: phone-number,
        email: email,
        priority: priority,
        active: true
      }
    )

    (ok true)
  )
)

;; Register emergency equipment
(define-public (register-emergency-equipment (building-id uint) (equipment-id uint) (equipment-type (string-ascii 30)) (location (string-ascii 50)))
  (begin
    (asserts! (> (len equipment-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)

    (map-set emergency-equipment
      { building-id: building-id, equipment-id: equipment-id }
      {
        equipment-type: equipment-type,
        location: location,
        last-inspected: block-height,
        functional: true,
        notes: ""
      }
    )

    (ok true)
  )
)

;; Resolve emergency
(define-public (resolve-emergency (emergency-id uint))
  (let ((emergency (unwrap! (map-get? emergencies { emergency-id: emergency-id }) ERR-EMERGENCY-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get reported-by emergency))) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status emergency) STATUS-ACTIVE) ERR-NOT-ACTIVE)

    (map-set emergencies
      { emergency-id: emergency-id }
      (merge emergency {
        status: STATUS-RESOLVED,
        resolved-at: (some block-height),
        resolved-by: (some tx-sender)
      })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get emergency information
(define-read-only (get-emergency-info (emergency-id uint))
  (map-get? emergencies { emergency-id: emergency-id })
)

;; Get evacuation route
(define-read-only (get-evacuation-route (building-id uint) (route-id uint))
  (map-get? evacuation-routes { building-id: building-id, route-id: route-id })
)

;; Get personnel status
(define-read-only (get-personnel-status (emergency-id uint) (person principal))
  (map-get? personnel-status { emergency-id: emergency-id, person: person })
)

;; Get emergency contact
(define-read-only (get-emergency-contact (building-id uint) (contact-type (string-ascii 20)))
  (map-get? emergency-contacts { building-id: building-id, contact-type: contact-type })
)

;; Get emergency equipment
(define-read-only (get-emergency-equipment (building-id uint) (equipment-id uint))
  (map-get? emergency-equipment { building-id: building-id, equipment-id: equipment-id })
)

;; Check if emergency is active
(define-read-only (is-emergency-active (emergency-id uint))
  (match (map-get? emergencies { emergency-id: emergency-id })
    emergency (is-eq (get status emergency) STATUS-ACTIVE)
    false
  )
)

;; Get available evacuation routes
(define-read-only (get-available-routes (building-id uint))
  ;; This would require iteration in a real implementation
  ;; For now, return a placeholder indicating routes are available
  (ok true)
)

;; Private Functions

;; Calculate evacuation time estimate
(define-private (calculate-evacuation-time (route-capacity uint) (people-count uint) (base-time uint))
  (if (> people-count route-capacity)
    (* base-time u2)  ;; Double time if overcapacity
    base-time
  )
)

;; Determine emergency priority
(define-private (get-emergency-priority (emergency-type uint) (severity-level uint))
  (if (is-eq emergency-type EMERGENCY-FIRE)
    (+ severity-level u10)  ;; Fire gets highest priority
    severity-level
  )
)
