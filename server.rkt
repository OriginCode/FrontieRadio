#lang racket/base

(require "./mpd.rkt")
(require racket/match
         net/rfc6455
         json)

(ws-idle-timeout 6000)

(define mpd-info #f)
(define mpd-conn (mpd-connect))
(define mpd-worker
  (thread (λ ()
            (let loop ()
              (define currinfo
                (hash 'current (mpd-currentsong mpd-conn)
                      'next (mpd-nextsong mpd-conn)))
              (when (not (equal? mpd-info currinfo))
                (set! mpd-info currinfo))
              (sleep 1)
              (loop)))))

(define (connection-handler c state)
  (define id (gensym 'conn))
  (displayln (format "~a: connection received" id))
  (define worker
    (thread (λ ()
              (let loop ([previnfo #f])
                (when (not (equal? previnfo mpd-info))
                  (ws-send! c (jsexpr->bytes mpd-info)))
                (sleep 1)
                (loop mpd-info)))))
  (let loop ()
    (match (ws-recv c #:payload-type 'text)
      [(? eof-object?) (void)]
      ["ping"
       (displayln (format "~a: recv ping" id))
       (ws-send! c "pong")
       (loop)]))
  (displayln (format "~a: connection lost" id))
  (kill-thread worker)
  (ws-close! c))

(define stop-service
  (ws-serve #:port (string->number (vector-ref (current-command-line-arguments)
                                               0))
            connection-handler))
(printf "Server running. Hit enter to stop service.\n")
(void (read-line))
(stop-service)
(kill-thread mpd-worker)
