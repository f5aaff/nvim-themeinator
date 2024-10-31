package libfuncs

func search_for_theme(kt *Known_themes, theme_name string) error {
	err := Populate_kt(kt, &theme_name)
	if err != nil {
		return err
	}
	return nil
}
