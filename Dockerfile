# ---- Build stage ----
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o continuum-go main.go

# ---- Final stage ----
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/continuum-go .
RUN mkdir -p /root/static
EXPOSE 18517
CMD ["./continuum-go"]
