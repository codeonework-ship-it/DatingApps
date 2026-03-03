package application

const (
	ListActivitiesCommandName    = "admin.activities.list"
	ListReportsCommandName       = "admin.reports.list"
	ActionReportCommandName      = "admin.reports.action"
	AnalyticsOverviewCommandName = "admin.analytics.overview"
	UserAnalyticsCommandName     = "admin.analytics.user"
)

type ListActivitiesCommand struct {
	Limit int
}

type ListReportsCommand struct {
	Status string
	Limit  int
}

type ActionReportCommand struct {
	ReportID   string
	Status     string
	Action     string
	ReviewedBy string
}

type AnalyticsOverviewCommand struct{}

type UserAnalyticsCommand struct {
	UserID string
}
