def compose_rhel_versions = ['7']
def tools_compose_rhel_versions = ['8', '7', '6', '5']
def tools_compose_sles_versions = ['11.4', '12.3', '12.4', '15.1']

def os_versions = ['7']

def satellite_short_version = 67
def satellite_main_version = '6.7'
def satellite_version = '6.7.0'

def satellite_repositories = [
    "Satellite ${satellite_main_version} RHEL7",
]

def capsule_repositories = [
    "Satellite Capsule ${satellite_main_version} RHEL7",
]

def tools_repositories = [
    "Satellite Tools ${satellite_main_version} RHEL8 x86_64",
    "Satellite Tools ${satellite_main_version} RHEL8 ppc64le",
    "Satellite Tools ${satellite_main_version} RHEL8 s390x",
    "Satellite Tools ${satellite_main_version} RHEL8 aarch64",
    "Satellite Tools ${satellite_main_version} RHEL7 x86_64",
    "Satellite Tools ${satellite_main_version} RHEL7 ppc64le",
    "Satellite Tools ${satellite_main_version} RHEL7 ppc64",
    "Satellite Tools ${satellite_main_version} RHEL7 s390x",
    "Satellite Tools ${satellite_main_version} RHEL7 aarch64",
    "Satellite Tools ${satellite_main_version} RHEL6 x86_64",
    "Satellite Tools ${satellite_main_version} RHEL6 i386",
    "Satellite Tools ${satellite_main_version} RHEL6 ppc64",
    "Satellite Tools ${satellite_main_version} RHEL6 s390x",
    "Satellite Tools ${satellite_main_version} RHEL5 x86_64",
    "Satellite Tools ${satellite_main_version} RHEL5 i386",
    "Satellite Tools ${satellite_main_version} RHEL5 s390x",
    "Satellite Tools ${satellite_main_version} SLES11.4 x86_64",
    "Satellite Tools ${satellite_main_version} SLES12.3 x86_64",
    "Satellite Tools ${satellite_main_version} SLES12.4 x86_64",
    "Satellite Tools ${satellite_main_version} SLES15.1 x86_64",
]

def satellite_content_views = [
    "Satellite ${satellite_main_version} RHEL7",
]

def capsule_content_views = [
    "Capsule ${satellite_main_version} RHEL7",
]

def tools_content_views = [
    "Tools ${satellite_main_version} RHEL8",
    "Tools ${satellite_main_version} RHEL7",
    "Tools ${satellite_main_version} RHEL6",
    "Tools ${satellite_main_version} RHEL5",
    "Tools ${satellite_main_version} SLES11.4",
    "Tools ${satellite_main_version} SLES12.3",
    "Tools ${satellite_main_version} SLES12.4",
    "Tools ${satellite_main_version} SLES15.1",
]

def content_views = satellite_content_views + capsule_content_views + tools_content_views

def satellite_composite_content_views = [
    "Satellite ${satellite_main_version} with RHEL7 Server",
]
def capsule_composite_content_views = [
    "Capsule ${satellite_main_version} with RHEL7 Server",
]
def tools_composite_content_views = [
    "Tools ${satellite_main_version} with RHEL8 Server",
    "Tools ${satellite_main_version} with RHEL7 Server",
    "Tools ${satellite_main_version} with RHEL6 Server",
    "Tools ${satellite_main_version} with RHEL5 Server",
]
def composite_content_views = satellite_composite_content_views + capsule_composite_content_views + tools_composite_content_views

def tools_sles_content_views = [
    "Tools ${satellite_main_version} SLES11.4",
    "Tools ${satellite_main_version} SLES12.3",
    "Tools ${satellite_main_version} SLES12.4",
    "Tools ${satellite_main_version} SLES15.1",
]

def satellite_activation_keys = [
    "satellite-${satellite_main_version}-qa-rhel7",
]
def capsule_activation_keys = [
    "capsule-${satellite_main_version}-qa-rhel7",
]
def tools_activation_keys = [
    "satellite-tools-${satellite_main_version}-qa-rhel8",
    "satellite-tools-${satellite_main_version}-qa-rhel7",
    "satellite-tools-${satellite_main_version}-qa-rhel6",
    "satellite-tools-${satellite_main_version}-qa-rhel5",
    "satellite-tools-${satellite_main_version}-qa-sles11-4",
    "satellite-tools-${satellite_main_version}-qa-sles12-3",
    "satellite-tools-${satellite_main_version}-qa-sles12-4",
    "satellite-tools-${satellite_main_version}-qa-sles15-1",
]
def satellite_product = 'satellite'
