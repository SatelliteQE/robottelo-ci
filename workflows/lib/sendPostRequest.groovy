@NonCPS
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

    try {
        OutputStreamWriter writer = new OutputStreamWriter(connection.getOutputStream())
        writer.write(config.json)
        writer.flush()
        writer.close()
        connection.connect()
        input = new InputStreamReader(connection.getInputStream(),"UTF-8")
        response = readJSON(text: input.toString())
    }

    catch(Exception e) {
      println e.getMessage()
    }

    finally {
        connection.disconnect()
    }
}
