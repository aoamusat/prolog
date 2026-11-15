package log_v1

import (
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestErrOffsetOutOfRange(t *testing.T) {
	err := ErrOffsetOutOfRange{Offset: 42}
	require.EqualError(t, err, "offset out of range: 42")
	s := status.Convert(err)
	require.Equal(t, codes.OutOfRange, s.Code())
	require.Equal(t, err.Error(), s.Message())
}
