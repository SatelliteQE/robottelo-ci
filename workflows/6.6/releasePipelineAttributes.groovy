def compose_rhel_versions = ['7']
def tools_compose_rhel_versions = ['8', '7', '6', '5']
def tools_compose_sles_versions = []
def tools_sles_content_views = []

def os_versions = ['7']

def satellite_short_version = 66
def satellite_main_version = "6.6"
def satellite_version = "6.6.0"

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
    "Satellite Tools ${satellite_main_version} RHEL6 s390x",
    "Satellite Tools ${satellite_main_version} RHEL5 x86_64",
    "Satellite Tools ${satellite_main_version} RHEL5 i386",
    "Satellite Tools ${satellite_main_version} RHEL5 s390x",
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
]
def satellite_product = 'satellite'
