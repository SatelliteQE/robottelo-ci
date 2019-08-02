package_version = env.gitlabTargetBranch.minus('SATELLITE-')
packaging_repo = 'satellite-packaging'
packaging_repo_project = 'satellite6'
tool_belt_repo_folder = "satellite_${package_version}"
def tool_belt_config = './configs/satellite/'
