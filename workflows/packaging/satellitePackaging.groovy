package_version = env.gitlabTargetBranch.minus('SATELLITE-')
packaging_repo = 'satellite-packaging'
packaging_repo_project = 'satellite6'
packaging_disttag = 'sat'
tool_belt_repo_folder = "satellite_${package_version}"
def tool_belt_config = './configs/satellite/'
