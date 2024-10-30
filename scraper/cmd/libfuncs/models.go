package libfuncs


type Theme struct {
	Name       string `json:"name"`
	Downloaded bool   `json:"downloaded"`
	Link       string `json:"link"`
	Path       string `json:"path"`
}
type known_themes struct {
	Themes map[string]Theme `json:"themes"`
}
