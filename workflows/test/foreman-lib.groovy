def configure_foreman_environment() {
    try {
        sh "cp config/settings.yaml.example config/settings.yaml"
        sh "sed -i 's/:locations_enabled: false/:locations_enabled: true/' config/settings.yaml"
        sh "sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' config/settings.yaml"

        sh "cp $HOME/postgresql.db.yaml config/database.yml"

        sh "sed -i 's/database:.*/database: ${gemset()}-test/' config/database.yml"
        sh """
cat <<EOT >> config/database.yml
development:
  adapter: postgresql
  database: ${gemset()}-development
  username: foreman
  password: foreman
  host: localhost
  template: template0
production:
  adapter: postgresql
  database: ${gemset()}-development
  username: foreman
  password: foreman
  host: localhost
  template: template0
EOT
        """
    } catch(all) {

        updateGitlabCommitStatus state: 'failed'
        cleanup(get_ruby_version())
        throw(all)

    }
}

def get_ruby_version() {
  target_branch = env.getProperty('gitlabTargetBranch')
  return branch_map[target_branch]['ruby']
}

def setup_foreman(ruby = '2.2') {
    try {

        withRVM(['gem install bundler'], ruby)
        withRVM(['bundle install --without mysql:mysql2:development'], ruby)

        if (fileExists('package.json')) {
            withRVM(['npm install npm@\\<"5.0.0"'], ruby)
            withRVM(['./node_modules/.bin/npm install --no-optional --global-style true'], ruby)
            withRVM(['npm install phantomjs'], ruby)
            withRVM(['./node_modules/webpack/bin/webpack.js --bail --config config/webpack.config.js'], ruby)
        }

        // Create DB first in development as migrate behaviour can change
        withRVM(['bundle exec rake db:drop db:create db:migrate DISABLE_DATABASE_ENVIRONMENT_CHECK=true'], ruby)

    } catch (all) {

        updateGitlabCommitStatus state: 'failed'
        cleanup(get_ruby_version())
        throw(all)

    }
}

def setup_plugin(plugin_name, ruby = '2.2') {
    try {
        // Ensure we don't mention the gem twice in the Gemfile in case it's already mentioned there
        sh "find Gemfile bundler.d -type f -exec sed \"/gem ['\\\"]${plugin_name}['\\\"]/d\" {} \\;"
        // Now let's introduce the plugin
        sh "echo \"gem '${plugin_name}', :path => '\$(pwd)/../plugin'\" >> bundler.d/Gemfile.local.rb"
        // Plugin specifics..
        if(fileExists("../plugin/gemfile.d/${plugin_name}.rb")) {
            sh "cat ../plugin/gemfile.d/${plugin_name}.rb >> bundler.d/Gemfile.local.rb"
        }

        withRVM(['bundle update'], ruby)

        withRVM(['bundle exec rake db:migrate RAILS_ENV=development'], ruby)

    } catch (all) {

        updateGitlabCommitStatus state: 'failed'
        cleanup(get_ruby_version())
        throw(all)

    }
}

def cleanup(ruby = '2.2') {
    try {

        sh "rm -rf node_modules/"
        withRVM(['bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true'], ruby)

    } finally {

        cleanup_rvm('', ruby)

    }
}
