package log_v1

import (
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// ErrOffsetOutOfRange indicates that the requested offset is not in the log.
type ErrOffsetOutOfRange struct {
	Offset uint64
}

var _ error = *new(ErrOffsetOutOfRange)

func (e ErrOffsetOutOfRange) Error() string {
	return fmt.Sprintf("offset out of range: %d", e.Offset)
}

func (e ErrOffsetOutOfRange) GRPCStatus() *status.Status {
	return status.New(codes.OutOfRange, e.Error())
}
