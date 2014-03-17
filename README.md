# ABS Opsworks Cookbooks

These are some Chef recipes we use to assist our OpsWorks deployments.

## Warning

This cookbook repository is public, so don't commit any secrets into its codebase. Secrets should be passed to your applications through [custom JSON](#customjson).

## Terminology

There are some basic concepts and terms you'll want to know:

* OpsWorks - an AWS version of Chef. It can use standard Chef cookbooks, but doesn't use a Chef server. Using a custom agent, it pushes changes to a locally Chef Solo style deployment. It has a web frontend.
* Stack - an OpsWorks specification for a group of servers and the services and apps deployed to them.
* Layer - a particular type of server within a stack, e.g. a Rails server, a load balancer
* Instances - EC2 VM's built according to a layer's recipes. Each layer can have multiple instances, and they can be permanent or have lifetimes based on load a time schedule.
* Application - a custom codebase we want to deploy to one or more servers, usually from a git repository.
* Deployment - an attempt to clone and run an application version to one or more instances. Typically, you will push your changes to GitHub then trigger a deployment.

## Quick Start

Unless you make a stack every day, this will never feel *quick*, but this checklist for a typical Rails deployment should help get you on your way to a repeatable server build.

### The Stack

1. Create a new OpsWorks stack and edit it's settings.
1. **Chef version**: 11.4
1. **Custom Chef Cookbooks**: Yes
1. **Cookbook URL**: `https://github.com/americanbible/abs-opsworks.git`
1. **Cookbook Key**: none, they're public (so don't commit secrets to them!)
1. **Cookbook Branch**: `master`, unless you are developing new recipes
1. **Custom JSON**: we'll fix this [later](#customjson).

### The Layers

1. Add a layer. For this example, make it a Rails App Server with no load balancer.
1. **Rails Stack**: nginx and Unicorn (not a hard recommendation)
1. **Install and Manage Bundler**: Yes!
1. **OS Packages**: anything else your app might need, often `nodejs` to support Foundation
1. **Auto Healing**: No, unless you're absolutely sure your app is truly 12-factor, keeping nothing on the hard disk you can't live without.
1. **Public IP**: Yes.

### The Instances

1. Add an instance and start it.
1. In the OpsWorks `My Settings` menu, upload your **public** ssh key.
1. In the Stack Permissions page, add your IAM user to the access list with ssh and sudo permissions.
1. Once the server has started, try `ssh your_iam_name@instance_public_ip`
1. If that works, try `sudo -i` (Ubuntu's preferred idiom for becoming root)

### The Database

If you need a database server,

1. Head back to the layer settings screen and note the layer's security group, probably `AWS-OpsWorks-Rails-App-Server`.
1. Use the AWS RDS dashboard to make a database server.
1. Give it a custom security group, like `database-server`.
1. Edit that security group to to allow inbound TCP on port 3306 for the layer's security group.
1. Use your ssh prompt to create a database for your app.

```
$ mysql -h myappdb.some.cryptic.aws.stuff.amazon.com -u database_admin_username -p
> create database whatever_you_want_to_call_it;
> exit;
```

### The Application

1. Create an OpsWorks application
1. **Rails Environment**: `production`, even if you're deploying a development branch, unless you really understand the security risks of your development configuration.
1. **Auto Bundle**: Yes!
1. **Repository Type**: git
1. **URL**: the GitHub **ssh** URI for your project without a 'ssh://' prefix. (Gemfiles need that; git doesn't.)
1. Create a fresh ssh keypair with `ssh-keygen`,
1. **Repository SSH Key**: the **private** key of that pair (`~/.ssh/id_rsa`).
1. Add the public key of that pair (`~/.ssh/id_rsa.pub`) to your project's deployment keys.
1. **Branch**: whatever you want deployed here.

### Deployments

Go ahead and trigger a deployment. This will begin the process of cloning your application onto the layer you just created.

It will probably fail, and we'll discuss problem solving later

### Custom JSON

Head back to the Stack settings page and scroll down to the custom JSON field. There several main reasons to add data here:

#### Altering Deployment

The OpsWorks documents cover the many deployment settings you can alter here. For instance, you can set the deployment directory by adding:

```json
{
 "deploy" : {
      "deploy_to": "/srv/www/my_custom_directory",
  }
}
```

#### Injecting Secrets and Settings

For this to work, you have to add one of our custom recipes in your layer's `deploy` event: `opsworks_custom_env::configure`.

What this does is cause our custom recipe to run after every deployment. That recipe leverages `figaro` (a great way to handle apps that need secrets without committing them to your code base). It takes JSON data from here:

```json
"custom_env": {
    "your_application_name": {
      "AWS_ID": "<REDACTED>",
      "AWS_KEY": "<REDACTED>"
    }
}
```

...and templates out a Figaro-style `application.yml`. But to get it to work right, you also have to add this deployment instruction because of how OpsWorks symlinks the current codebase into place.

```json
"deploy": {
  "symlink_before_migrate": {
        "config/application.yml": "config/application.yml"
  }
}
```

#### Custom Recipes

The recipes in the custom cookbook, most of them copied or adapated from Chef community cookbooks, automate additional parts of deployment. Situations where we use them are:

1. Forcing precompilation of assets
1. Setting up cron jobs
1. Restarting DelayedJob workers after deployment.

TODO: document these in README's for each recipe.

## Troubleshooting

Usually your first few deployments will fail. Look at the deploy logs. Then head back to your ssh prompt.

1. `su -l deploy` become the deploy user from root (or `sudo su -l deploy` from your user account)`
1. `tmux` if you know how; learn if you don't. It saves a ton of hassle.
1. `cd /srv/www/your_app_dir/` and poke around a bit to understand the OpsWorks deployment strategy.
1. `cd /srv/www/your_app_dir/current`
1. If your app isn't there, there's a cloning problem, probably with your deployment keys.
1. Can you run `bundle install`? Fix any bundler problems. Private Gems are a special annoyance. We're working on a recipe to help, but as a manual workaround, `ssh-keygen` a pair for the deploy user and add the public key to the private gem's deploy keys.
1. Can you run `bundle exec rails s -e production`? If not, does `bundle exec rails c -e production` shed any light as to why?
1. Can you connect to your database using `mysql`? If not, check your RDS security group inbound rules.
1. `ls -l`. Have you accidently messed around as root and made some files or directories deploy can't change?
1. `pgrep -fl unicorn`. Is Unicorn running? How about nginx?
1. Check your layer's security group. Are you allowing inbound HTTP(S)?
1. Look at `config/database.yml` and `config/application.yml` (if you're using Figaro). Do they look right?
1. Look over the deploy logs again. Also check the application's log/ directory.
1. Make sure you've pushed your application edits to the right branch and try another deploy.

There are more things that can go wrong, but this list will catch the bulk of problems.

