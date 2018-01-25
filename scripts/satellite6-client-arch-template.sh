#!/usr/bin/env bash

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        RHEL6_TOOLS_PRD_ppc64="Red Hat Enterprise Linux for Power big endian"
        RHEL6_TOOLS_REPO_ppc64="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 for IBM Power RPMs ppc64"
        RHEL7_TOOLS_PRD_ppc64="Red Hat Enterprise Linux for Power big endian"
        RHEL7_TOOLS_REPO_ppc64="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 7 for IBM Power RPMs ppc64"
    else
        RHEL6_TOOLS_PPC64_PRD=Sat6Tools6ppc64
        RHEL6_TOOLS_PPC64_REPO=sat6tool6ppc64
        RHEL6_TOOLS_PPC64_URL="ppc64rhel6_tools_url"
        RHEL7_TOOLS_PPC64_PRD=Sat6Tools7ppc64
        RHEL7_TOOLS_PPC64_REPO=sat6tool7ppc4
        RHEL7_TOOLS_PPC64_URL="ppc64rhel7_tools_url"
    fi

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

if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
    create-repo "${RHEL6_TOOLS_PPC64_PRD}" "${RHEL6_TOOLS_PPC64_REPO}" "${RHEL6_TOOLS_PPC64_URL}"
    create-repo "${RHEL7_TOOLS_PPC64_PRD}" "${RHEL7_TOOLS_PPC64_REPO}" "${RHEL7_TOOLS_PPC64_URL}"
fi

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    #Create content views
    satellite_runner content-view create --name 'RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner content-view create --name 'RHEL 6 CV ppc64' --organization-id="${ORG}"

    # RHEL 7 ppc64
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PRD_ppc64}" --repository="${RHEL7_TOOLS_REPO_ppc64}"
    satellite_runner  content-view publish --name='RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 6 ppc64
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

    satellite_runner activation-key content-override --name 'ak-rhel-7' --content-label "rhel-7-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
    satellite_runner activation-key content-override --name 'ak-rhel-6' --content-label "rhel-6-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    satellite_runner activation-key content-override --name 'ak-rhel-7-ppc64' --content-label "rhel-7-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
    satellite_runner activation-key content-override --name 'ak-rhel-6-ppc64' --content-label "rhel-6-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    # As SATELLITE TOOLS REPO is already part of RHEL subscription.
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        TOOLS6_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL6_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        TOOLS7_SUBS_ID=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL7_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID}"
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID}"
    fi
fi
