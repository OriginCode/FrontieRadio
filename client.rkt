#lang racket/base

(require net/url
         net/rfc6455)

;(define server-url "ws://frontier.origincode.local:9000/")
(define server-url "ws://localhost:9000/")
;(define server-url "wss://radio-api.origincode.me/")

(define conn (ws-connect (string->url server-url)))
(thread (λ () (let loop ()
                   (ws-send! conn "ping")
                   (sleep 5)
                   (loop))))
(let loop ()
  (displayln (ws-recv conn #:payload-type 'text))
  (loop))
