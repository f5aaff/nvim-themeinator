package main

import (
	"fmt"
	"github.com/gocolly/colly"
	"strings"
)

func main() {

	//initiate colly collector, pointed at vimcolorschemes .vim top results
	c := colly.NewCollector()

	c.OnHTML("div", func(e *colly.HTMLElement) {
		classAttr := e.Attr("class")
		if strings.Contains(classAttr, "repositoryCard_info") {
			fmt.Println("vimcolorschemes link: ",e.Attr("href"))
		}

		githubLink := e.ChildAttr("a[href*='github.com']", "href")
		if githubLink != "" {
			fmt.Println("found GH link: ", githubLink)
			scrapeColors(githubLink)
		}
	})

	err := c.Visit("https://vimcolorschemes.com/i/top/e.vim")
	if err != nil {
		fmt.Println("err:", err)
	}
}

func scrapeColors(link string) {
	// new collector, aims for github links
	ghCollector := colly.NewCollector(
		colly.AllowedDomains("github.com"),
	)

	ghCollector.OnHTML("table a.js-navigation-open", func(e *colly.HTMLElement) {
		if e.Text == "colors" {
			colorsFolderLink := e.Request.AbsoluteURL(e.Attr("href"))
			fmt.Println("colors folder: ", colorsFolderLink)
		}
	})
}
