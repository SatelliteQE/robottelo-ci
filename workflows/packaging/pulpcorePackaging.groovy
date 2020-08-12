package_version = env.gitlabTargetBranch.minus('PULPCORE-')
packaging_repo = 'pulpcore-packaging'
packaging_repo_project = 'satellite6'
packaging_disttag = 'pc'
tool_belt_repo_folder = "pulpcore_${package_version}"
def tool_belt_config = './configs/pulpcore/'
