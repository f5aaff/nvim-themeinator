/*
Copyright © 2024 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
	"os"
	"themeinator/cmd/libfuncs"
	"github.com/spf13/cobra"
)

var kt = libfuncs.Known_themes{Themes : make(map[string]libfuncs.Theme)}

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "themeinator",
	Short: "CLI tool for scraping vim themes and downloading them to file",
	Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	rootCmd.AddCommand(&getColoursCmd)
	rootCmd.AddCommand(&DownloadColoursCmd)
	rootCmd.AddCommand(&searchCmd)
}


