package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	pb "proto-example/pb"
	"strings"

	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const (
	grpcAddress = 10000
	httpAddress = 9000
)

type server struct {
	pb.UnimplementedAuthServer
}

func (s *server) Login(ctx context.Context, in *pb.UserRequest) (*pb.UserResponse, error) {
	log.Printf("Received: %v", in.GetUsername())
	return &pb.UserResponse{AccessToken: "123"}, nil
}

func (s *server) GetUser(ctx context.Context, in *pb.GetUserRequest) (*pb.GetUserResponse, error) {
	return &pb.GetUserResponse{
		UserId: int64(1000),
	}, nil
}

func RunGRPCGateway() (err error) {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	mux := runtime.NewServeMux(runtime.WithMarshalerOption(runtime.MIMEWildcard, &runtime.JSONPb{OrigName: true, EmitDefaults: true}))
	opts := []grpc.DialOption{grpc.WithInsecure()}
	err = pb.RegisterAuthHandlerFromEndpoint(ctx, mux, fmt.Sprintf(":%d", grpcAddress), opts)
	if err != nil {
		return err
	}

	muxHttp := http.NewServeMux()
	muxHttp.Handle("/", forwardAccessToken(mux))

	return http.ListenAndServe(fmt.Sprintf(":%d", httpAddress), muxHttp)
}

func forwardAccessToken(next http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		md := make(metadata.MD)
		for k := range r.Header {
			k2 := strings.ToLower(k)
			md[k2] = []string{r.Header.Get(k)}
		}
		ctx := metadata.NewIncomingContext(r.Context(), md)
		r = r.WithContext(ctx)
		next.ServeHTTP(w, r)
	}
}

func main() {
	go func() {
		RunGRPCGateway()
	}()
	s := grpc.NewServer()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", grpcAddress))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	pb.RegisterAuthServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
