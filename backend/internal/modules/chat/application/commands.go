package application

const (
	ListMessagesCommandName  = "chat.messages.list"
	SendMessageCommandName   = "chat.messages.send"
	DeleteMessageCommandName = "chat.messages.delete"
)

type ListMessagesCommand struct {
	MatchID string
	Limit   int
}

type SendMessageCommand struct {
	MatchID string
	Payload map[string]any
}

type DeleteMessageCommand struct {
	MatchID string
	Payload map[string]any
}
