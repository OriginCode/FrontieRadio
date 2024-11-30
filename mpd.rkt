#lang racket/base

(provide mpd-connection?
         mpd-connect
         mpd-close-connection
         mpd-currentsong)
 
(require racket/contract
         racket/tcp
         racket/async-channel
         racket/string
         racket/match)

(module+ test
  (require rackunit))

(struct mpd-connection (in-port out-port))

(define/contract (mpd-connect [hostname "localhost"] [port 6600])
  (->* () (string? port-number?) mpd-connection?)
  (define-values (in-port out-port) (tcp-connect hostname port))
  (read-line in-port)
  (file-stream-buffer-mode out-port 'line)
  (mpd-connection in-port out-port))

(define/contract (mpd-close-connection connection)
  (-> mpd-connection? void?)
  (close-input-port (mpd-connection-in-port connection))
  (close-output-port (mpd-connection-out-port connection)))

(define/contract (mpd-parse-response lines)
  (-> (listof string?) (hash/c symbol? string?))
  (make-hash
   (for/list ([line lines])
    (match line
      [(regexp #rx"^(.+): (.+)$" (list _ key val))
       (cons (string->symbol key) val)]
      [_ (error 'mpd-parse-response "failed to parse response from MPD")]))))

(define/contract (mpd-fetch-response connection lines)
  (-> mpd-connection? (listof string?) (hash/c symbol? string?))
  (define line (read-line (mpd-connection-in-port connection)))
  (match line
    ["OK" (mpd-parse-response lines)]
    [(regexp #rx"^ACK (.*)" (list _ errmsg)) (error 'mpd-fetch-response errmsg)]
    [_ (mpd-fetch-response connection (cons line lines))]))

(define/contract (mpd-command connection command)
  (-> mpd-connection? string? (hash/c symbol? string?))
  (fprintf (mpd-connection-out-port connection)
           "~a\r\n"
           command)
  (mpd-fetch-response connection (list)))

(define/contract (mpd-currentsong connection)
  (-> mpd-connection? (hash/c symbol? string?))
  (mpd-command connection "currentsong"))

(module+ test
  (define conn (mpd-connect))
  (check-not-exn (λ () (mpd-currentsong conn))))
