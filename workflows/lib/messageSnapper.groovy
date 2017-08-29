def sendSnapperMessage(stage_name) {

    def body = [
        "name": env.JOB_NAME,
        "build": [
                  "full_url": env.BUILD_URL,
                  "status": currentBuild.result,
                  "phase": (currentBuild.result == 'FAILURE') ? "COMPLETED" : stage_name,
        ]
    ]

    def api_url = new URL(env.SNAPPER_URL)
    def json_body = JsonOutput.toJson(body)

    post {
        url = api_url
        json = json_body
    }
}

def snapperStage(name, body) {
    def config = [:]
    body.resolveStrategy = Closure.OWNER_FIRST
    body.delegate = config

    try {
        stage(name) {
            body()
        }
    }

    catch(any) {
        currentBuild.result = 'FAILURE'
        error('Build failed, messaging Snapper')
    }

    finally {
        sendSnapperMessage(name)
    }
}
