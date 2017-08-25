import groovy.json.JsonOutput
import groovy.json.JsonSlurper

def post(body) {
    // evaluate the body block, and collect configuration into the object
    def config = [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = config
    body()

    def HttpURLConnection connection = config.url.openConnection()

    connection.setRequestMethod("POST")
    connection.setRequestProperty("Content-Type", "application/json")
    connection.setRequestProperty("Accept", "application/json")
    connection.setDoOutput(true)
    connection.setDoInput(true)

    OutputStreamWriter writer = new OutputStreamWriter(connection.getOutputStream())
    writer.write(config.json)
    writer.flush()
    writer.close()

    try {
        connection.connect()
        response = new JsonSlurper().parse(new InputStreamReader(connection.getInputStream(),"UTF-8"))
    } finally {
        connection.disconnect()
    }
}
