Get an OAUTH token for Github
-----------------------------
1. Create a new github user that has access ONLY to the repository of the private gem you want to use.
2. Login with that user and go the user's applications settings (https://github.com/settings/applications).
3. Hit Generate new token
4. Add a token description that indicates this is being used for deployments.
5. Remove ALL scopes EXCEPT "repo".
6. Copy the token.  You will not be able to access it again.  If you need to make a change in the future you will need to generate a completely new token.


Local Use
---------
You will need to use the Oauth token in your Gemfile, but will not want to commit it into the repo.  To do this use an environment variable.  You can name this variable however you choose, and how you setup the environment variable is up to you.  I added it to my profile like this:
```
export OMNIAUTH_REPO_TOKEN=2200f.....
```

Once you have the environment variable set you can change your Gemfile declaration of the private gem to look like this:
````
gem 'omniauth-bibles', git: "https://#{ENV['OMNIAUTH_REPO_TOKEN']}:x-oauth-basic@github.com/americanbible/omniauth-bibles.git"
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

This would set an environment variable in the travis build environment.  The name and value of the variable is securely encrypted in the "secure" line.  To generate your own encrypted version of your OAUTH token use the travis command line tool:
```
travis encrypt OMNIAUTH_REPO_TOKEN=as;dfkjqopwieua;lkdjf
```

OpsWorks
--------
Finally, to get the environment variable to your server you will want to use the "opsworks\_custom_env" recipe in this repo.  In your stack settings set the stack to use a custom cookbook and set it to this repository.  Then in the Custom Chef JSON field add this:
```
{
  "custom_env": {
    "yourappname": {
      "OMNIAUTH_REPO_TOKEN": "2200fc...."
    }
  }
}
```

You will also need to go to the Layer settings and enable that recipe.  Look for the Deploy field in the Custom Chef Recipes section and add "opsworks_custom_env::configure".  I also added the "opsworks_custom_env:\:write_config" to the Configure section.  This makes sure that the application.yml file is written early enough in the startup cycle.

Unfortunately due to the way that the chef recipes do the initial bundle install, it won't pick up your environment variables, which leaves you in a bit of a problem.  I've determined that I needed to manually get the value from the config/application.yml file.  I did that by adding this to the top of the Gemfile (which is just ruby):

```
omniauth_token = `grep OMNIAUTH config/application.yml`
omniauth_token = omniauth_token.gsub(/OMNIAUTH_REPO_TOKEN:/, "").gsub(/['"\s\t\n]/, "")
```

Then you can use the variable in your gem declaration like any variable:
```
gem 'omniauth-bibles', '= 0.0.2', git: "https://#{omniauth_token}:x-oauth-basic@github.com/americanbible/omniauth-bibles.git", branch: 'develop'
```