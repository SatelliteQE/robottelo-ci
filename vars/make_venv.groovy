def call(Object param = [:]) {

    if (param in String) param = [venv: param]

    def venv = param.get('venv', defaults.venv)
    def venvModule = param.get('venvModule', defaults.venvModule)
    def python = param.get('python', defaults.python)

    sh """
        rm -rf ${venv}
        ${python} -m ${venvModule} ${venv}
        source ${venv}/bin/activate
        pip install -U pip
    """
}
