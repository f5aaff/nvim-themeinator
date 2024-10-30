package libfuncs
import (
	"net/http"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
)
func DownloadColourScheme(kt *Known_themes,theme_name string) error {

	theme,ok := kt.Themes[theme_name]
	if !ok {
		return errors.New("theme not found in known_themes.json")
	}
	// check for a valid DL link
	if !strings.HasSuffix(theme.Link, theme.Name+".vim") {
		return errors.New("invalid link" + theme.Link)
	}

	dest := fmt.Sprintf("/home/f/.config/nvim/colors/%s.vim", theme.Name)
	// create the file at the given destination
	out, err := os.Create(dest)
	if err != nil {
		return err
	}

	// defer closing the file struct to prevent it closing in the event of a large file
	defer out.Close()

	resp, err := http.Get(theme.Link)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	n, err := io.Copy(out, resp.Body)

	if n < 1 {
		return errors.New("wrote <1 bytes to file")
	}

	if err != nil {
		return err
	}

	theme.Downloaded = true
	theme.Path = dest
	kt.Themes[theme_name] = theme
	return nil
}


//
//func downloadAllThemes(kt Known_themes, colours_dir string) {
//	for _, theme := range kt.Themes {
//		err := DownloadColourScheme(&kt,theme.Name)
//		if err != nil {
//			return
//		}
//	}
//}
