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
	Known	   bool `json:"known"`
}
type Known_themes struct {
	Path   string
	Themes map[string]Theme
	Themes_list []Theme `json:"Themes_list"`
}

func (k *Known_themes) From_file(known_themes_path string) error {

	// attempt to open existing Known_themes,
	// if it errors, or cannot be unmarshalled, instantiate a new kt struct.
	//kt := Known_themes{Themes: make(map[string]Theme)}
	kt := Known_themes{Themes: make(map[string]Theme),Themes_list: make([]Theme,0)}

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
		if k.Path == ""{
			k.Path = "/home/f/.config/nvim/lua/themeinator/known_themes.json"
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
