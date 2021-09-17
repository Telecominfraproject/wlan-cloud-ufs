FROM alpine AS builder

RUN apk add --update --no-cache \
    openssl openssh \
    ncurses-libs \
    bash util-linux coreutils curl \
    make cmake gcc g++ libstdc++ libgcc git zlib-dev \
    openssl-dev boost-dev curl-dev util-linux-dev \
    unixodbc-dev postgresql-dev mariadb-dev \
    librdkafka-dev

RUN git clone https://github.com/stephb9959/poco /poco
RUN git clone https://github.com/stephb9959/cppkafka /cppkafka
RUN git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp /aws-sdk-cpp

WORKDIR /aws-sdk-cpp
RUN mkdir cmake-build
WORKDIR cmake-build
RUN cmake .. -DBUILD_ONLY="s3" \
             -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_CXX_FLAGS="-Wno-error=stringop-overflow -Wno-error=uninitialized" \ 
             -DAUTORUN_UNIT_TESTS=OFF
RUN cmake --build . --config Release -j8
RUN cmake --build . --target install

WORKDIR /cppkafka
RUN mkdir cmake-build
WORKDIR cmake-build
RUN cmake ..
RUN cmake --build . --config Release -j8
RUN cmake --build . --target install

WORKDIR /poco
RUN mkdir cmake-build
WORKDIR cmake-build
RUN cmake ..
RUN cmake --build . --config Release -j8
RUN cmake --build . --target install

ADD CMakeLists.txt build /ucentralfms/
ADD cmake /ucentralfms/cmake
ADD src /ucentralfms/src

WORKDIR /ucentralfms
RUN mkdir cmake-build
WORKDIR /ucentralfms/cmake-build
RUN cmake ..
RUN cmake --build . --config Release -j8

FROM alpine

ENV UCENTRALFMS_USER=ucentralfms \
    UCENTRALFMS_ROOT=/ucentralfms-data \
    UCENTRALFMS_CONFIG=/ucentralfms-data

RUN addgroup -S "$UCENTRALFMS_USER" && \
    adduser -S -G "$UCENTRALFMS_USER" "$UCENTRALFMS_USER"

RUN mkdir /ucentral
RUN mkdir -p "$UCENTRALFMS_ROOT" "$UCENTRALFMS_CONFIG" && \
    chown "$UCENTRALFMS_USER": "$UCENTRALFMS_ROOT" "$UCENTRALFMS_CONFIG"
RUN apk add --update --no-cache librdkafka curl-dev mariadb-connector-c libpq unixodbc su-exec gettext ca-certificates

COPY --from=builder /ucentralfms/cmake-build/ucentralfms /ucentral/ucentralfms
COPY --from=builder /cppkafka/cmake-build/src/lib/* /lib/
COPY --from=builder /poco/cmake-build/lib/* /lib/
COPY --from=builder /aws-sdk-cpp/cmake-build/aws-cpp-sdk-core/libaws-cpp-sdk-core.so /lib/
COPY --from=builder /aws-sdk-cpp/cmake-build/aws-cpp-sdk-s3/libaws-cpp-sdk-s3.so /lib/

COPY ucentralfms.properties.tmpl ${UCENTRALFMS_CONFIG}/
COPY docker-entrypoint.sh /

EXPOSE 16004 17004 16104

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/ucentral/ucentralfms"]
