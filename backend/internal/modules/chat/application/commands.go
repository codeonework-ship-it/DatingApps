package application

const (
	ListMessagesCommandName = "chat.messages.list"
	SendMessageCommandName  = "chat.messages.send"
)

type ListMessagesCommand struct {
	MatchID string
	Limit   int
}

type SendMessageCommand struct {
	MatchID string
	Payload map[string]any
}
