package libfuncs

import (
	"encoding/json"
	"errors"
	"io"
	"os"
)

type Theme struct {
	Name       string `json:"name"`
	Downloaded bool   `json:"downloaded"`
	Link       string `json:"link"`
	Path       string `json:"path"`
}
type Known_themes struct {
	Path   string
	Themes map[string]Theme `json:"themes"`
}

func (k *Known_themes) From_file(known_themes_path string) error {

	// attempt to open existing Known_themes,
	// if it errors, or cannot be unmarshalled, instantiate a new kt struct.
	kt := Known_themes{Themes: make(map[string]Theme)}

	kt_file, err := os.Open(known_themes_path)
	if err != nil {
		return err
	} else {
		r, err := io.ReadAll(kt_file)
		if err != nil {
			return err
		} else {
			err := json.Unmarshal(r, &kt)
			if err != nil {
				return err
			}
		}
	}

	defer kt_file.Close()
	k.Themes = kt.Themes
	k.Path = known_themes_path
	return nil
}

func (k *Known_themes) To_file() error {

	// write known theme links to file, if the map has any items
	if len(k.Themes) > 1 {
		b, err := json.Marshal(k)
		if err != nil {
			return err
		}
		themes_file, err := os.Create(k.Path)
		if err != nil {
			return err
		}
		defer themes_file.Close()

		_, err = io.Writer.Write(themes_file, b)
		if err != nil {
			return err
		}
	} else {
		return errors.New("no themes to record!")
	}
	return nil
}
