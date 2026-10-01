package mobile

import (
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
)

// HTTP surface for friend vouches and intros (migration 096).
//
//	GET    /friends/{userID}/vouches                      vouches about me + vouches I wrote
//	POST   /friends/{userID}/vouches                      write a vouch {for_user_id, text}
//	POST   /friends/{userID}/vouches/{vouchID}/decision   subject approves or hides
//	DELETE /friends/{userID}/vouches/{vouchID}            voucher withdraws / subject removes
//	GET    /users/{userID}/vouches                        approved vouches on a profile
//	GET    /friends/{userID}/intros                       intros for me + intros I made
//	POST   /friends/{userID}/intros                       introduce two friends
//	POST   /friends/{userID}/intros/{introID}/decision    invitee accepts or declines

func (s *Server) friendSocial() (*friendSocialService, error) {
	db, err := s.growthDB()
	if err != nil {
		return nil, errors.New("friend social persistence is unavailable")
	}
	return newFriendSocialService(db), nil
}

func writeFriendSocialError(w http.ResponseWriter, err error) {
	conflict := func(code string) {
		writeJSON(w, http.StatusConflict, map[string]any{
			"success": false, "error": err.Error(), "error_code": code,
		})
	}
	switch {
	case errors.Is(err, errVouchNotFound), errors.Is(err, errIntroNotFound):
		writeError(w, http.StatusNotFound, err)
	case errors.Is(err, errVouchForbidden), errors.Is(err, errIntroForbidden):
		writeError(w, http.StatusForbidden, err)
	case errors.Is(err, errVouchNotFriend), errors.Is(err, errIntroNotFriends):
		conflict("FRIEND_REQUIRED")
	case errors.Is(err, errVouchExists):
		conflict("VOUCH_EXISTS")
	case errors.Is(err, errIntroUnavailable), errors.Is(err, errIntroNotPublished):
		conflict("INTRO_UNAVAILABLE")
	case errors.Is(err, errIntroAlreadyOpen):
		conflict("INTRO_ALREADY_OPEN")
	case errors.Is(err, errIntroNotOpen):
		conflict("INTRO_NOT_OPEN")
	default:
		writeError(w, http.StatusServiceUnavailable, errors.New("friend social persistence is unavailable"))
	}
}

func isFriendSocialInputError(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.HasPrefix(msg, "a vouch must") || strings.HasPrefix(msg, "message must") ||
		strings.HasPrefix(msg, "decision must") || strings.HasPrefix(msg, "for_user_id") ||
		strings.HasPrefix(msg, "first_user_id") || strings.HasPrefix(msg, "choose two")
}

func (s *Server) listFriendVouches(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	aboutMe, written, err := svc.listVouches(r.Context(), principal.UserID)
	if err != nil {
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"about_me": aboutMe, "written": written})
}

func (s *Server) writeFriendVouch(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.writeVouch(r.Context(), principal.UserID,
		strings.TrimSpace(toString(payload["for_user_id"])), toString(payload["text"]))
	if err != nil {
		if isFriendSocialInputError(err) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeFriendSocialError(w, err)
		return
	}
	s.store.recordActivity(activityEvent{
		UserID: principal.UserID, Actor: principal.UserID, Action: "friends.vouch",
		Status: "success", Resource: "/friends/" + principal.UserID + "/vouches",
		Details: map[string]any{"vouch_id": view.ID, "subject_user_id": view.SubjectID},
	})
	writeJSON(w, http.StatusCreated, map[string]any{"vouch": view})
}

func (s *Server) decideFriendVouch(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.decideVouch(r.Context(), principal.UserID,
		strings.TrimSpace(chi.URLParam(r, "vouchID")),
		strings.ToLower(strings.TrimSpace(toString(payload["decision"]))))
	if err != nil {
		if isFriendSocialInputError(err) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"vouch": view})
}

func (s *Server) withdrawFriendVouch(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = svc.withdrawVouch(r.Context(), principal.UserID, strings.TrimSpace(chi.URLParam(r, "vouchID"))); err != nil {
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) getPublicVouches(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	vouches, err := svc.publicVouches(r.Context(), principal.UserID, strings.TrimSpace(chi.URLParam(r, "userID")))
	if err != nil {
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"vouches": vouches})
}

func (s *Server) listFriendIntros(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	received, made, err := svc.listIntros(r.Context(), principal.UserID)
	if err != nil {
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"received": received, "made": made})
}

func (s *Server) makeFriendIntro(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.makeIntro(r.Context(), principal.UserID,
		strings.TrimSpace(toString(payload["first_user_id"])),
		strings.TrimSpace(toString(payload["second_user_id"])),
		toString(payload["message"]))
	if err != nil {
		if isFriendSocialInputError(err) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeFriendSocialError(w, err)
		return
	}
	s.store.recordActivity(activityEvent{
		UserID: principal.UserID, Actor: principal.UserID, Action: "friends.intro",
		Status: "success", Resource: "/friends/" + principal.UserID + "/intros",
		Details: map[string]any{"intro_id": view.ID},
	})
	writeJSON(w, http.StatusCreated, map[string]any{"intro": view})
}

func (s *Server) decideFriendIntro(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	svc, err := s.friendSocial()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	view, err := svc.decideIntro(r.Context(), principal.UserID,
		strings.TrimSpace(chi.URLParam(r, "introID")),
		strings.ToLower(strings.TrimSpace(toString(payload["decision"]))))
	if err != nil {
		if isFriendSocialInputError(err) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeFriendSocialError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"intro": view})
}
