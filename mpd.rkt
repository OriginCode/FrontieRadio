#lang racket/base

(provide mpd-connection?
         mpd-connect
         mpd-close-connection
         mpd-currentsong
         mpd-playlistinfo
         mpd-nextsong)

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
  (-> (listof string?) (listof (hash/c symbol? (or/c string? number?))))
  ; Assume the output key-value pair is formatted and identical to each list
  ; item.
  (foldl
   (λ (x acc)
     (if (or (null? acc) (hash-has-key? (car acc) (car x)))
         (cons (hash (car x) (cdr x)) acc)
         (cons (hash-set (car acc) (car x) (cdr x)) (cdr acc))))
   (list)
   (for/list ([line lines])
     (match line
       [(regexp #rx"^(.+): (.+)$" (list _ key val))
        (cons (string->symbol key)
              (let ([num (string->number val)]) (if num num val)))]
       [_ (error 'mpd-parse-response "failed to parse response from MPD")]))))

(define/contract (mpd-fetch-response connection lines)
  (-> mpd-connection?
      (listof string?)
      (listof (hash/c symbol? (or/c string? number?))))
  (define line (read-line (mpd-connection-in-port connection)))
  (match line
    ["OK" (mpd-parse-response lines)]
    [(regexp #rx"^ACK (.*)" (list _ errmsg)) (error 'mpd-fetch-response errmsg)]
    [_ (mpd-fetch-response connection (cons line lines))]))

(define/contract (mpd-command connection command)
  (-> mpd-connection? string? (listof (hash/c symbol? (or/c string? number?))))
  (fprintf (mpd-connection-out-port connection) "~a\r\n" command)
  (mpd-fetch-response connection (list)))

(define/contract (mpd-currentsong connection)
  (-> mpd-connection? (hash/c symbol? (or/c string? number?)))
  (define currentsong (mpd-command connection "currentsong"))
  (if (null? currentsong)
      (hash)
      (car currentsong)))

(define/contract (mpd-playlistinfo connection [pos #f])
  (->* (mpd-connection?)
       (exact-nonnegative-integer?)
       (or/c (listof (hash/c symbol? (or/c string? number?)))
             (hash/c symbol? (or/c string? number?))))
  (if pos
      (let ([playlistinfo (mpd-command connection
                                       (format "playlistinfo ~a" pos))])
        (if (null? playlistinfo)
            (hash)
            (car playlistinfo)))
      (mpd-command connection "playlistinfo")))

(define/contract (mpd-status connection)
  (-> mpd-connection? (hash/c symbol? (or/c string? number?)))
  (car (mpd-command connection "status")))

(define/contract (mpd-nextsong connection)
  (-> mpd-connection? (hash/c symbol? (or/c string? number?)))
  (define status (mpd-status connection))
  (if (hash-has-key? status 'nextsong)
      (mpd-playlistinfo connection (hash-ref status 'nextsong))
      (hash)))

(module+ test
  (define conn (mpd-connect))
  (mpd-currentsong conn)
  (mpd-playlistinfo conn)
  (mpd-status conn)
  (mpd-nextsong conn)
  (check-not-exn (λ () (mpd-currentsong conn)))
  (check-not-exn (λ () (mpd-playlistinfo conn))))
