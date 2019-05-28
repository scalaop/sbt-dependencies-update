FROM groovy:2.5.7-jre8-alpine

ADD sbt-update.conf /sbt-update.conf
ADD sbt-update-dependencies.sh /sbt-update-dependencies.sh

ENTRYPOINT /sbt-update-dependencies.sh