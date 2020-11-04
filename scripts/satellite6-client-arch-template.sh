#!/usr/bin/env bash

POPULATE_RHEL5=""
POPULATE_RHEL6=""
POPULATE_RHEL8=""

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        RHEL5_TOOLS_PRD="Red Hat Enterprise Linux Server"
        RHEL5_TOOLS_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 5 Server RPMs x86_64"
        RHEL5_TOOLS_PPC64_PRD="Red Hat Enterprise Linux for Power big endian"
        RHEL5_TOOLS_PPC64_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 5 for IBM Power RPMs ppc"
        RHEL5_TOOLS_S390X_PRD="Red Hat Enterprise Linux for IBM z Systems"
        RHEL5_TOOLS_S390X_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 5 for System Z RPMs s390x"
        RHEL5_TOOLS_I386_PRD="Red Hat Enterprise Linux Server"
        RHEL5_TOOLS_I386_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 5 Server RPMs i386"
        RHEL5_TOOLS_IA64_PRD="Red Hat Enterprise Linux Server"
        RHEL5_TOOLS_IA64_REPO="Red Hat Satellite Tools ${SAT_VERSION} for RHEL 5 Server RPMs ia64"

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
        RHEL5_TOOLS_PRD=Sat6Tools5
        RHEL5_TOOLS_REPO=sat6tool5
        RHEL5_TOOLS_URL="rhel5_tools_url"
        RHEL5_TOOLS_PPC64_PRD=Sat6Tools5ppc64
        RHEL5_TOOLS_PPC64_REPO=sat6tool5ppc64
        RHEL5_TOOLS_PPC64_URL="ppc64rhel5_tools_url"
        RHEL5_TOOLS_S390X_PRD=Sat6Tools5s390x
        RHEL5_TOOLS_S390X_REPO=sat6tool5s390x
        RHEL5_TOOLS_S390X_URL="s390xrhel5_tools_url"
        RHEL5_TOOLS_I386_PRD=Sat6Tools5i386
        RHEL5_TOOLS_I386_REPO=sat6tool5i386
        RHEL5_TOOLS_I386_URL="i386rhel5_tools_url"
        RHEL5_TOOLS_IA64_PRD=Sat6Tools5ia64
        RHEL5_TOOLS_IA64_REPO=sat6tool5ia64
        RHEL5_TOOLS_IA64_URL="ia64rhel5_tools_url"

        RHEL6_TOOLS_PPC64_PRD=Sat6Tools6ppc64
        RHEL6_TOOLS_PPC64_REPO=sat6tool6ppc64
        RHEL6_TOOLS_PPC64_URL="ppc64rhel6_tools_url"
        RHEL7_TOOLS_PPC64_PRD=Sat6Tools7ppc64
        RHEL7_TOOLS_PPC64_REPO=sat6tool7ppc64
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

        RHEL8_TOOLS_PRD=Sat6Tools8
        RHEL8_TOOLS_REPO=sat6tool8
        RHEL8_TOOLS_URL="rhel8_tools_url"
        RHEL8_TOOLS_PPC64LE_PRD=Sat6Tools8ppc64le
        RHEL8_TOOLS_PPC64LE_REPO=sat6tool8ppc64le
        RHEL8_TOOLS_PPC64LE_URL="ppc64lerhel8_tools_url"
        RHEL8_TOOLS_S390X_PRD=Sat6Tools8s390x
        RHEL8_TOOLS_S390X_REPO=sat6tool8s390x
        RHEL8_TOOLS_S390X_URL="s390xrhel8_tools_url"
        RHEL8_TOOLS_AARCH64_PRD=Sat6Tools8aarch64
        RHEL8_TOOLS_AARCH64_REPO=sat6tool8aarch64
        RHEL8_TOOLS_AARCH64_URL="aarch64rhel8_tools_url"
    fi

    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        # Satellite6 Tools RPMS
        if [[ "${POPULATE_RHEL5}" = 'true' ]]; then
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 5 for IBM Power) (RPMs)" --basearch="ppc" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 5 for System Z) (RPMs)" --basearch="s390x" --product "Red Hat Enterprise Linux for IBM z Systems" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 5 Server) (RPMs)" --basearch="i386" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 5 Server) (RPMs)" --basearch="ia64" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 5 Server) (RPMs)" --basearch="x86_64" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
        fi
        if [[ "${POPULATE_RHEL6}" = 'true' ]]; then
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 for System Z) (RPMs) " --basearch="s390x" --product "Red Hat Enterprise Linux for IBM z Systems" --organization-id="${ORG}"
            satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 6 Server) (RPMs)" --basearch="i386" --product "Red Hat Enterprise Linux Server" --organization-id="${ORG}"
        fi
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 for IBM Power) (RPMs)" --basearch="ppc64" --product "Red Hat Enterprise Linux for Power big endian" --organization-id="${ORG}"
        satellite_runner repository-set enable --name="Red Hat Satellite Tools ${SAT_VERSION} (for RHEL 7 for System Z) (RPMs)" --basearch="s390x" --product "Red Hat Enterprise Linux for IBM z Systems" --organization-id="${ORG}"
    fi
fi

#Create product and repository for errata
    create-repo "Errata-product" "Errata-repo" "https://repos.fedorapeople.org/pulp/pulp/demo_repos/test_simple_errata/"

# Synchronize all repositories except for Puppet repositories which don't have URLs
for repo in $(satellite --csv repository list --organization-id="${ORG}" --per-page=1000 | grep -vi 'puppet' | cut -d ',' -f 1 | grep -vi '^ID'); do
    satellite_runner repository synchronize --id "${repo}" --organization-id="${ORG}" --async
done

# Check the async tasks for completion.
for id in `satellite --csv task list | grep -i synchronize | awk -F "," '{print $1}'`; do satellite_runner task progress --id $id; done

if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
    if [[ "${POPULATE_RHEL5}" = 'true' ]]; then
        create-repo "${RHEL5_TOOLS_PRD}" "${RHEL5_TOOLS_REPO}" "${RHEL5_TOOLS_URL}"
        create-repo "${RHEL5_TOOLS_S390X_PRD}" "${RHEL5_TOOLS_S390X_REPO}" "${RHEL5_TOOLS_S390X_URL}"
        create-repo "${RHEL5_TOOLS_I386_PRD}" "${RHEL5_TOOLS_I386_REPO}" "${RHEL5_TOOLS_I386_URL}"
    fi
    if [[ "${POPULATE_RHEL6}" = 'true' ]]; then
        create-repo "${RHEL6_TOOLS_PPC64_PRD}" "${RHEL6_TOOLS_PPC64_REPO}" "${RHEL6_TOOLS_PPC64_URL}"
        create-repo "${RHEL6_TOOLS_S390X_PRD}" "${RHEL6_TOOLS_S390X_REPO}" "${RHEL6_TOOLS_S390X_URL}"
        create-repo "${RHEL6_TOOLS_I386_PRD}" "${RHEL6_TOOLS_I386_REPO}" "${RHEL6_TOOLS_I386_URL}"
    fi
    create-repo "${RHEL7_TOOLS_PPC64_PRD}" "${RHEL7_TOOLS_PPC64_REPO}" "${RHEL7_TOOLS_PPC64_URL}"
    create-repo "${RHEL7_TOOLS_S390X_PRD}" "${RHEL7_TOOLS_S390X_REPO}" "${RHEL7_TOOLS_S390X_URL}"
fi

if [[ "${POPULATE_CLIENTS_ARCH}" = 'true' ]]; then
    #Create content views
    satellite_runner content-view create --name 'RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner content-view create --name 'RHEL 7 CV s390x' --organization-id="${ORG}"
    satellite --csv content-view list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "RHEL 7" | while read -r line ; do
        satellite_runner  content-view add-repository --name="${line}" --organization-id="${ORG}" --product="Errata-product" --repository="Errata-repo"
    done
    satellite_runner  content-view add-repository --name='RHEL 7 CV ppc64' --organization-id="${ORG}" --product="${RHEL7_TOOLS_PPC64_PRD}" --repository="${RHEL7_TOOLS_PPC64_REPO}"
    satellite_runner  content-view add-repository --name='RHEL 7 CV s390x' --organization-id="${ORG}" --product="${RHEL7_TOOLS_S390X_PRD}" --repository="${RHEL7_TOOLS_S390X_REPO}"
    satellite_runner  content-view publish --name='RHEL 7 CV s390x' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV s390x' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"
    satellite_runner  content-view publish --name='RHEL 7 CV ppc64' --organization-id="${ORG}"
    satellite_runner  content-view version promote --content-view='RHEL 7 CV ppc64' --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library"

    # Activation Keys
    # Create activation keys
    satellite_runner  activation-key create --name 'ak-rhel-7-ppc64' --content-view='RHEL 7 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-7-s390x' --content-view='RHEL 7 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-7-s390x' --auto-attach no --organization-id="${ORG}"
    satellite_runner  activation-key update --name 'ak-rhel-7-ppc64' --auto-attach no --organization-id="${ORG}"

    RHEL_SUBS_ID_ppc64=$(satellite --csv subscription list --organization-id=${ORG} | grep -i "Red Hat Enterprise Linux for Power, BE" |  awk -F "," '{print $1}' | grep -vi id)
    RHEL_SUBS_ID_s390x=$(satellite --csv subscription list --organization-id=${ORG} | grep -i "Red Hat Enterprise Linux for IBM System z, Standard" |  awk -F "," '{print $1}' | grep -vi id)

    if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_ppc64}"
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-s390x' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_s390x}"

        satellite_runner activation-key content-override --name 'ak-rhel-7' --content-label "rhel-7-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
        satellite_runner activation-key content-override --name 'ak-rhel-7-ppc64' --content-label "rhel-7-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
        satellite_runner activation-key content-override --name 'ak-rhel-7-s390x' --content-label "rhel-7-for-system-z-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"

    fi
    if [[ "${POPULATE_RHEL6}" = 'true' ]]; then
        # RHEL 6
        for cv in 'RHEL 6 CV ppc64' 'RHEL 6 CV s390x' 'RHEL 6 CV i386'; do satellite_runner content-view create --name="${cv}" --organization-id="${ORG}"; done
        satellite_runner  content-view add-repository --name='RHEL 6 CV ppc64' --organization-id="${ORG}" --product="${RHEL6_TOOLS_PPC64_PRD}" --repository="${RHEL6_TOOLS_PPC64_REPO}"
        satellite_runner  content-view add-repository --name='RHEL 6 CV s390x' --organization-id="${ORG}" --product="${RHEL6_TOOLS_S390X_PRD}" --repository="${RHEL6_TOOLS_S390X_REPO}"
        satellite_runner  content-view add-repository --name='RHEL 6 CV i386' --organization-id="${ORG}" --product="${RHEL6_TOOLS_I386_PRD}" --repository="${RHEL6_TOOLS_I386_REPO}"
        satellite --csv content-view list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "RHEL 6" | while read -r line ; do
            satellite_runner  content-view add-repository --name="${line}" --organization-id="${ORG}" --product="Errata-product" --repository="Errata-repo"
        done
        for cv in 'RHEL 6 CV ppc64' 'RHEL 6 CV s390x' 'RHEL 6 CV i386'; do
            satellite_runner  content-view publish --name="${cv}" --organization-id="${ORG}";
            satellite_runner  content-view version promote --content-view="${cv}" --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library";
        done
        satellite_runner  activation-key create --name 'ak-rhel-6-ppc64' --content-view='RHEL 6 CV ppc64' --lifecycle-environment='DEV' --organization-id="${ORG}"
        satellite_runner  activation-key create --name 'ak-rhel-6-s390x' --content-view='RHEL 6 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"
        satellite_runner  activation-key create --name 'ak-rhel-6-i386' --content-view='RHEL 6 CV i386' --lifecycle-environment='DEV' --organization-id="${ORG}"
        for ak in 'ak-rhel-6-ppc64' 'ak-rhel-6-s390x' 'ak-rhel-6-i386'; do satellite_runner  activation-key update --name ${ak} --auto-attach no --organization-id="${ORG}"; done
        if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_ppc64}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-s390x' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_s390x}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-i386' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"

            satellite_runner activation-key content-override --name 'ak-rhel-6' --content-label "rhel-6-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
            satellite_runner activation-key content-override --name 'ak-rhel-6-ppc64' --content-label "rhel-6-for-power-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
            satellite_runner activation-key content-override --name 'ak-rhel-6-s390x' --content-label "rhel-6-for-system-z-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
            satellite_runner activation-key content-override --name 'ak-rhel-6-i386' --content-label "rhel-6-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
        fi
    fi
    if [[ "${POPULATE_RHEL5}" = 'true' ]]; then
        # RHEL 5
        for cv in 'RHEL 5 CV x86_64' 'RHEL 5 CV ppc64' 'RHEL 5 CV s390x' 'RHEL 5 CV i386' 'RHEL 5 CV ia64'; do satellite_runner content-view create --name="${cv}" --organization-id="${ORG}"; done
        satellite_runner  content-view add-repository --name='RHEL 5 CV x86_64' --organization-id="${ORG}" --product="${RHEL5_TOOLS_PRD}" --repository="${RHEL5_TOOLS_REPO}"
        satellite_runner  content-view add-repository --name='RHEL 5 CV s390x' --organization-id="${ORG}" --product="${RHEL5_TOOLS_S390X_PRD}" --repository="${RHEL5_TOOLS_S390X_REPO}"
        satellite_runner  content-view add-repository --name='RHEL 5 CV i386' --organization-id="${ORG}" --product="${RHEL5_TOOLS_I386_PRD}" --repository="${RHEL5_TOOLS_I386_REPO}"
        satellite --csv content-view list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "RHEL 5" | while read -r line ; do
            satellite_runner  content-view add-repository --name="${line}" --organization-id="${ORG}" --product="Errata-product" --repository="Errata-repo";
            satellite_runner  content-view publish --name="${line}" --organization-id="${ORG}";
            satellite_runner  content-view version promote --content-view="${line}" --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library";
        done
        satellite_runner  activation-key create --name 'ak-rhel-5' --content-view='RHEL 5 CV x86_64' --lifecycle-environment='DEV' --organization-id="${ORG}"
        satellite_runner  activation-key create --name 'ak-rhel-5-s390x' --content-view='RHEL 5 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"
        satellite_runner  activation-key create --name 'ak-rhel-5-i386' --content-view='RHEL 5 CV i386' --lifecycle-environment='DEV' --organization-id="${ORG}"
        if [ "${SATELLITE_DISTRIBUTION}" = "GA" ]; then
            satellite_runner  activation-key add-subscription --name='ak-rhel-5' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-5-s390x' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID_s390x}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-5-i386' --organization-id="${ORG}" --subscription-id="${RHEL_SUBS_ID}"
            satellite_runner activation-key content-override --name 'ak-rhel-5' --content-label "rhel-5-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
            satellite_runner activation-key content-override --name 'ak-rhel-5-s390x' --content-label "rhel-5-for-system-z-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
            satellite_runner activation-key content-override --name 'ak-rhel-5-i386' --content-label "rhel-5-server-satellite-tools-${SAT_VERSION}-rpms" --organization-id="${ORG}" --value "1"
        fi
        satellite --csv activation-key list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "ak-rhel-5" | while read -r line ; do
            satellite_runner  activation-key update --name ${line} --auto-attach no --organization-id="${ORG}";
        done
    fi

    # As SATELLITE TOOLS REPO is already part of RHEL subscription.
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        if [[ "${POPULATE_RHEL5}" = 'true' ]]; then
            # RHEL 5
            TOOLS5_SUBS_ID=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL5_TOOLS_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            TOOLS5_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL5_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            TOOLS5_SUBS_ID_i386=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL5_TOOLS_I386_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            satellite_runner  activation-key add-subscription --name='ak-rhel-5' --organization-id="${ORG}" --subscription-id="${TOOLS5_SUBS_ID}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-5-s390x' --organization-id="${ORG}" --subscription-id="${TOOLS5_SUBS_ID_s390x}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-5-i386' --organization-id="${ORG}" --subscription-id="${TOOLS5_SUBS_ID_i386}"
        fi
        if [[ "${POPULATE_RHEL6}" = 'true' ]]; then
            # RHEL 6
            TOOLS6_SUBS_ID_ppc64=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL6_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            TOOLS6_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL6_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            TOOLS6_SUBS_ID_i386=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL6_TOOLS_I386_PRD}" | awk -F "," '{print $1}' | grep -vi id)
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_ppc64}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-s390x' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_s390x}"
            satellite_runner  activation-key add-subscription --name='ak-rhel-6-i386' --organization-id="${ORG}" --subscription-id="${TOOLS6_SUBS_ID_i386}"
        fi
        TOOLS7_SUBS_ID_ppc64=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL7_TOOLS_PPC64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        TOOLS7_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL7_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-s390x' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID_s390x}"
        satellite_runner  activation-key add-subscription --name='ak-rhel-7-ppc64' --organization-id="${ORG}" --subscription-id="${TOOLS7_SUBS_ID_ppc64}"
    fi
    # Add subscription Errata-product to activation keys
    ERRATA_PRODUCT_SUBS_ID=$(satellite --csv subscription list --organization-id=${ORG} | grep -i "Errata-product" |  awk -F "," '{print $1}' | grep -vi id | head -n 1)
    satellite --csv activation-key list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' | while read -r line ; do
            satellite_runner  activation-key add-subscription --name="${line}" --organization-id="${ORG}" --subscription-id="${ERRATA_PRODUCT_SUBS_ID}";
        done
fi
#RHEL8
if [[ "${POPULATE_RHEL8}" = 'true' ]]; then
    if [ "${SATELLITE_DISTRIBUTION}" != "GA" ]; then
        create-repo "${RHEL8_TOOLS_PRD}" "${RHEL8_TOOLS_REPO}" "${RHEL8_TOOLS_URL}"
        create-repo "${RHEL8_TOOLS_S390X_PRD}" "${RHEL8_TOOLS_S390X_REPO}" "${RHEL8_TOOLS_S390X_URL}"
        create-repo "${RHEL8_TOOLS_PPC64LE_PRD}" "${RHEL8_TOOLS_PPC64LE_REPO}" "${RHEL8_TOOLS_PPC64LE_URL}"
        create-repo "${RHEL8_TOOLS_AARCH64_PRD}" "${RHEL8_TOOLS_AARCH64_REPO}" "${RHEL8_TOOLS_AARCH64_URL}"
    fi
    # Synchronize all repositories except for Puppet repositories which don't have URLs
    for repo in $(satellite --csv repository list --organization-id="${ORG}" --per-page=1000 | grep -vi 'puppet' | cut -d ',' -f 1 | grep -vi '^ID'); do
        satellite_runner repository synchronize --id "${repo}" --organization-id="${ORG}" --async
    done

    # Check the async tasks for completion.
    for id in `satellite --csv task list | grep -i synchronize | awk -F "," '{print $1}'`; do satellite_runner task progress --id $id; done

    #create content view
    for cv in 'RHEL 8 CV' 'RHEL 8 CV ppc64le' 'RHEL 8 CV s390x' 'RHEL 8 CV aarch64'; do satellite_runner content-view create --name="${cv}" --organization-id="${ORG}"; done

    satellite_runner  content-view add-repository --name='RHEL 8 CV' --organization-id="${ORG}" --product="${RHEL8_TOOLS_PRD}" --repository="${RHEL8_TOOLS_REPO}"
    satellite_runner  content-view add-repository --name='RHEL 8 CV ppc64le' --organization-id="${ORG}" --product="${RHEL8_TOOLS_PPC64LE_PRD}" --repository="${RHEL8_TOOLS_PPC64LE_REPO}"
    satellite_runner  content-view add-repository --name='RHEL 8 CV s390x' --organization-id="${ORG}" --product="${RHEL8_TOOLS_S390X_PRD}" --repository="${RHEL8_TOOLS_S390X_REPO}"
    satellite_runner  content-view add-repository --name='RHEL 8 CV aarch64' --organization-id="${ORG}" --product="${RHEL8_TOOLS_AARCH64_PRD}" --repository="${RHEL8_TOOLS_AARCH64_REPO}"

    satellite --csv content-view list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "RHEL 8" | while read -r line ; do
        satellite_runner  content-view add-repository --name="${line}" --organization-id="${ORG}" --product="Errata-product" --repository="Errata-repo"
        satellite_runner  content-view publish --name="${line}" --organization-id="${ORG}";
        satellite_runner  content-view version promote --content-view="${line}" --organization-id="${ORG}" --to-lifecycle-environment=DEV --from-lifecycle-environment="Library";
    done

    satellite_runner  activation-key create --name 'ak-rhel-8' --content-view='RHEL 8 CV' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-8-s390x' --content-view='RHEL 8 CV s390x' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-8-aarch64' --content-view='RHEL 8 CV aarch64' --lifecycle-environment='DEV' --organization-id="${ORG}"
    satellite_runner  activation-key create --name 'ak-rhel-8-ppc64le' --content-view='RHEL 8 CV ppc64le' --lifecycle-environment='DEV' --organization-id="${ORG}"

    TOOLS8_SUBS_ID=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL8_TOOLS_PRD}" | awk -F "," '{print $1}' | grep -vi id)
    TOOLS8_SUBS_ID_ppc64le=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL8_TOOLS_PPC64LE_PRD}" | awk -F "," '{print $1}' | grep -vi id)
    TOOLS8_SUBS_ID_s390x=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL8_TOOLS_S390X_PRD}" | awk -F "," '{print $1}' | grep -vi id)
    TOOLS8_SUBS_ID_aarch64=$(satellite  --csv subscription list --organization-id=${ORG} --search="name=${RHEL8_TOOLS_AARCH64_PRD}" | awk -F "," '{print $1}' | grep -vi id)
    satellite_runner  activation-key add-subscription --name='ak-rhel-8' --organization-id="${ORG}" --subscription-id="${TOOLS8_SUBS_ID}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-8-ppc64le' --organization-id="${ORG}" --subscription-id="${TOOLS8_SUBS_ID_ppc64le}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-8-s390x' --organization-id="${ORG}" --subscription-id="${TOOLS8_SUBS_ID_s390x}"
    satellite_runner  activation-key add-subscription --name='ak-rhel-8-aarch64' --organization-id="${ORG}" --subscription-id="${TOOLS8_SUBS_ID_aarch64}"

    satellite --csv activation-key list --organization-id="${ORG}" | cut -d ',' -f2 | grep -vi 'Name' |  grep "ak-rhel-8" | while read -r line ; do
            satellite_runner  activation-key update --name ${line} --auto-attach no --organization-id="${ORG}";
    done
fi
