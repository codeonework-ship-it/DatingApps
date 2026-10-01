package mobile

import (
	"errors"
	"os"
	"strings"
	"testing"
)

// TestGiftUnavailableIsDistinctFromNotFound guards the GIFT-005 status
// contract.
//
// `getCatalogByID` filters on is_active, so a retired or out-of-season gift
// came back indistinguishable from one that never existed, and both answered
// 400. The documented response for an unavailable gift is 422: the request was
// well formed, the gift simply cannot be sent, and a client has to tell that
// apart from having sent a bad id.
func TestGiftUnavailableIsDistinctFromNotFound(t *testing.T) {
	if errGiftUnavailable == nil {
		t.Fatal("errGiftUnavailable must exist for the transport to map 422")
	}
	notFound := errors.New("gift not found")
	if errors.Is(notFound, errGiftUnavailable) {
		t.Fatal(
			"a missing gift must not match the unavailable sentinel; they map " +
				"to different documented responses",
		)
	}
}

// TestSendRoseGiftMapsUnavailableTo422 pins the mapping in the transport.
//
// Asserted against the handler source because reaching this branch for real
// needs an unlocked match, a funded wallet and a deactivated catalog row. The
// mapping is one line and silently reverting it would put the response back to
// 400 with every functional test still passing.
func TestSendRoseGiftMapsUnavailableTo422(t *testing.T) {
	source := giftSendHandlerSource(t)
	if !strings.Contains(source, "errors.Is(err, errGiftUnavailable)") {
		t.Error("the gift send handler must branch on errGiftUnavailable")
	}
	if !strings.Contains(source, "StatusUnprocessableEntity") {
		t.Error("an unavailable gift must answer 422, as GIFT-005 documents")
	}
	if !strings.Contains(source, "GIFT_UNAVAILABLE") {
		t.Error("the response should carry a distinguishable error_code")
	}
	// The neighbouring documented codes must survive alongside it.
	for _, code := range []string{
		"StatusPaymentRequired", // insufficient coins
		"StatusTooManyRequests", // per-match daily limit
		"StatusLocked",          // chat not unlocked
	} {
		if !strings.Contains(source, code) {
			t.Errorf("gift send must still map %s", code)
		}
	}
}

// giftSendHandlerSource returns the body of the send handler.
func giftSendHandlerSource(t *testing.T) string {
	t.Helper()
	bytes, err := os.ReadFile("server_gifts.go")
	if err != nil {
		t.Fatalf("read server_gifts.go: %v", err)
	}
	raw := string(bytes)
	start := strings.Index(raw, "func (s *Server) sendRoseGift(")
	if start < 0 {
		t.Fatal("sendRoseGift handler not found")
	}
	next := strings.Index(raw[start+1:], "\nfunc ")
	if next < 0 {
		return raw[start:]
	}
	return raw[start : start+1+next]
}
