#lang racket/base

(require racket/contract
         racket/tcp
         racket/async-channel
         racket/string)

(provide mpd-connection?
         mpd-connect
         mpd-close-connection
         mpd-connection-incoming
         mpd-currentsong)

(struct mpd-connection (in-port out-port in-channel))

(define/contract (mpd-connect [hostname "localhost"] [port 6600])
  (->* () (string? port-number?) mpd-connection?)
  (define-values (in-port out-port) (tcp-connect hostname port))
  (read-line in-port)
  (file-stream-buffer-mode out-port 'line)
  (define in-channel (make-async-channel))
  (define connection (mpd-connection in-port out-port in-channel))
  (define (fetch-response ls)
    (define line (read-line in-port))
    (if (equal? line "OK")
        ls
        (fetch-response (cons line ls))))
  (thread (λ ()
            (let loop ()
              (sync in-port)
              (async-channel-put in-channel (fetch-response (list)))
              (loop))))
  connection)

(define/contract (mpd-close-connection connection)
  (-> mpd-connection? void?)
  (close-input-port (mpd-connection-in-port connection))
  (close-output-port (mpd-connection-out-port connection)))

(define/contract (mpd-command connection command)
  (-> mpd-connection? string? void?)
  (fprintf (mpd-connection-out-port connection)
           "~a\r\n"
           command))

(define/contract (mpd-connection-incoming connection)
  (-> mpd-connection? async-channel?)
  (mpd-connection-in-channel connection))

(define/contract (mpd-currentsong connection)
  (-> mpd-connection? void?)
  (mpd-command connection "currentsong"))
