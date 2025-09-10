;; ArtisanVault - Creative arts and craftsmanship rewards platform
(define-data-var guild-master principal tx-sender)
(define-data-var total-craft-points uint u0)
(define-data-var artistry-multiplier uint u85) ;; multiplier per craft mastery level
(define-data-var last-showcase-event uint u0)

(define-map artisan-mastery principal uint)
(define-map craft-disciplines principal (string-utf8 64))
(define-map recognized-crafts (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-guild-master (err u5400))
(define-constant err-guild-master-already-set (err u5401))
(define-constant err-invalid-craft-points (err u5402))
(define-constant err-no-artistry-rewards (err u5403))
(define-constant err-no-artisan-mastery (err u5404))
(define-constant err-invalid-craft-discipline (err u5405))
(define-constant err-craft-not-recognized (err u5406))

;; Verify guild master authorization
(define-private (is-guild-master (caller principal))
  (begin
    (asserts! (is-eq caller (var-get guild-master)) err-unauthorized-guild-master)
    (ok true)))

;; Initialize artisan guild platform
(define-public (establish-artisan-guild (master principal))
  (begin
    (asserts! (is-none (map-get? artisan-mastery master)) err-guild-master-already-set)
    (var-set guild-master master)
    (ok "ArtisanVault creative guild platform established")))

;; Recognize craft discipline for mastery tracking
(define-public (recognize-craft-discipline (discipline (string-utf8 64)))
  (begin
    (try! (is-guild-master tx-sender))
    (asserts! (> (len discipline) u0) err-invalid-craft-discipline)
    (map-set recognized-crafts discipline true)
    (ok "Craft discipline recognized for mastery tracking")))

;; Record artisan craft progress
(define-public (record-craft-progress (craft-points uint) (discipline (string-utf8 64)))
  (begin
    (asserts! (> craft-points u0) err-invalid-craft-points)
    (asserts! (default-to false (map-get? recognized-crafts discipline)) err-craft-not-recognized)
    
    (let ((current-mastery (default-to u0 (map-get? artisan-mastery tx-sender))))
      (map-set artisan-mastery tx-sender (+ current-mastery craft-points))
      (map-set craft-disciplines tx-sender discipline)
      (var-set total-craft-points (+ (var-get total-craft-points) craft-points))
      (ok (+ current-mastery craft-points)))))

;; Host artistry showcase event
(define-public (host-artistry-showcase)
  (begin
    (try! (is-guild-master tx-sender))
    (let ((current-showcase (+ (var-get last-showcase-event) u1))
          (total-points (var-get total-craft-points)))
      (asserts! (> total-points (var-get last-showcase-event)) err-no-artistry-rewards)
      
      (let ((artistry-reward-pool (* (var-get artistry-multiplier) total-points)))
        (var-set last-showcase-event current-showcase)
        (ok artistry-reward-pool)))))

;; Complete master artisan certification and claim rewards
(define-public (complete-master-artisan-certification)
  (begin
    (let ((artisan-points (default-to u0 (map-get? artisan-mastery tx-sender))))
      (asserts! (> artisan-points u0) err-no-artisan-mastery)
      
      (let ((total-points (var-get total-craft-points))
            (base-artistry-rewards (* (var-get artistry-multiplier) artisan-points))
            (mastery-ratio (/ (* artisan-points u100000) total-points)))
        
        (let ((final-artistry-rewards (/ (* mastery-ratio base-artistry-rewards) u100000)))
          (map-delete artisan-mastery tx-sender)
          (map-delete craft-disciplines tx-sender)
          (var-set total-craft-points (- (var-get total-craft-points) artisan-points))
          (ok (+ artisan-points final-artistry-rewards)))))))

;; Read-only functions
(define-read-only (get-artisan-mastery (artisan principal))
  (default-to u0 (map-get? artisan-mastery artisan)))

(define-read-only (get-craft-discipline (artisan principal))
  (map-get? craft-disciplines artisan))

(define-read-only (get-total-craft-points)
  (var-get total-craft-points))

(define-read-only (is-craft-recognized (discipline (string-utf8 64)))
  (default-to false (map-get? recognized-crafts discipline)))
