node('sat6-rhel7') {

    snapperStage('Setup Git Repos') {

        deleteDir()
        gitlab_clone_and_merge('foreman')

    }

    snapperStage('Configure Environment') {

        try {
            sh "cp config/settings.yaml.example config/settings.yaml"
            sh "sed -i 's/:locations_enabled: false/:locations_enabled: true/' config/settings.yaml"
            sh "sed -i 's/:organizations_enabled: false/:organizations_enabled: true/' config/settings.yaml"

            sh "cp $HOME/postgresql.db.yaml config/database.yml"

            sh "sed -i \"s/database:.*/database: ${gemset()}-test/\" config/database.yml"
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

            cleanup()
            throw(all)

        }

    }

    snapperStage('Configure Database') {

        try {

            withRVM(['gem install bundler'], 2.2)
            withRVM(['bundle install --without mysql:mysql2:development'], 2.2)

            sh 'npm install npm@\\<"5.0.0"'
            sh './node_modules/.bin/npm install --no-optional --global-style true'
            sh './node_modules/webpack/bin/webpack.js --bail --config config/webpack.config.js'

            withRVM(['bundle exec rake db:drop db:create db:migrate'], 2.2)

        } catch (all) {

            cleanup()
            throw(all)

        }

    }

    snapperStage('Run Tests') {

        try {

            withRVM(['bundle exec rake jenkins:unit jenkins:integration TESTOPTS="-v"'], 2.2)

        } finally {

            cleanup()

            archive "Gemfile.lock pkg/*"
            junit keepLongStdio: true, testResults: 'jenkins/reports/unit/*.xml'

        }
    }

}

def cleanup() {
    try {

        sh "rm -rf node_modules/"
        withRVM(['bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=true'], 2.2)

    } finally {

        cleanup_rvm()

    }
}
