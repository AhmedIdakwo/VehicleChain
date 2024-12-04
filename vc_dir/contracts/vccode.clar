;; Vehicle Registration Basic Implementation

;; Error codes
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERROR-VEHICLE-EXISTS (err u101))
(define-constant ERROR-VEHICLE-NOT-FOUND (err u102))

;; Data Maps
(define-map registered-vehicles
    principal
    {
        vehicle-hash: (buff 32),
        registration-timestamp: uint
    }
)

;; Public functions
(define-public (register-vehicle (vehicle-hash (buff 32)))
    (let
        ((current-user tx-sender))
        (asserts! (is-none (map-get? registered-vehicles current-user)) ERROR-VEHICLE-EXISTS)
        (ok (map-set registered-vehicles
            current-user
            {
                vehicle-hash: vehicle-hash,
                registration-timestamp: block-height
            }
        ))
    )
)

(define-read-only (get-vehicle-details (owner-principal principal))
    (map-get? registered-vehicles owner-principal)
)