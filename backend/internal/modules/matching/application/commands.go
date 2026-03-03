package application

const (
	GetCandidatesCommandName       = "matching.candidates"
	SwipeCommandName               = "matching.swipe"
	ListMatchesCommandName         = "matching.list"
	UnmatchCommandName             = "matching.unmatch"
	MarkAsReadCommandName          = "matching.read"
	GetQuestTemplateCommandName    = "matching.quest.template.get"
	UpsertQuestTemplateCommandName = "matching.quest.template.upsert"
	GetQuestWorkflowCommandName    = "matching.quest.workflow.get"
	SubmitQuestResponseCommandName = "matching.quest.workflow.submit"
	ReviewQuestResponseCommandName = "matching.quest.workflow.review"
	ListGestureTimelineCommandName = "matching.gesture.timeline.list"
	CreateGestureCommandName       = "matching.gesture.create"
	DecideGestureCommandName       = "matching.gesture.decide"
	GetGestureScoreCommandName     = "matching.gesture.score.get"
)

type GetCandidatesCommand struct {
	UserID string
	Limit  int
}

type SwipeCommand struct {
	Payload map[string]any
}

type ListMatchesCommand struct {
	UserID string
}

type UnmatchCommand struct {
	MatchID string
	UserID  string
}

type MarkAsReadCommand struct {
	MatchID string
	Payload map[string]any
}

type GetQuestTemplateCommand struct {
	MatchID string
}

type UpsertQuestTemplateCommand struct {
	MatchID       string
	CreatorUserID string
	Prompt        string
	MinChars      int
	MaxChars      int
}

type GetQuestWorkflowCommand struct {
	MatchID string
}

type SubmitQuestResponseCommand struct {
	MatchID         string
	SubmitterUserID string
	ResponseText    string
}

type ReviewQuestResponseCommand struct {
	MatchID        string
	ReviewerUserID string
	DecisionStatus string
	ReviewReason   string
}

type ListGestureTimelineCommand struct {
	MatchID string
}

type CreateGestureCommand struct {
	MatchID        string
	SenderUserID   string
	ReceiverUserID string
	GestureType    string
	ContentText    string
	Tone           string
}

type DecideGestureCommand struct {
	MatchID        string
	GestureID      string
	ReviewerUserID string
	Decision       string
	Reason         string
}

type GetGestureScoreCommand struct {
	MatchID   string
	GestureID string
}
