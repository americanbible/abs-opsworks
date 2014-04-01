If you have a gem that is getting loaded from a private github repo, this will cause problems when it's time to use an automated continuous integration and deployment system.  You need to have access to the private repo for the gem without committing private authentication information to the repository.  There are two basic methods for this sort of access: ssh keys and OAuth tokens.  For my purposes oauth tokens are easier to setup and move around.

Get an OAuth token for Github
-----------------------------
1. Create a new github user that has access ONLY to the repositories of the private gems you want to use.
2. Login with that user and go the user's applications settings (https://github.com/settings/applications).
3. Hit Generate new token
4. Add a token description that indicates this is being used for deployments.
5. Remove ALL scopes EXCEPT "repo".  You don't need anything else.
6. Copy the token.  You will not be able to access it again.  If you need to make a change in the future you will need to generate a completely new token.

The OAuth token has to be kept out of the repository.  Since we are using figaro to handle this sort of private information in our projects we will continue to use that as a source of information for local building and the deployment system, but for continuous integration (Travis CI) we'll also need another option.  Travis doesn't have a way of generating the application.yml file we need, so we use environment variables as well.  In the end you can use whichever method works for the system you are working in.

For both cases we'll rely on a small bit of ruby in the project Gemfile to load up the private information, either from the environment or the figaro application.yml file.  At the top of the Gemfile you will need to look for the information in the environment, and if it isn't found then look in the application.yml file.  The key to remember is that the Gemfile is just a ruby file, so you can run any ruby that will work as long as you don't need a gem.

```
token = ENV['OMNIAUTH_REPO_TOKEN']
if token.nil?
  token = `grep TOKEN_NAME config/application.yml`
  token = token.gsub(/TOKEN_NAME:/, "").gsub(/['"\s\t\n]/, "")
end
```

Now the token is loaded in a variable, and you can use that in the gem declaration.  OAuth tokens can be specified in the gem declaration like this:
```
gem 'omniauth-bibles', git: "https://#{token}:x-oauth-basic@github.com/americanbible/omniauth-bibles.git"
```


Local Use
---------
You can provide the OAuth token either as an environment variable, or using the figaro config/application.yml file.  If you want to use an environment variable add this to your .profile file:
```
export OMNIAUTH_REPO_TOKEN=2200f.....
```

Otherwise, add a config/application.yml file and add a line like this:
```
TOKEN_NAME: "abcdefg0123456789"
```

Do a bundle install, and you should see your private gem downloaded.


Travis CI
---------
To use the environment variable in the Travis CI environment you'll want to first install the travis cli tools (https://github.com/travis-ci/travis.rb).  Once that's setup you need to make sure you have a valid .travis.yml file in your project.  Assuming you have those two things setup, then you'll want to have an "env" section in your .travis file.

```
env:
  global:
    - secure: "PAVMfVqrh28m7ylp+SFEXswUyY4ML4CONst99dzNgJSfQhwzBGQAi2gZP5dL3uW8Bu0fYExN0RQOu/cZxJBgphraFoFfqSn1zKgiOarUcVlaNrW/h3NtFSIDdVQnZ7dQ4maQDg0R/qNV2tKec2qpzRWVRdylVoGUCUsJrsFFTuY="
```

This would set an environment variable in the travis build environment.  The name and value of the variable is securely encrypted in the "secure" line.  To generate your own encrypted version of your OAuth token use the travis command line tool:
```
travis encrypt TOKEN_NAME=abcdefg0123456789
```


OpsWorks
--------
Finally, to get the variable to your server as part of your deployment process in OpsWorks you will want to use the "opsworks\_custom_env" recipe in this repo.  In your stack settings set the stack to use a custom cookbook and set it to this repository.  Then in the Custom Chef JSON field add this:
```
{
  "custom_env": {
    "yourappname": {
      "TOKEN_NAME": "abcdefg0123456789"
    }
  }
}
```

You will also need to go to the Layer settings and enable that recipe.  Look for the Configure field in the Custom Chef Recipes section and add "opsworks_custom_env:\:write_config".  This makes sure that the application.yml file is written early enough in the startup cycle.

Unfortunately due to the way that the chef recipes do the initial bundle install, it won't pick environment variables, but it will have the config/application.yml file, thanks to the write_config recipe that we just added.  You'll need to restart any instances that are already running so that they get the recipe and run it.  After that your Gemfile should work normally.