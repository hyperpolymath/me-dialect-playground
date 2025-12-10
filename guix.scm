;; me-dialect-playground - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system cargo)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public me_dialect_playground
  (package
    (name "me-dialect-playground")
    (version "0.1.0")
    (source (local-file "." "me-dialect-playground-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system cargo-build-system)
    (synopsis "Rust application")
    (description "Rust application - part of the RSR ecosystem.")
    (home-page "https://github.com/hyperpolymath/me-dialect-playground")
    (license license:agpl3+)))

;; Return package for guix shell
me_dialect_playground
