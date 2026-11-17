package server

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/peer"
	"google.golang.org/grpc/status"
)

func TestAuthenticate(t *testing.T) {
	cert := &x509.Certificate{Subject: pkix.Name{CommonName: "root"}}
	for name, ctx := range map[string]context.Context{
		"missing peer": context.Background(),
		"missing TLS":  peer.NewContext(context.Background(), &peer.Peer{}),
		"unverified certificate": peer.NewContext(context.Background(), &peer.Peer{
			AuthInfo: credentials.TLSInfo{State: tls.ConnectionState{
				PeerCertificates: []*x509.Certificate{cert},
			}},
		}),
	} {
		t.Run(name, func(t *testing.T) {
			_, err := authenticate(ctx)
			require.Equal(t, codes.Unauthenticated, status.Code(err))
		})
	}
	t.Run("verified certificate", func(t *testing.T) {
		ctx := peer.NewContext(context.Background(), &peer.Peer{
			AuthInfo: credentials.TLSInfo{State: tls.ConnectionState{
				VerifiedChains: [][]*x509.Certificate{{cert}},
			}},
		})
		ctx, err := authenticate(ctx)
		require.NoError(t, err)
		require.Equal(t, "root", ctx.Value(subjectContextKey{}))
	})
}
