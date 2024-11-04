package cmd

import (
	"fmt"
	"themeinator/cmd/libfuncs"

	"github.com/spf13/cobra"
)


var getColoursCmd = cobra.Command{
	Use: "getThemes",
	Short: "get results from vimcolors",
	Long: ``,
	Args: cobra.MaximumNArgs(2),
	Run: func (cmd *cobra.Command, args []string)  {
		err := kt.From_file("/home/f/.config/nvim/lua/themeinator/known_themes.json")
		if err != nil {
			fmt.Println("error:",err.Error())
		}
		err = libfuncs.Populate_kt(&kt,"")
		if err != nil {
			fmt.Println("error:", err.Error())
		}
		fmt.Printf("%d themes recorded to file %s\n",len(kt.Themes),kt.Path)
	},
}


