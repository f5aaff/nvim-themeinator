package libfuncs

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/gocolly/colly"
)

func Populate_kt(kt *Known_themes, search_query string) error {
	themes_recorded := 0
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
			_ = GetColors(kt, href)
			themes_recorded++
			fmt.Printf("themes grabbed:%d\r", themes_recorded)
			// Visit the GitHub link
			_ = e.Request.Visit(href)
		}
	})
	colorSchemesURL := "https://vimcolorschemes.com/i/top/e.vim"
	if search_query != "" {
		colorSchemesURL = fmt.Sprintf("%s/s.%s", colorSchemesURL, search_query)
	}
	err := c.Visit(colorSchemesURL)
	if err != nil {
		return err
	}
	return nil
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	if os.IsNotExist(err) {
		return false
	}
	return err == nil
}
func GetColors(kt *Known_themes, ghLink string) error {

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

			err := c.Visit(e.Request.AbsoluteURL(link))
			if err != nil {
				return
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
			path := "/home/f/.config/nvim/colors/" + name + ".vim"
			t, ok := kt.Themes[name]
			t.Known = true
			if !ok {
				t := Theme{
					Name:       name,
					Path:       "",
					Link:       rawURL,
					Downloaded: false,
				}
				exists := fileExists(path)
				if exists {
					t.Downloaded = true
					t.Path = path
					kt.Themes[name] = t
					kt.Themes_list = append(kt.Themes_list, t)
				}
				kt.Themes[name] = t
			}
			exists := fileExists(path)
			if exists {
				t.Downloaded = true
				t.Path = path
				kt.Themes[name] = t
				kt.Themes_list = append(kt.Themes_list, t)
			}
			// if it is in the map, but the link is old, update it
			if ok && kt.Themes[name].Link != rawURL {
				t := kt.Themes[name]
				t.Link = rawURL
				exists := fileExists(path)
				if exists {
					t.Downloaded = true
					t.Path = path
				}
				kt.Themes[name] = t
				kt.Themes_list = append(kt.Themes_list, t)
			}
		}
	})

	// Start the scraping process by visiting the provided GitHub repository link
	err := c.Visit(ghLink)
	if err != nil {
		return err
	}
	err = kt.To_file()
	if err != nil {
		return err
	}

	return nil
}
