package application

const (
	SendOTPCommandName   = "auth.send_otp"
	VerifyOTPCommandName = "auth.verify_otp"
)

type SendOTPCommand struct {
	Email string
}

type VerifyOTPCommand struct {
	Email string
	OTP   string
}
