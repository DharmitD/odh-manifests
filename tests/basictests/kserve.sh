#!/bin/bash

source $TEST_DIR/common

MY_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)

source ${MY_DIR}/../util
RESOURCEDIR="${MY_DIR}/../resources"
TESTPROJECT=${TESTPROJECT:-"testproject"}
export TESTPROJECT

os::test::junit::declare_suite_start "$MY_SCRIPT"

function check_resources() {
    header "Testing kserve controller installation"
    os::cmd::expect_success "oc project ${ODHPROJECT}"
    os::cmd::try_until_text "oc get statefulset kserve-controller-manager" "kserve-controller-manager" $odhdefaulttimeout $odhdefaultinterval
    os::cmd::try_until_text "oc get pods -l control-plane=kserve-controller-manager --field-selector='status.phase=Running' -o jsonpath='{$.items[*].metadata.name}' | wc -w" "1" $odhdefaulttimeout $odhdefaultinterval #list the name of pods
    os::cmd::try_until_text "oc get service -l app=kserve -o jsonpath='{$.items[*].metadata.name}' | wc -w" "3" $odhdefaulttimeout $odhdefaultinterval
}

function setup_test_serving() {
  # creating an inference service
    header "Setting up test Kserve"
    os::cmd::expect_success "oc new-project ${TESTPROJECT}"
    os::cmd::expect_success "oc project ${TESTPROJECT}"
    os::cmd::expect_success "oc apply -f ${RESOURCEDIR}/kserve/tensorflow.yaml -n testproject"
    os::cmd::try_until_text "oc get pods -l app=isvc.flower-sample-predictor-default -o jsonpath='{$.items[*].metadata.name}' | wc -w" "1" $odhdefaulttimeout $odhdefaultinterval
}

function teardown_test_serving() {
    header "Tearing down test kserve serving"
    os::cmd::expect_success "oc delete project ${TESTPROJECT}"
}

function test_inferences() {
    header "Testing inference from example flower sample predictor model"
    sleep 20s
    oc expose service flower-sample-predictor-default -n testproject
    os::cmd::try_until_text "oc get route" "flower-sample" $odhdefaulttimeout $odhdefaultinterval

    ROUTE=$(oc get route flower-sample-predictor-default -n testproject --template={{.spec.host}})
    MODEL_NAME=flower-sample
    INPUT_PATH=@${RESOURCEDIR}/kserve/input.json
    os::cmd::try_until_text "curl -v http://$ROUTE/v1/models/$MODEL_NAME:predict -d $INPUT_PATH | jq '.predictions[0].prediction[0]'" "0" $odhdefaulttimeout $odhdefaultinterval

}

function setup_monitoring() {
    header "Enabling User Workload Monitoring on the cluster"
    oc apply -f ${RESOURCEDIR}/modelmesh/enable-uwm.yaml
}

setup_monitoring
check_resources
setup_test_serving
test_inferences
teardown_test_serving

os::test::junit::declare_suite_end
