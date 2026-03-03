package application

const (
	StartCallCommandName       = "calls.start"
	EndCallCommandName         = "calls.end"
	ListCallHistoryCommandName = "calls.history"
)

type StartCallCommand struct {
	MatchID         string
	InitiatorUserID string
	RecipientUserID string
}

type EndCallCommand struct {
	CallID        string
	EndedByUserID string
}

type ListCallHistoryCommand struct {
	UserID string
	Limit  int
}
