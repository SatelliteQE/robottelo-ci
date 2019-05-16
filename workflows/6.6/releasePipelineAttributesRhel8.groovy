def compose_versions = ['8']
def tools_compose_versions = []

def os_versions = ['8']

def satellite_short_version = 66
def satellite_main_version = '6.6'
def satellite_version = '6.6.0'

def satellite_repositories = [
    "Satellite 6.6 RHEL8"
]

def capsule_repositories = [
    "Satellite Capsule 6.6 RHEL8",
]

def tools_repositories = []

def satellite_content_views = [
    'Satellite 6.6 RHEL8',
]

def capsule_content_views = [
    'Capsule 6.6 RHEL8',
]

def tools_content_views = []

def content_views = satellite_content_views + capsule_content_views + tools_content_views

def satellite_composite_content_views = [
    'Satellite 6.6 with RHEL8 Server',
]
def capsule_composite_content_views = [
    'Capsule 6.6 with RHEL8 Server',
]
def tools_composite_content_views = []
def composite_content_views = satellite_composite_content_views + capsule_composite_content_views + tools_composite_content_views

def satellite_activation_keys = [
    'satellite-6.6.0-qa-rhel8',
]
def capsule_activation_keys = [
    'capsule-6.6.0-qa-rhel8',
]
def tools_activation_keys = []
