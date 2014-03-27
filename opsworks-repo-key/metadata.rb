name        "ssh_deploy_repo_key"
description 'Add private ssh key to deploy user for a private github repo'
maintainer  "ABS"
license     "Apache 2.0"
version     "1.0.0"

depends 'opsworks_initial_setup'

recipe "opsworks_deploy_key::add", "Add a github ssh key for private repos"