FROM golang:1.16.8-alpine3.13 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build 
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o books


FROM scratch
COPY --from=builder /app/books /books
ENV DBURL=""
EXPOSE 8080
ENTRYPOINT ["/books"]
