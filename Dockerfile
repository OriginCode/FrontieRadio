FROM racket/racket
WORKDIR /app

RUN raco pkg install --auto -D rfc6455

COPY mpd.rkt server.rkt ./

EXPOSE 9000
ENTRYPOINT ["racket", "server.rkt", "9000", "172.17.0.1"]
