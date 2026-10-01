package application

const (
	LoginCommandName  = "auth.login"
	SignupCommandName = "auth.signup"
)

type LoginCommand struct {
	Username string
	Password string
}

type SignupCommand struct {
	Username    string
	Password    string
	AccountKind string
	Name        string
	DateOfBirth string
}
