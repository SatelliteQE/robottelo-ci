#!/usr/bin/env bash

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        RHEL6_TOOLS_PPC64_PRD="Red Hat Enterprise Linux for Power big endian"
        RHEL6_TOOLS_PPC64_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 for IBM Power RPMs ppc64"
        RHEL7_TOOLS_PPC64_PRD="Red Hat Enterprise Linux for Power big endian"
        RHEL7_TOOLS_PPC64_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 7 for IBM Power RPMs ppc64"

        RHEL6_TOOLS_S390X_PRD="Red Hat Enterprise Linux for IBM z Systems"
        RHEL6_TOOLS_S390X_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 for System Z RPMs s390x"
        RHEL7_TOOLS_S390X_PRD="Red Hat Enterprise Linux for IBM z Systems"
        RHEL7_TOOLS_S390X_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 7 for System Z RPMs s390x"

        RHEL6_TOOLS_I386_PRD="Red Hat Enterprise Linux Server"
        RHEL6_TOOLS_I386_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 6 Server RPMs i386"
    else
        RHEL6_TOOLS_PPC64_PRD=Sat6Tools6ppc64
        RHEL6_TOOLS_PPC64_REPO=sat6tool6ppc64
        RHEL6_TOOLS_PPC64_URL="ppc64rhel6_tools_url"
        RHEL7_TOOLS_PPC64_PRD=Sat6Tools7ppc64
        RHEL7_TOOLS_PPC64_REPO=sat6tool7ppc4
        RHEL7_TOOLS_PPC64_URL="ppc64rhel7_tools_url"

        RHEL6_TOOLS_S390X_PRD=Sat6Tools6s390x
        RHEL6_TOOLS_S390X_REPO=sat6tool6s390x
        RHEL6_TOOLS_S390X_URL="s390xrhel6_tools_url"
        RHEL7_TOOLS_S390X_PRD=Sat6Tools7s390x
        RHEL7_TOOLS_S390X_REPO=sat6tool7s390x
        RHEL7_TOOLS_S390X_URL="s390xrhel7_tools_url"

        RHEL6_TOOLS_I386_PRD=Sat6Tools6i386
        RHEL6_TOOLS_I386_REPO=sat6tool6i386
        RHEL6_TOOLS_I386_URL="i386rhel6_tools_url"
    fi

    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        # Satellite6 Tools RPMS
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"

        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 for System Z) (RPMs)" --basearch="s390x" --product "Red Hat Enterprise Linux for IBM z Systems" --organization-id="${ORG}"
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 for System Z) (RPMs) " --basearch="s390x" --product "Red Hat Enterprise Linux for IBM z Systems" --organization-id="${ORG}"

        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 Server) (RPMs)" --basearch="i386" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
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

    create-repo "${RHEL6_TOOLS_S390X_PRD}" "${RHEL6_TOOLS_S390X_REPO}" "${RHEL6_TOOLS_S390X_URL}"
    create-repo "${RHEL7_TOOLS_S390X_PRD}" "${RHEL7_TOOLS_S390X_REPO}" "${RHEL7_TOOLS_S390X_URL}"

    create-repo "${RHEL6_TOOLS_I386_PRD}" "${RHEL6_TOOLS_I386_REPO}" "${RHEL6_TOOLS_I386_URL}"
fi

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    #Create content views
    satellite_runner content-view create --name 'RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner content-view create --name 'RHEL 6 CV ppc64' --organization-id="${ORG}"

    satellite_runner content-view create --name 'RHEL 7 CV s390x' --organization-id="${ORG}"
    satellite_runner content-view create --name 'RHEL 6 CV s390x' --organization-id="${ORG}"

    satellite_runner content-view create --name 'RHEL 6 CV i386' --organization-id="${ORG}"

    # RHEL 7 ppc64
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PPC64_PRD}" --repository="${RHEL7_TOOLS_PPC64_REPO}"
    satellite_runner  content-view publish --name='RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 7 s390x
    satellite_runner  content-view add-repository --name='RHEL 7 CV s390x' --organization-id="${ORG}" --product="${RHEL7_TOOLS_S390X_PRD}" --repository="${RHEL7_TOOLS_S390X_REPO}"
    satellite_runner  content-view publish --name='RHEL 7 CV s390x' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV s390x' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 6 ppc64
    satellite_runner  content-view add-repository --name='RHEL 6 CV ppc64' --organization-id="${ORG}" --product="${RHEL6_TOOLS_PPC64_PRD}" --repository="${RHEL6_TOOLS_PPC64_REPO}"
    satellite_runner  content-view publish --name='RHEL 6 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 6 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 6 s390x
    satellite_runner  content-view add-repository --name='RHEL 6 CV s390x' --organization-id="${ORG}" --product="${RHEL6_TOOLS_S390X_PRD}" --repository="${RHEL6_TOOLS_S390X_REPO}"
    satellite_runner  content-view publish --name='RHEL 6 CV s390x' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 6 CV s390x' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # RHEL 6 i386
    satellite_runner  content-view add-repository --name='RHEL 6 CV i386' --organization-id="${ORG}" --product="${RHEL6_TOOLS_I386_PRD}" --repository="${RHEL6_TOOLS_I386_REPO}"
    satellite_runner  content-view publish --name='RHEL 6 CV i386' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 6 CV i386' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # Activation Keys
    # Create activation keys
    satellite_runner  activation-key create --name 'ak-rhel-7-ppc64' --content-view='RHEL 7 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-6-ppc64' --content-view='RHEL 6 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"

    satellite_runner  activation-key update --name 'ak-rhel-7-ppc64' --auto-attach no --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-6-ppc64' --auto-attach no --organization-id="${ORG}"

    satellite_runner  activation-key create --name 'ak-rhel-7-s390x' --content-view='RHEL 7 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-6-s390x' --content-view='RHEL 6 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"

    satellite_runner  activation-key update --name 'ak-rhel-7-s390x' --auto-attach no --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-6-s390x' --auto-attach no --organization-id="${ORG}"

    satellite_runner  activation-key create --name 'ak-rhel-6-i386' --content-view='RHEL 6 CV i386' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-6-i386' --auto-attach no --organization-id="${ORG}"

    RHEL_SUBS_ID_ppc64=$(satellite --csv subscription list --organization-id=1 | grep -i "Red Hat Enterprise Linux for Power, BE" |  awk -F "," '{print $1}' | grep -vi id)
    RHEL_SUBS_ID_s390x=$(satellite --csv subscription list --organization-id=1 | grep -i "Red Hat Enterprise Linux for IBM System z, Standard" |  awk -F "," '{print $1}' | grep -vi id)

    satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_ppc64}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_ppc64}"

    satellite_runner  activation-key add-subscription --name='ak-rhel-7-s390x' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_s390x}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-6-s390x' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_s390x}"

    satellite_runner  activation-key add-subscription --name='ak-rhel-6-i386' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"

    satellite_runner activation-key content-override --name 'ak-rhel-7' --content-label "rhel-7-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
    satellite_runner activation-key content-override --name 'ak-rhel-6' --content-label "rhel-6-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    satellite_runner activation-key content-override --name 'ak-rhel-7-ppc64' --content-label "rhel-7-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
    satellite_runner activation-key content-override --name 'ak-rhel-6-ppc64' --content-label "rhel-6-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    satellite_runner activation-key content-override --name 'ak-rhel-7-s390x' --content-label "rhel-7-for-system-z-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
    satellite_runner activation-key content-override --name 'ak-rhel-6-s390x' --content-label "rhel-6-for-system-z-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    satellite_runner activation-key content-override --name 'ak-rhel-6-i386' --content-label "rhel-6-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    # As SATELLITE TOOLS REPO is already part of RHEL subscription.
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        TOOLS6_SUBS_ID_ppc64=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL6_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        TOOLS7_SUBS_ID_ppc64=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL7_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_ppc64}"
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID_ppc64}"

        TOOLS6_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL6_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        TOOLS7_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL7_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_s390x}"
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID_s390x}"

        TOOLS6_SUBS_ID_i386=$(satellite  --csv subscription list --organization-id=1 --search="name=${RHEL6_TOOLS_I386_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        satellite_runner  activation-key add-subscription --name='ak-rhel-6-i386' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_i386}"
    fi
fi
