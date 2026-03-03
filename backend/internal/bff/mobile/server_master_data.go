package mobile

import "net/http"

func (s *Server) getPreferenceMasterData(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	payload := s.masterData.getPreferenceMasterData(ctx)
	writeJSON(w, http.StatusOK, map[string]any{
		"master_data": payload,
	})
}
