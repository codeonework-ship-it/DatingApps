package application

const (
	GetProfileCommandName             = "profile.get"
	GetProfileSummaryCommandName      = "profile.summary"
	UpsertProfileCommandName          = "profile.upsert"
	GetProfileDraftCommandName        = "profile.draft.get"
	PatchProfileDraftCommandName      = "profile.draft.patch"
	AddProfilePhotoCommandName        = "profile.photo.add"
	DeleteProfilePhotoCommandName     = "profile.photo.delete"
	ReorderProfilePhotosCommandName   = "profile.photo.reorder"
	CompleteProfileCommandName        = "profile.complete"
	GetSettingsCommandName            = "profile.settings.get"
	PatchSettingsCommandName          = "profile.settings.patch"
	ListEmergencyContactsCommandName  = "profile.emergency.list"
	AddEmergencyContactCommandName    = "profile.emergency.add"
	UpdateEmergencyContactCommandName = "profile.emergency.update"
	DeleteEmergencyContactCommandName = "profile.emergency.delete"
	ListBlockedUsersCommandName       = "profile.blocked.list"
)

type GetProfileCommand struct {
	UserID string
}

type GetProfileSummaryCommand struct {
	UserID string
}

type UpsertProfileCommand struct {
	UserID  string
	Profile map[string]any
}

type GetProfileDraftCommand struct {
	UserID string
}

type PatchProfileDraftCommand struct {
	UserID  string
	Payload map[string]any
}

type AddProfilePhotoCommand struct {
	UserID   string
	PhotoURL string
}

type DeleteProfilePhotoCommand struct {
	UserID  string
	PhotoID string
}

type ReorderProfilePhotosCommand struct {
	UserID   string
	PhotoIDs []string
}

type CompleteProfileCommand struct {
	UserID string
}

type GetSettingsCommand struct {
	UserID string
}

type PatchSettingsCommand struct {
	UserID  string
	Payload map[string]any
}

type ListEmergencyContactsCommand struct {
	UserID string
}

type AddEmergencyContactCommand struct {
	UserID      string
	Name        string
	PhoneNumber string
}

type UpdateEmergencyContactCommand struct {
	UserID      string
	ContactID   string
	Name        string
	PhoneNumber string
}

type DeleteEmergencyContactCommand struct {
	UserID    string
	ContactID string
}

type ListBlockedUsersCommand struct {
	UserID string
}
