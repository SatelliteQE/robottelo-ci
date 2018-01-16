#!/usr/bin/env bash

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        RHEL6_TOOLS_PRD_ppc64="Red Hat Enterprise Linux for Power big endian"
        RHEL6_TOOLS_REPO_ppc64="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 for IBM Power RPMs ppc64"
        RHEL7_TOOLS_PRD_ppc64="Red Hat Enterprise Linux for Power big endian"
        RHEL7_TOOLS_REPO_ppc64="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 7 for IBM Power RPMs ppc64"
    fi
    satellite_runner repository-set enable --name="Red Hat Enterprise Linux 7 for IBM Power (Kickstart)" --basearch="ppc64" --releasever="7.4" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
    satellite_runner repository-set enable --name="Red Hat Enterprise Linux 6 for IBM Power (Kickstart)" --basearch="ppc64" --releasever="6.8" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"

    satellite_runner repository-set enable --name="Red Hat Enterprise Linux 7 for IBM Power (RPMs)" --basearch="ppc64" --releasever="7Server" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
    satellite_runner repository-set enable --name="Red Hat Enterprise Linux 6 for IBM Power (RPMs)" --basearch="ppc64" --releasever="6Server" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"

    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        # Satellite6 Tools RPMS
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
    fi
fi

# Synchronize all repositories except for Puppet repositories which don't have URLs
for repo in $(satellite --csv repository list --organization-id="${ORG}" --per-page=1000 | grep -vi 'puppet' | cut -d ',' -f 1 | grep -vi '^ID'); do
    satellite_runner repository synchronize --id "${repo}" --organization-id="${ORG}" --async
done

# Check the async tasks for completion.
for id in `satellite --csv task list | grep -i synchronize | awk -F "," '{print $1}'`; do satellite_runner task progress --id $id; done

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    #Create content views
    satellite_runner content-view create --name 'RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner content-view create --name 'RHEL 6 CV ppc64' --organization-id="${ORG}"

    # RHEL 7 ppc64
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product='Red Hat Enterprise Linux for Power big endian' --repository='Red Hat Enterprise Linux 7 for IBM Power Kickstart ppc64 7.4'
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product='Red Hat Enterprise Linux for Power big endian' --repository='Red Hat Enterprise Linux 7 for IBM Power RPMs ppc64 7Server'
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PRD_ppc64}" --repository="${RHEL7_TOOLS_REPO_ppc64}"
    satellite_runner  content-view publish --name='RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 6 ppc64
    satellite_runner  content-view add-repository --name='RHEL 6 CV ppc64' --organization-id="${ORG}" --product='Red Hat Enterprise Linux for Power big endian' --repository='Red Hat Enterprise Linux 6 for IBM Power Kickstart ppc64 6.8'
    satellite_runner  content-view add-repository --name='RHEL 6 CV ppc64' --organization-id="${ORG}" --product='Red Hat Enterprise Linux for Power big endian' --repository='Red Hat Enterprise Linux 6 for IBM Power RPMs ppc64 6Server'
    satellite_runner  content-view add-repository --name='RHEL 6 CV ppc64' --organization-id="${ORG}" --product="${RHEL6_TOOLS_PRD_ppc64}" --repository="${RHEL6_TOOLS_REPO_ppc64}"
    satellite_runner  content-view publish --name='RHEL 6 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 6 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # Activation Keys
    # Create activation keys
    satellite_runner  activation-key create --name 'ak-rhel-7-ppc64' --content-view='RHEL 7 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-6-ppc64' --content-view='RHEL 6 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"

    satellite_runner  activation-key update --name 'ak-rhel-7-ppc64' --auto-attach no --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-6-ppc64' --auto-attach no --organization-id="${ORG}"

    RHEL_SUBS_ID_ppc64=$(satellite --csv subscription list --organization-id=1 | grep -i "Red Hat Enterprise Linux for Power, BE" |  awk -F "," '{print $1}' | grep -vi id)

    satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_ppc64}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"
fi
