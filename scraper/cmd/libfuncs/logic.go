package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gocolly/colly"
)

type Theme struct {
	Name       string `json:"name"`
	Downloaded bool   `json:"downloaded"`
	Link       string `json:"link"`
	Path       string `json:"path"`
}
type known_themes struct {
	Themes map[string]Theme `json:"themes"`
}

func test() {
	known_themes_path := "/home/f/.config/nvim/lua/themeinator/known_themes.json"

	// attempt to open existing known_themes,
	// if it errors, or cannot be unmarshalled, instantiate a new kt struct.
	kt := known_themes{Themes: make(map[string]Theme)}

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
//	t := kt.Themes["two-firewatch"]
//	err = DownloadColourScheme(&t)
//	if err != nil {
//		log.Printf("error downloading colour scheme: %s",err.Error())
//	}
}

func GetColors(kt *known_themes, ghLink string) error {

	// pull the author and theme name from the repo link
	parts := strings.Split(strings.Trim(ghLink, "/"), "/")
	if len(parts) < 2 {
		return errors.New("no author/theme found")
	}

	// split out the theme name
	theme := parts[len(parts)-1]

	// Initialize the main collector for the GitHub repository page
	c := colly.NewCollector(
		colly.AllowedDomains("github.com"),
	)

	// Variable to track if we are inside the colors directory

	// Scrape repository page to find directories and files
	c.OnHTML("a[href*=\"/tree/\"]", func(e *colly.HTMLElement) {
		link := e.Attr("href")
		name := e.Text

		// Check if the directory name contains "colors"
		if strings.Contains(strings.ToLower(name), "colors") {
			log.Printf("Found colors directory at: %s\n", link)

			err := c.Visit(e.Request.AbsoluteURL(link))
			if err != nil {
				log.Printf("Error visiting colors directory: %v\n", err)
			}
		}
	})

	// Handle the contents of the colors directory
	c.OnHTML("a[href*=\"/blob/\"]", func(e *colly.HTMLElement) {
		fileLink := e.Attr("href")
		fileName := e.Text

		// Check if the link is to a .vim file
		if (strings.HasSuffix(fileName, ".vim") && strings.Contains(fileLink, "colors")) || strings.Contains(fileName, theme+".vim") {
			// Construct the raw GitHub URL
			rawURL := strings.Replace(fileLink, "/blob/", "/raw/", 1)
			rawURL = e.Request.AbsoluteURL(rawURL)

			// grab the name of the theme
			name := strings.Split(fileName, ".")[0]

			// if the theme isn't in the known themes map,
			// create a new Theme struct and add it
			_, ok := kt.Themes[name]
			if !ok {
				t := Theme{
					Name:       name,
					Path:       "",
					Link:       rawURL,
					Downloaded: false,
				}
				kt.Themes[name] = t
			}

			// if it is in the map, but the link is old, update it
			if ok && kt.Themes[name].Link != rawURL {
				t := kt.Themes[name]
				t.Link = rawURL
				kt.Themes[name] = t
			}

			log.Printf("Found .vim file: %s\nRaw URL: %s\n", fileName, rawURL)
		}
	})

	// Start the scraping process by visiting the provided GitHub repository link
	err := c.Visit(ghLink)
	if err != nil {
		log.Print("Error visiting GitHub link:", err)
		return err
	}

	// write known theme links to file, if the map has any items
	if len(kt.Themes) > 1 {
		b, err := json.Marshal(kt)
		if err != nil {
			log.Print("ERROR: ", err.Error())
		}
		themes_file, err := os.Create("/home/f/.config/nvim/lua/themeinator/known_themes.json")
		if err != nil {
			log.Print("ERROR: ", err.Error())
		}
		defer themes_file.Close()

		_, err = io.Writer.Write(themes_file, b)
		if err != nil {
			log.Print("ERROR: ", err.Error())
		}
	}

	return nil
}

func DownloadColourScheme(theme *Theme) error {

	// check for a valid DL link
	if !strings.HasSuffix(theme.Link,theme.Name+".vim") {
		return errors.New("invalid link"+theme.Link)
	}
	log.Printf("DOWNLOADING: %s",theme.Name)
	dest := fmt.Sprintf("/home/f/.config/nvim/colors/%s.vim",theme.Name)
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
	return nil
}

func downloadAllThemes(kt known_themes, colours_dir string) {
	for _, theme := range kt.Themes {

		//fullPath := colours_dir + "/" + theme.Name
		log.Printf("Downloading %s", theme.Name)
		err := DownloadColourScheme(&theme)
		if err != nil {
			log.Printf("DOWNLOAD ERROR: %s", err.Error())
		}
	}
}
