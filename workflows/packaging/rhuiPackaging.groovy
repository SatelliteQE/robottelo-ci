def package_version = env.gitlabTargetBranch.minus('RHUI-')
def packaging_repo = 'rhui-packaging'
def packaging_repo_project = 'RHUI'
def tool_belt_config = './configs/rhui/'
def tool_belt_repo_folder = "rhui_${package_version}"
