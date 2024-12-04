#lang racket/base

(require net/url
         net/rfc6455)

(define conn (ws-connect (string->url "ws://127.0.0.1:8081/")))
(let loop ()
  (displayln (ws-recv conn #:payload-type 'text))
  (loop))
