package application

const (
	ReportUserCommandName  = "safety.report"
	BlockUserCommandName   = "safety.block"
	UnblockUserCommandName = "safety.unblock"
	TriggerSOSCommandName  = "safety.sos.trigger"
	ListSOSCommandName     = "safety.sos.list"
	ResolveSOSCommandName  = "safety.sos.resolve"
)

type ReportUserCommand struct {
	ReporterUserID string
	ReportedUserID string
	Reason         string
	Description    string
}

type BlockUserCommand struct {
	UserID        string
	BlockedUserID string
}

type UnblockUserCommand struct {
	UserID        string
	BlockedUserID string
}

type TriggerSOSCommand struct {
	UserID         string
	MatchID        string
	EmergencyLevel string
	Message        string
	Latitude       float64
	Longitude      float64
}

type ListSOSCommand struct {
	UserID string
	Limit  int
}

type ResolveSOSCommand struct {
	AlertID        string
	ResolvedBy     string
	ResolutionNote string
}
