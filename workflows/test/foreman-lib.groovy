def configure_foreman_environment() {
    try {
        sh "cp config/settings.yaml.example config/settings.yaml"
        sh "sed -i 's/:locations_enabled: false/:locations_enabled: true/' config/settings.yaml"
        sh "sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' config/settings.yaml"

        sh "cp $HOME/postgresql.db.yaml config/database.yml"

        sh "sed -i 's/database:.*/database: ${gemset()}-test/' config/database.yml"
        sh """
cat <<EOT >> config/database.yml
test:
  adapter: postgresql
  database: ${gemset()}-test
  username: foreman
  password: foreman
  host: localhost
  template: template0
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
        cleanup(get_ruby_version(branch_map))
        throw(all)

    }
}

def get_ruby_version(branches) {
  target_branch = env.getProperty('gitlabTargetBranch')
  return branches[target_branch]['ruby']
}

def setup_foreman(ruby = '2.2') {
    try {

        configureRVM(ruby)

        withRVM(['bundle install --jobs=5 --retry=2 --without mysql:mysql2'], ruby)

        // Create DB first in development as migrate behaviour can change
        withRVM(['bundle exec rake db:drop -q || true'], ruby)
        withRVM(['bundle exec rake db:create -q'], ruby)
        withRVM(['bundle exec rake db:migrate -q'], ruby)

        if (fileExists('package.json')) {
              sh 'npm install npm'
              sh 'npm install phantomjs'
              withRVM(['./node_modules/.bin/npm install'], ruby)
        }

    } catch (all) {

        updateGitlabCommitStatus state: 'failed'
        cleanup(get_ruby_version(branch_map))
        throw(all)

    }
}

def setup_plugin(plugin_name) {
        // Ensure we don't mention the gem twice in the Gemfile in case it's already mentioned there
        sh "find Gemfile bundler.d -type f -exec sed -i \"/gem ['\\\"]${plugin_name}['\\\"]/d\" {} \\;"
        // Now let's introduce the plugin
        sh "echo \"gemspec :path => '\$(pwd)/../plugin', :name => '${plugin_name}', :development_group => '${plugin_name}_dev'\" >> bundler.d/Gemfile.local.rb"
        // Plugin specifics..
        if(fileExists("../plugin/gemfile.d/${plugin_name}.rb")) {
            sh "cat ../plugin/gemfile.d/${plugin_name}.rb >> bundler.d/Gemfile.local.rb"
        }
}

def cleanup(ruby = '2.2') {
    try {

        sh "rm -rf node_modules/"
        withRVM(['bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true'], ruby)

    } finally {

        cleanupRVM(ruby)

    }
}
