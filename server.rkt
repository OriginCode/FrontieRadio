#lang racket/base

(require "./mpd.rkt")
(require racket/match
         net/rfc6455
         json)

(ws-idle-timeout 6000)

(define mpd-channel (make-channel))
(define mpd-conn (mpd-connect))
(define mpd-worker
  (thread (λ ()
            (let loop ([previnfo #f])
              (define currinfo
                (hash 'current
                      (mpd-currentsong mpd-conn)
                      'next
                      (mpd-nextsong mpd-conn)))
              (when (not (equal? previnfo currinfo))
                (displayln (format "mpd: updating info ~a" currinfo))
                (channel-put mpd-channel currinfo))
              (sleep 1)
              (loop currinfo)))))

(define (connection-handler c state)
  (define id (gensym 'conn))
  (displayln (format "~a: connection received" id))
  ; initial message
  (ws-send! c
            (jsexpr->bytes
             (hash 'current
                   (mpd-currentsong mpd-conn)
                   'next
                   (mpd-nextsong mpd-conn))))
  (define worker
    (thread (λ ()
              (let loop ()
                (ws-send! c (jsexpr->bytes (sync mpd-channel)))
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
  (ws-close! c))

(define stop-service
  (ws-serve #:port (string->number (vector-ref (current-command-line-arguments)
                                               0))
            connection-handler))
(printf "Server running. Hit enter to stop service.\n")
(void (read-line))
(stop-service)
(kill-thread mpd-worker)
