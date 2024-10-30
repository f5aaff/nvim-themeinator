package cmd

import (
	"strings"
	"fmt"
	"github.com/spf13/cobra"
)


var getColoursCmd = cobra.Command{
	Use: "get_colours",
	Short: "get results from vimcolors",
	Long: ``,
	Args: cobra.MaximumNArgs(2),
	Run: func (cmd *cobra.Command, args []string)  {
		fmt.Println("stuff"+strings.Join(args, "|"))
	},
}


func get_colours(){

}
