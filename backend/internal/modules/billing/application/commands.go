package application

const (
	ListPlansCommandName       = "billing.plans.list"
	GetSubscriptionCommandName = "billing.subscription.get"
	SubscribePlanCommandName   = "billing.subscribe"
	ListPaymentsCommandName    = "billing.payments.list"
)

type ListPlansCommand struct{}

type GetSubscriptionCommand struct {
	UserID string
}

type SubscribePlanCommand struct {
	UserID       string
	PlanID       string
	BillingCycle string
}

type ListPaymentsCommand struct {
	UserID string
	Limit  int
}
