#lang racket/base

(require "./mpd.rkt")
(require racket/match
         net/rfc6455
         json)

(define mpd-conn (mpd-connect))

(define (connection-handler c state)
  (displayln "connection received")
  (let loop ([previnfo #f])
    (define currinfo
      (hash 'current (mpd-currentsong mpd-conn) 'next (mpd-nextsong mpd-conn)))
    (if (equal? previnfo currinfo)
        (loop currinfo)
        (ws-send! c (jsexpr->bytes currinfo)))
    (sleep 5)
    (loop currinfo)))

(define stop-service
  (ws-serve #:port (string->number (vector-ref (current-command-line-arguments)
                                               0))
            connection-handler))
(printf "Server running. Hit enter to stop service.\n")
(void (read-line))
(stop-service)
(mpd-close-connection mpd-conn)
