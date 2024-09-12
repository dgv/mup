FROM alpine:edge as build

RUN apk add --no-cache --update zig
WORKDIR /src/app
COPY . .
RUN zig build --release=small

FROM gcr.io/distroless/static-debian12
COPY --from=build /src/app/zig-out/bin/mup /
ENTRYPOINT [ "/mup" ]
