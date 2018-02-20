def package_version = env.gitlabTargetBranch.minus('SATELLITE-')
def packaging_repo = 'satellite-packaging'
def packaging_repo_project = 'satellite6'
def tool_belt_config = './configs/satellite/'
def tool_belt_repo_folder = "satellite_${package_version}"
