def compose_versions = ['7']
def tools_compose_versions = ['7', '6', '5']

def os_versions = ['7']

def satellite_short_version = 64
def satellite_main_version = '6.4'
def satellite_version = '6.4.0'

def satellite_repositories = [
    "Satellite 6.4 RHEL7",
]

def capsule_repositories = [
    "Satellite Capsule 6.4 RHEL7",
]

def tools_repositories = [
    "Satellite Tools 6.4 RHEL7 x86_64",
    "Satellite Tools 6.4 RHEL7 ppc64le",
    "Satellite Tools 6.4 RHEL7 ppc64",
    "Satellite Tools 6.4 RHEL7 s390x",
    "Satellite Tools 6.4 RHEL7 aarch64",
    "Satellite Tools 6.4 RHEL6 x86_64",
    "Satellite Tools 6.4 RHEL6 i386",
    "Satellite Tools 6.4 RHEL6 ppc64",
    "Satellite Tools 6.4 RHEL6 s390x",
    "Satellite Tools 6.4 RHEL5 x86_64",
    "Satellite Tools 6.4 RHEL5 i386",
    "Satellite Tools 6.4 RHEL5 s390x",
]

def content_views = [
    'Satellite 6.4 RHEL7',
    'Capsule 6.4 RHEL7',
    'Tools 6.4 RHEL7',
    'Tools 6.4 RHEL6',
    'Tools 6.4 RHEL5'
]

def composite_content_views = [
    'Satellite 6.4 with RHEL7 Server',
    'Capsule 6.4 with RHEL7 Server',
    'Tools 6.4 with RHEL7 Server',
    'Tools 6.4 with RHEL6 Server',
    'Tools 6.4 with RHEL5 Server'
]
