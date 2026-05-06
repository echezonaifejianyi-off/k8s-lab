FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY main.go .

RUN go mod init myapp && go build -o myapp .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/myapp .

EXPOSE 8080

CMD ["./myapp"]