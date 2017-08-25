def sendSnapperMessage(stage_name) {

    def body = [
        "name": env.JOB_NAME,
        "build": [
                  "full_url": env.BUILD_URL,
                  "status": currentBuild.status,
                  "phase": (currentBuild.status == 'FAILURE') ? "COMPLETED" : stage_name,
        ]
    ]

    def api_url = new URL(env.SNAPPER_URL)

    post {
        url = api_url
        json = json_body
    }

    error('Build failed, messaging Snapper')
}

def snapperStage(name, body) {
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config

    try {
        stage(name) {
            body()
        }
    }

    catch(any) {
        currentBuild.result = 'FAILURE'
        error()
    }

    finally {
        sendSnapperMessage(name)
    }
}
