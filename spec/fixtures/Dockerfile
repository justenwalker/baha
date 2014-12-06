# Comment
FROM ubuntu:14.04.1

MAINTAINER "Captain Ahab" <ahab@example.com>

RUN echo "Hello"
RUN ["/bin/echo", "World"]
RUN echo Hello \
  world \
  multiline

ENTRYPOINT ["/bin/bash"]

EXPOSE 8080
EXPOSE 8081
EXPOSE 8009

ENV HOME /home/user
ENV BIN_DIR bin
ENV HOME2 $HOME/two
ENV USER daemon

WORKDIR ${HOME}
WORKDIR $BIN_DIR
WORKDIR b
WORKDIR c

CMD -l

USER ${USER}

VOLUME $HOME /logs
VOLUME ["$HOME/logs", "/data"]