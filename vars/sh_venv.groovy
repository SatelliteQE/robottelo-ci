def call(Object param = [:]) {

    if (param in String) param = [body: param]

    def body = param.get('body', "")
    def venv = param.get('venv', ".env")

    sh """
        source ${venv}/bin/activate
        ${body}
    """
}
