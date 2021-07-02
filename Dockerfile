FROM swift:5.3

RUN apt-get update --assume-yes
RUN apt-get install --assume-yes libsqlite3-dev libncurses-dev
