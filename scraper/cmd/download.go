package cmd


import (
	"fmt"
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
	//	err = libfuncs.Populate_kt(&kt)
	//	if err != nil{
	//		fmt.Printf("error populating known themes")
	//	}
	//	if len(kt.Themes) < 1 {
	//		fmt.Println("no themes found!")
	//		return
	//	}
		fmt.Printf("ARGS:%s",args[0])
		err = libfuncs.DownloadColourScheme(&kt,args[0])
		if err != nil {
			fmt.Printf("error downloading colour scheme: %s",err.Error())
		}

		fmt.Printf("%d themes downloaded to %s\n",len(kt.Themes),kt.Path)
	},
}
