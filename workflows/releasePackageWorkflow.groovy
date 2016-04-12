import groovy.json.JsonSlurper

node('rhel') {
    stage "Identify Bugs"

        def repoName = gitRepository.split('/')[1]
        def releaseTag = ''

        dir(repoName) {
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {
            
                git url: "https://${env.USERNAME}:${env.PASSWORD}@${env.GIT_HOSTNAME}/${gitRepository}.git", branch: releaseBranch

            }
        }

        dir('tool_belt') {
            git url: "https://${env.GIT_HOSTNAME}/satellite6/tool_belt.git", branch: 'master'
            sh 'bundle install'
        }

        dir(repoName) {
            sh "../tool_belt/tools.rb release find-bz-ids --output-file bz_ids.json"
            archive 'bz_ids.json'
        }


    stage "Move Bugs to Modified"
    
        dir(repoName) {
            def ids = readFile 'bz_ids.json'
            ids = new JsonSlurper().parseText(ids)
            ids = ids.join(' --bug ')
  
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'bugzilla-credentials', passwordVariable: 'BZ_PASSWORD', usernameVariable: 'BZ_USERNAME']]) {
    
                echo ids.toString()
                sh "../tool_belt/tools.rb bugzilla move-to-modified --username ${env.BZ_USERNAME} --password ${env.BZ_PASSWORD} --bug ${ids}"
  
            }
        }


    stage "Bump Version"
            
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-gitlab', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME']]) {

            dir(repoName) {
                sh "git config user.email 'sat6-jenkins@redhat.com'"
                sh "git config user.name 'Jenkins'"

                sh "../tool_belt/tools.rb release bump-version --output-file version.json"
                archive "version.json"
                releaseTag = readFile 'version.json'

                sh "git push origin ${releaseBranch}"
                sh "git push origin ${releaseTag}"
            }

        }


    stage "Build Source"

        dir(repoName) {

            def artifact = ''            

            sh "../tool_belt/tools.rb release build-source --type ${sourceType} --output-file artifact"
            artifact = readFile 'artifact'
            
            sh "scp ${artifact} jenkins@${env.SOURCE_FILE_HOST}:/var/www/html/pub/sources/6.2"
            sh "rm artifact"

        }

}
