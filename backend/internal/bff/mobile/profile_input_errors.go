package mobile

// photoOrderError is a photo_ids list that does not name each active photo
// exactly once. It is the caller's mistake, but as a plain error it was
// answered 502 "temporarily unavailable" (API-21).
type photoOrderError struct{ msg string }

func (e *photoOrderError) Error() string { return e.msg }
