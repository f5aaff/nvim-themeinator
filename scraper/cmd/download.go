package cmd

import (
	"fmt"
	"os"
	"themeinator/cmd/libfuncs"

	"github.com/spf13/cobra"
)

var DownloadColoursCmd = cobra.Command{
	Use: "download",
	Short: "download theme from vimcolors, expects the theme name",
	Long: ``,
	Args: cobra.MaximumNArgs(1),
	Run: func (cmd *cobra.Command, args []string)  {
		err := kt.From_file("/home/f/.config/nvim/lua/themeinator/known_themes.json")
		if err != nil {
			fmt.Println("error:",err.Error())
		}
		err = libfuncs.DownloadColourScheme(&kt,args[0])
		if err != nil {
			fmt.Printf("error downloading colour scheme: %s",err.Error())
			os.Exit(1)
		}
		fmt.Printf("%s downloaded to %s\n",kt.Themes[args[0]].Name,kt.Themes[args[0]].Path)
		os.Exit(0)
	},
}
