# ML Pipelines

ML Pipelines is the Open Data Hub's pipeline solution for data scientists. It is built on top of the upstream [Kubeflow Piplines](https://github.com/kubeflow/pipelines) and [kfp-tekton](https://github.com/kubeflow/kfp-tekton) projects. The Open Data Hub community has a [fork](https://github.com/opendatahub-io/ml-pipelines) of this upstream under the Open Data Hub org.


## Installation

### Prerequisites

1. The cluster needs to be OpenShift 4.9 or higher
2. OpenShift Pipelines 1.7.2 or higher needs to be installed on the cluster
3. The Open Data Hub operator needs to be installed
4. The default installation namespace for ML Pipelines is `odh-applications`. This namespace will need to be created. In case you wish to install in a custom location, create it and update the kfdef as documented below.

### Installation Steps

1. Ensure that the prerequisites are met.
2. Apply the kfdef at [kfctl_openshift_ml-pipelines.yaml](https://github.com/opendatahub-io/odh-manifests/blob/master/kfdef/kfctl_openshift_ml-pipelines.yaml). You may need to update the `namespace` field under `metadata` in case you want to deploy in a namespace that isn't `odh-applications`.
3. To find the url for ML pipelines, you can run the following command.
    ```bash
    $ oc get route -n <kdef_namespace> ml-pipeline-ui -o jsonpath='{.spec.host}'
    ```
    The value of `<kfdef_namespace>` should match the namespace field of the kfdef that you applied.
4. Alternatively, you can access the route via the console. To do so:

    1. Go to `<kfdef_namespace>`
    2. Click on `Networking` in the sidebar on the left side.
    3. Click on `Routes`. It will take you to a new page in the console.
    4. Click the url under the `Location` column for the row item matching `ml-pipeline-ui`


## Directory Structure

### Base

This directory contains artifacts for deploying all backend components of ML Pipelines. This deployment currently includes the kfp-tekton backend as well as a Minio deployment to act as an object store. The Minio deployment will be moved to an overlay at some point in the near future.

### Overlays

1. metadata-store-mysql: This overlay contains artifacts for deploying a MySQL database. MySQL is currently the only supported backend for ML Pipelines, so if you don't have an existing MySQL database deployed, this overlay needs to be applied.
2. metadata-store-postgresql: This overlay contains artifacts for deploying a PostgreSQL database. ML Pipelines does not currently support PostgreSQL as a backend, so deploying this overlay will not actually modify ML Pipelines behaviour.
3. ml-pipeline-ui: This overlay contains deployment artifacts for the ML Pipelines UI. Deploying ML Pipelines without this overlay will result in only the backend artifacts being created.
4. object-store-minio: This overlay contains artifacts for deploying Minio as the Object Store to store Pipelines artifacts.

### Prometheus

This directory contains the service monitor definition for ML Pipelines. It is always deployed by base, so this will eventually be moved into the base directory itself.

## Configuration

* It is possible to configure what S3 storage is being used by Pipeline Runs. Detailed instructions on how to configure this will be added once Minio is moved to an overlay.

## Usage

### These instructions will be updated once ML Pipelines has a tile available in odh-dashboard

1. Go to the ml-pipelines-ui route.
2. Click on `Pipelines` on the left side.
3. There will be a `[Demo] flip-coin` Pipeline already available. Click on it.
4. Click on the blue `Create run` button towards the top of the screen.
5. You can leave all the fields untouched. If desired, you can create a new experiment to link the pipeline run to, or rename the run itself.
6. Click on the blue `Start` button.
7. You will be taken to the `Runs` page. You will see a row matching the `Run name` you previously picked. Click on the `Run name` in that row.
8. Once the Pipeline is done running, you can see a graph of all the pods that were created as well as the paths that were followed.
9. For further verification, you can view all the pods that were created as part of the Pipeline Run in the `<kfdef_namespace>`. They will all show up as `Completed`.

## ML Pipelines Architecture

A complete architecture can be found at [ODH ML Pipelines Architecture and Design](https://docs.google.com/document/d/1o-JS1uZKLZsMY3D16kl5KBdyBb-aV-kyD_XycdJOYpM/edit#heading=h.3aocw3evrps0). This document will be moved to GitHub once the corresponding ML Ops SIG repos are created.
