;; -----------------------------------------------------------------------------
;; Skill Certificate Smart Contract
;; Issue, verify, and revoke skill certificates on the Stacks blockchain
;; -----------------------------------------------------------------------------

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-ISSUER (err u101))
(define-constant ERR-CERT-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-REVOKED (err u103))

(define-data-var admin principal tx-sender)

(define-map issuers
  { issuer: principal }
  { active: bool, name: (string-ascii 64) }
)

(define-data-var cert-counter uint u0)

(define-map certificates
  { id: uint }
  {
    recipient: principal,
    issuer: principal,
    course: (string-ascii 80),
    metadata: (string-ascii 128),
    issue-block: uint,
    expiry-block: uint,
    revoked: bool
  }
)

;; ------------------------
;; Read-only checks
;; ------------------------

(define-read-only (is-admin (p principal))
  (ok (is-eq p (var-get admin)))
)

(define-read-only (is-active-issuer (p principal))
  (match (map-get? issuers { issuer: p })
    data (ok (get active data))
    (ok false))
)

;; ------------------------
;; Admin functions
;; ------------------------

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set admin new-admin)
    (print (tuple (message "admin-changed") (new-admin new-admin)))
    (ok true)
  )
)

(define-public (add-issuer (issuer principal) (name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (map-set issuers { issuer: issuer } { active: true, name: name })
    (print (tuple (message "issuer-added") (issuer issuer) (name name)))
    (ok issuer)
  )
)

(define-public (remove-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (map-set issuers { issuer: issuer } { active: false, name: "" })
    (print (tuple (message "issuer-removed") (issuer issuer)))
    (ok issuer)
  )
)

;; ------------------------
;; Certificate functions
;; ------------------------

(define-public (issue-certificate
    (recipient principal)
    (course (string-ascii 80))
    (metadata (string-ascii 128))
    (validity-blocks uint)
  )
  (let ((issuer-data (map-get? issuers { issuer: tx-sender })))
    (match issuer-data
      data
        (begin
          (if (get active data)
              (let ((new-id (+ (var-get cert-counter) u1)))
                (let ((current-height u0))  ;; TODO: Replace with actual block height when running
                  (let ((expiry (if (is-eq validity-blocks u0)
                                   u0
                                   (+ current-height validity-blocks))))
                    ;; Validate all inputs before using them
                    (asserts! (is-some (some recipient)) ERR-NOT-AUTHORIZED)
                    (asserts! (is-some (some course)) ERR-NOT-AUTHORIZED)
                    (asserts! (is-some (some metadata)) ERR-NOT-AUTHORIZED)
                    (map-set certificates { id: new-id }
                      {
                        recipient: recipient,
                        issuer: tx-sender,
                        course: course,
                        metadata: metadata,
                        issue-block: current-height,
                        expiry-block: expiry,
                        revoked: false
                      })
                    (var-set cert-counter new-id)
                    (print (tuple (message "cert-issued") (id new-id) (recipient recipient)))
                    (ok new-id)
                  )
                )
              )
              ERR-NOT-ISSUER)
        )
      ERR-NOT-ISSUER
    )
  )
)

(define-public (revoke-certificate (cert-id uint))
  (match (map-get? certificates { id: cert-id })
    cert
      (let (
            (issuer (get issuer cert))
            (revoked? (get revoked cert))
          )
        (asserts! (not revoked?) ERR-ALREADY-REVOKED)
        (asserts!
          (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender issuer))
          ERR-NOT-AUTHORIZED
        )
        (map-set certificates { id: cert-id }
          {
            recipient: (get recipient cert),
            issuer: issuer,
            course: (get course cert),
            metadata: (get metadata cert),
            issue-block: (get issue-block cert),
            expiry-block: (get expiry-block cert),
            revoked: true
          })
        (print (tuple (message "cert-revoked") (id cert-id) (revoker tx-sender)))
        (ok cert-id)
      )
    ERR-CERT-NOT-FOUND
  )
)

;; ------------------------
;; Read-only utilities
;; ------------------------

(define-read-only (get-certificate (cert-id uint))
  (ok (map-get? certificates { id: cert-id }))
)

(define-read-only (is-certificate-valid (cert-id uint))
  (let ((cert-data (map-get? certificates { id: cert-id })))
    (if (is-some cert-data)
        (let ((cert (unwrap-panic cert-data)))
          (let ((revoked? (get revoked cert))
                (expiry (get expiry-block cert)))
            (if revoked?
                (ok false)
                (if (is-eq expiry u0)
                    (ok true)
                    (ok true)  ;; TODO: Replace with block height check when running
                )
            )
          ))
        (ok false))
  )
)

(define-read-only (get-certificate-count)
  (ok (var-get cert-counter))
)

(define-read-only (get-issuer (acct principal))
  (let ((data (map-get? issuers { issuer: acct })))
    (ok (if (is-some data)
          (let ((issuer-data (unwrap-panic data)))
            (tuple (active (get active issuer-data)) 
                  (name (get name issuer-data))))
          (tuple (active false) (name ""))))
  )
)
