#lang racket/base

(require "./mpd.rkt")
(require racket/match
         racket/async-channel
         net/rfc6455
         json)

(ws-idle-timeout 600)

(define clients 0)

(define mpd-channel (make-async-channel))
(define mpd-conn
  (mpd-connect (if (> (vector-length (current-command-line-arguments)) 1) (vector-ref (current-command-line-arguments) 1) "localhost")))

(define (resp-info)
  (hash 'current (mpd-currentsong mpd-conn) 'next (mpd-nextsong mpd-conn)))

(define mpd-worker
  (thread (λ ()
            (let loop ([previnfo #f])
              (unless (mpd-connection-alive? mpd-conn)
                (set! mpd-conn (mpd-connect)))
              (define currinfo (resp-info))
              (when (and (not (equal? previnfo currinfo))
                         (positive? clients))
                (displayln (format "mpd: updating info ~a" currinfo))
                (async-channel-put mpd-channel currinfo))
              (sleep 1)
              (loop currinfo)))))

(define (connection-handler c state)
  (define id (gensym 'conn))
  (displayln (format "~a: connection received" id))
  (set! clients (add1 clients))
  ; initial message
  (ws-send! c (jsexpr->bytes (resp-info)))
  (define worker
    (thread (λ ()
              (let loop ()
                (define mpd-info (async-channel-try-get mpd-channel))
                (when mpd-info
                  (ws-send! c (jsexpr->bytes mpd-info)))
                (sleep 1)
                (loop)))))
  (let loop ()
    (match (ws-recv c #:payload-type 'text)
      [(? eof-object?) (void)]
      ["ping"
       (displayln (format "~a: recv ping" id))
       (ws-send! c "pong")
       (loop)]))
  (displayln (format "~a: connection lost" id))
  (kill-thread worker)
  (ws-close! c)
  (set! clients (sub1 clients)))

(define stop-service
  (ws-serve #:port (string->number (vector-ref (current-command-line-arguments)
                                               0))
            connection-handler))
(printf "Server running. Hit enter to stop service.\n")
(void (read-line (current-input-port) 'any))
(stop-service)
