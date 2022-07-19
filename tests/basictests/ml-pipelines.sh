#!/bin/bash

source $TEST_DIR/common

MY_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)

source ${MY_DIR}/../util
RESOURCEDIR="${MY_DIR}/../resources"

os::test::junit::declare_suite_start "$MY_SCRIPT"

function check_resources() {
    header "Testing Kubeflow pipelines installation"
    os::cmd::expect_success "oc project ${ODHPROJECT}"
    os::cmd::try_until_text "oc get pods -l application-crd-id=kubeflow-pipelines --field-selector='status.phase=Running' -o jsonpath='{$.items[*].metadata.name}' | wc -w" "10" $odhdefaulttimeout $odhdefaultinterval
}

function check_ui_overlay() {
    header "Checking UI overlay Kfdef deploys the UI"
    os::cmd::try_until_text "oc get pods -l app=ml-pipeline-ui --field-selector='status.phase=Running' -o jsonpath='{$.items[*].metadata.name}' | wc -w" "1" $odhdefaulttimeout $odhdefaultinterval
}

function create_pipeline() {
    header "Creating a pipeline"
    SVC=$(oc get route ml-pipeline --template={{.spec.host}})
    PIPELINE_ID=$(curl -F "uploadfile=@${RESOURCEDIR}/ml-pipelines/kfp-tekton.yaml" ${SVC}/apis/v1beta1/pipelines/upload | jq -r .id)
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/pipelines/${PIPELINE_ID} | jq '.name'" "kfp-tekton.yaml" $odhdefaulttimeout $odhdefaultinterval
}

function list_pipelines() {
    header "Listing pipelines"
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/pipelines | jq '.total_size'" "1" $odhdefaulttimeout $odhdefaultinterval #change to one
}

function create_run() {
    header "Creating a run"
    RUN_ID=$(curl -H "Content-Type: application/json" -X POST ${SVC}/apis/v1beta1/runs -d "{\"name\":\"kfp-tekton_run\", \"pipeline_spec\":{\"pipeline_id\":\"${PIPELINE_ID}\"}}" | jq -r .run.id)
}

function list_runs() {
    header "Listing runs"
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/runs | jq '.total_size'" "1" $odhdefaulttimeout $odhdefaultinterval
}

function check_run_status() {
    header "Checking run status"
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/runs/${RUN_ID} | jq '.run.status'" "Completed" $odhdefaulttimeout $odhdefaultinterval
}

function delete_runs() {
    header "Deleting runs"
    os::cmd::try_until_text "curl -X DELETE ${SVC}/apis/v1beta1/runs/${RUN_ID} | jq" "" $odhdefaulttimeout $odhdefaultinterval
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/runs/${RUN_ID} | jq '.code'" "5" $odhdefaulttimeout $odhdefaultinterval
}

function delete_pipeline() {
    header "Deleting the pipeline"
    os::cmd::try_until_text "curl -X DELETE ${SVC}/apis/v1beta1/pipelines/${PIPELINE_ID} | jq" "" $odhdefaulttimeout $odhdefaultinterval
    os::cmd::try_until_text "curl ${SVC}/apis/v1beta1/pipelines/${PIPELINE_ID} | jq '.code'" "5" $odhdefaulttimeout $odhdefaultinterval
    os::cmd::try_until_text "oc get PipelineRun" "No resources found" $odhdefaulttimeout $odhdefaultinterval
    os::cmd::try_until_text "oc get TaskRun" "No resources found" $odhdefaulttimeout $odhdefaultinterval
}

check_resources
#check_ui_overlay
create_pipeline
list_pipelines
create_run
list_runs
check_run_status
delete_runs
delete_pipeline

os::test::junit::declare_suite_end
