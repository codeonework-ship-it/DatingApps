package application

const (
	GetCircleChallengeCommandName    = "engagement.circle.challenge.get"
	JoinCircleCommandName            = "engagement.circle.join"
	SubmitCircleChallengeCommandName = "engagement.circle.challenge.submit"

	GetDailyPromptCommandName            = "engagement.daily_prompt.get"
	SubmitDailyPromptAnswerCommandName   = "engagement.daily_prompt.submit"
	ListDailyPromptRespondersCommandName = "engagement.daily_prompt.responders.list"

	SendMatchNudgeCommandName          = "engagement.match_nudge.send"
	ClickMatchNudgeCommandName         = "engagement.match_nudge.click"
	MarkConversationResumedCommandName = "engagement.match_nudge.resume"

	ListVoicePromptsCommandName     = "engagement.voice.prompts.list"
	StartVoiceIcebreakerCommandName = "engagement.voice.start"
	SendVoiceIcebreakerCommandName  = "engagement.voice.send"
	PlayVoiceIcebreakerCommandName  = "engagement.voice.play"

	CreateGroupCoffeePollCommandName   = "engagement.group_coffee.create"
	ListGroupCoffeePollsCommandName    = "engagement.group_coffee.list"
	GetGroupCoffeePollCommandName      = "engagement.group_coffee.get"
	VoteGroupCoffeePollCommandName     = "engagement.group_coffee.vote"
	FinalizeGroupCoffeePollCommandName = "engagement.group_coffee.finalize"

	CreateCommunityGroupCommandName        = "engagement.community_group.create"
	ListCommunityGroupsCommandName         = "engagement.community_group.list"
	InviteCommunityGroupMembersCommandName = "engagement.community_group.invite"
	RespondCommunityGroupInviteCommandName = "engagement.community_group.invite.respond"
	ListCommunityGroupInvitesCommandName   = "engagement.community_group.invites.list"
)

type GetCircleChallengeCommand struct {
	CircleID string
	UserID   string
}

type JoinCircleCommand struct {
	CircleID string
	UserID   string
}

type SubmitCircleChallengeCommand struct {
	CircleID    string
	ChallengeID string
	UserID      string
	EntryText   string
	ImageURL    string
}

type GetDailyPromptCommand struct {
	UserID string
}

type SubmitDailyPromptAnswerCommand struct {
	UserID     string
	PromptID   string
	AnswerText string
}

type ListDailyPromptRespondersCommand struct {
	UserID string
	Limit  int
	Offset int
}

type SendMatchNudgeCommand struct {
	MatchID            string
	UserID             string
	CounterpartyUserID string
	NudgeType          string
}

type ClickMatchNudgeCommand struct {
	NudgeID string
	UserID  string
}

type MarkConversationResumedCommand struct {
	MatchID        string
	UserID         string
	TriggerNudgeID string
}

type ListVoicePromptsCommand struct{}

type StartVoiceIcebreakerCommand struct {
	MatchID        string
	SenderUserID   string
	ReceiverUserID string
	PromptID       string
}

type SendVoiceIcebreakerCommand struct {
	IcebreakerID    string
	SenderUserID    string
	Transcript      string
	DurationSeconds int
}

type PlayVoiceIcebreakerCommand struct {
	IcebreakerID string
	UserID       string
}

type GroupCoffeeOptionInput struct {
	Day          string
	TimeWindow   string
	Neighborhood string
}

type CreateCommunityGroupCommand struct {
	OwnerUserID    string
	Name           string
	City           string
	Topic          string
	Description    string
	Visibility     string
	InviteeUserIDs []string
}

type ListCommunityGroupsCommand struct {
	UserID     string
	City       string
	Topic      string
	OnlyJoined bool
	Limit      int
}

type InviteCommunityGroupMembersCommand struct {
	GroupID        string
	InviterUserID  string
	InviteeUserIDs []string
}

type RespondCommunityGroupInviteCommand struct {
	GroupID  string
	UserID   string
	Decision string
}

type ListCommunityGroupInvitesCommand struct {
	UserID string
	Status string
	Limit  int
}

type CreateGroupCoffeePollCommand struct {
	CreatorUserID      string
	ParticipantUserIDs []string
	Options            []GroupCoffeeOptionInput
	DeadlineAt         string
}

type ListGroupCoffeePollsCommand struct {
	UserID string
	Status string
	Limit  int
}

type GetGroupCoffeePollCommand struct {
	PollID string
}

type VoteGroupCoffeePollCommand struct {
	PollID   string
	UserID   string
	OptionID string
}

type FinalizeGroupCoffeePollCommand struct {
	PollID string
	UserID string
}
