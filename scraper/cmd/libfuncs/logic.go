package libfuncs

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/gocolly/colly"
)

func test() {
	known_themes_path := "/home/f/.config/nvim/lua/themeinator/Known_themes.json"

	// attempt to open existing Known_themes,
	// if it errors, or cannot be unmarshalled, instantiate a new kt struct.
	kt := Known_themes{Themes: make(map[string]Theme)}

	kt_file, err := os.Open(known_themes_path)
	if err != nil {
		log.Printf("open known themes//os.open Error: %s", err.Error())
	} else {
		r, err := io.ReadAll(kt_file)
		if err != nil {
			log.Printf("open known themes//io.ReadAll Error: %s", err.Error())
		} else {
			err := json.Unmarshal(r, &kt)
			if err != nil {
				log.Printf("open known themes//json.Unmarshal Error: %s", err.Error())
			}
		}
	}

	defer kt_file.Close()

	// initiate colly collector, pointed at vimcolorschemes .vim top results
	c := colly.NewCollector()
	themeCollector := c.Clone()

	c.OnHTML("a.repositoryCard_info__5_UY6", func(e *colly.HTMLElement) {
		// Extract the href attribute
		href := e.Attr("href")
		if href != "" {
			// Construct the absolute URL if the href is relative
			link := e.Request.AbsoluteURL(href)
			parts := strings.Split(strings.Trim(href, "/"), "/")
			if len(parts) < 2 {
				return
			}

			themeCollector.OnRequest(func(r *colly.Request) {
				r.Ctx.Put("author", parts[len(parts)-2])
				r.Ctx.Put("theme", parts[len(parts)-1])
			})

			log.Print("Found link:", link)

			// Visit the link (or store it for further processing)
			_ = themeCollector.Visit(link)
		}
	})

	// Look for GitHub links on each theme page
	themeCollector.OnHTML("a", func(e *colly.HTMLElement) {
		href := e.Attr("href")
		author := e.Request.Ctx.Get("author")
		theme := e.Request.Ctx.Get("theme")
		if href == fmt.Sprintf("https://github.com/%s/%s", author, theme) {
			log.Print("Found GitHub link:", href)
			_ = GetColors(&kt, href)
			// Visit the GitHub link
			_ = e.Request.Visit(href)
		}
	})
	err = c.Visit("https://vimcolorschemes.com/i/top/e.vim")
	if err != nil {
		log.Print("err:", err)
	}

	// uncomment to download a single theme
}

