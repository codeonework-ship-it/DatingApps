package mobile

import "net/http"

func (s *Server) getPreferenceMasterData(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	payload, err := s.masterData.getPreferenceMasterData(ctx)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"master_data": payload,
	})
}
