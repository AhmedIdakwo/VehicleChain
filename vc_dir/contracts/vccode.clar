;; Vehicle Registration with Record Management

;; Error codes
(define-constant ERROR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERROR-VEHICLE-EXISTS (err u101))
(define-constant ERROR-VEHICLE-NOT-FOUND (err u102))
(define-constant ERROR-RECORD-LIMIT-EXCEEDED (err u103))

;; Constants
(define-constant MAX-RECORDS u5)

;; Data Maps
(define-map registered-vehicles
    principal
    {
        vehicle-hash: (buff 32),
        registration-timestamp: uint,
        vehicle-records: (list 5 (buff 32))
    }
)

(define-map record-details
    (buff 32)  ;; record hash
    {
        record-type: (string-utf8 32),
        issuance-timestamp: uint,
        record-data: (buff 64)
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
                registration-timestamp: block-height,
                vehicle-records: (list)
            }
        ))
    )
)

(define-public (add-vehicle-record 
    (record-hash (buff 32))
    (record-type (string-utf8 32))
    (record-data (buff 64)))
    (let
        ((current-user tx-sender)
         (vehicle-record (unwrap! (map-get? registered-vehicles current-user) ERROR-VEHICLE-NOT-FOUND)))
        (asserts! 
            (< (len (get vehicle-records vehicle-record)) MAX-RECORDS) 
            ERROR-RECORD-LIMIT-EXCEEDED
        )
        (map-set record-details
            record-hash
            {
                record-type: record-type,
                issuance-timestamp: block-height,
                record-data: record-data
            }
        )
        (ok (map-set registered-vehicles
            current-user
            (merge vehicle-record
                {vehicle-records: (unwrap! 
                    (as-max-len? 
                        (append (get vehicle-records vehicle-record) record-hash) 
                        MAX-RECORDS
                    ) ERROR-RECORD-LIMIT-EXCEEDED)
                }
            )
        ))
    )
)

(define-read-only (get-vehicle-details (owner-principal principal))
    (map-get? registered-vehicles owner-principal)
)

(define-read-only (get-record-details (record-hash (buff 32)))
    (map-get? record-details record-hash)
)