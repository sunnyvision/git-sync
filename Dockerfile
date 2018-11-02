FROM alpine:latest

# please consult github.com/sunnyvision/git-sync

VOLUME ["/git"]

# basic apk we requires

RUN apk add --update git ca-certificates openssh-client

# add our script and chmod

ADD sync.sh /sync.sh

RUN chmod +x /sync.sh

CMD ["/bin/sh", "/sync.sh"]