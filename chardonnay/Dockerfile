FROM ubuntu:latest as setup
WORKDIR ~
COPY ./scripts/setup.sh .
RUN chmod u+x setup.sh
RUN ./setup.sh

FROM rust:latest as steward_build
COPY ./scripts/steward_build.sh .
#RUN ./steward_build.sh

#FROM setup as binaries
#COPY ./scripts/binaries.sh .
#RUN ./binaries.sh

#FROM ubuntu:latest as configure
#WORKDIR ~
#COPY --from=steward_build /usr/bin/steward /usr/bin/steward
#COPY --from=binaries /usr/bin/gorc /usr/bin/gorc
#COPY --from=binaries /usr/bin/sommelier /usr/bin/sommelier
