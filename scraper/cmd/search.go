package cmd



import (
	"fmt"
	"themeinator/cmd/libfuncs"

	"github.com/spf13/cobra"
)


var searchCmd = cobra.Command{
	Use: "search",
	Short: "search for a theme, add them to known themes",
	Long: ``,
	Args: cobra.MaximumNArgs(1),
	Run: func (cmd *cobra.Command, args []string)  {
		err := kt.From_file("/home/f/.config/nvim/lua/themeinator/known_themes.json")
		if err != nil {
			fmt.Println("error:",err.Error())
		}
		err = libfuncs.Populate_kt(&kt,&args[0])
		if err != nil {
			fmt.Println("error:", err.Error())
		}
		fmt.Printf("%d themes recorded to file %s\n",len(kt.Themes),kt.Path)
	},
}
