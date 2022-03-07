package cmd

import (
	accountApi "shopware-cli/account-api"

	"github.com/pkg/errors"
	log "github.com/sirupsen/logrus"

	"github.com/spf13/cobra"
)

var logoutCmd = &cobra.Command{
	Use:   "logout",
	Short: "Logout from Shopware Account",
	Long:  ``,
	RunE: func(_ *cobra.Command, _ []string) error {
		err := accountApi.InvalidateTokenCache()
		if err != nil {
			return errors.Wrap(err, "cannot invalidate token cache")
		}

		appConfig.Account.Company = 0
		appConfig.Account.Email = ""
		appConfig.Account.Password = ""
		err = saveApplicationConfig()

		if err != nil {
			return errors.Wrap(err, "cannot write config")
		}

		log.Infof("You have been logged out")

		return nil
	},
}

func init() {
	accountRootCmd.AddCommand(logoutCmd)
}
