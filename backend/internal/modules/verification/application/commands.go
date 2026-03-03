package application

const (
	GetVerificationCommandName     = "verification.get"
	SubmitVerificationCommandName  = "verification.submit"
	ListVerificationsCommandName   = "verification.admin.list"
	ApproveVerificationCommandName = "verification.admin.approve"
	RejectVerificationCommandName  = "verification.admin.reject"
)

type GetVerificationCommand struct {
	UserID string
}

type SubmitVerificationCommand struct {
	UserID string
}

type ListVerificationsCommand struct {
	Status string
	Limit  int
}

type ApproveVerificationCommand struct {
	UserID     string
	ReviewedBy string
}

type RejectVerificationCommand struct {
	UserID          string
	RejectionReason string
	ReviewedBy      string
}
