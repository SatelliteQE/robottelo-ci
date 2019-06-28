def call(Object param = [:]) {

    if (param in String) param = [script: param]

    def script = param.get('script', "")
    def venv = param.get('venv', ".env")
    def label = param.get('label', "")
    def stdo = param.get('returnStdout', false)
    def rtnc = param.get('returnStatus', false)


    def result = sh label: label, returnStatus: rtnc, returnStdout: stdo, script: """
        source ${venv}/bin/activate
        ${script}
    """
    return result
}
