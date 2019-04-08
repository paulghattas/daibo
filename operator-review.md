# Prerequisites

## Cluster Access

For "upstream" operators:
* A running Kubernetes cluster; [minikube](https://kubernetes.io/docs/setup/minikube/) is the simplest approach

For "community" operators:
* A running Kubernetes cluster; [minikube](https://kubernetes.io/docs/setup/minikube/) is the simplest approach
* Access to a running OpenShift 4 cluster

## Repositories

The following repositories are used throughout the process and should be cloned locally:

* [Community Operators](https://github.com/operator-framework/community-operators)
* [Operator Marketplace](https://github.com/operator-framework/operator-marketplace)
* [Operator Courier](https://github.com/operator-framework/operator-courier)
* [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager)

For simplicity, the following commands will clone all of the repositories above:

```
git clone https://github.com/operator-framework/community-operators.git
git clone https://github.com/operator-framework/operator-marketplace.git
git clone https://github.com/operator-framework/operator-courier.git
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
```

## Other

### Operator Courier Installation

Operator Courier is used for metadata syntax checking and validation. This can be installed directly from `pip`:

```
pip3 install operator-courier
```

### Quay Token

In order to push operators into your quay.io account, a token is needed. This only needs to be done once and can be saved locally. The Operator Courier repository has a script to retrieve the token:

```
cd $COURIER_DIR
./scripts/get-quay-token
```

A token takes the form:

```
"basic abcdefghijkl=="
```

# Install and Configure Kubernetes

Optionally, delete the previous Kubernetes cluster:

```
minikube delete
```

Start the Kubernetes cluster:

```
minikube start
```

## Install OLM

Install OLM into the cluster and remove the default catalog source (a testing catalog source will be created later):

> Note: The first time the apply command is run, there may be errors. Simply run the command again to finish the OLM installation.

```
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.8.1/olm.yaml

kubectl delete catalogsource -n olm operatorhubio-catalog
```

## Install the Operator Marketplace

Install the Operator Marketplace. Unlike OLM, this is installed from a previously cloned repository. The second command here validates the installation by ensuring a `marketplace` namespace has been created.

```
kubectl apply -f operator-marketplace/deploy/upstream/ --validate=false

kubectl get ns | grep marketplace
```

At this point, the Kubernetes cluster is running and configured with the necessary pieces.

## Create the OperatorSource

An `OperatorSource` is used to define the external datastore we are using to store operator bundles. More information can be found in the documentation included in the Operator Marketplace repository.

An example can be found in the Operator Marketplace repository under `deploy/examples/upstream.operatorsource.cr.yaml`. The only required change is that `registryNamespace` _must_ be set to your quay.io username so the OperatorSource can find your uploaded operator bundles.

Example (where `jdob` is the quay.io user):

```
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: upstream-community-operators
  namespace: marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: jdob
  displayName: "Upstream Community Operators"
  publisher: "Red Hat"
```

Once the YAML has been changed, add it to the cluster:

```
OPERATOR_SOURCE=operator-source.yaml

kubectl apply -f $OPERATOR_SOURCE
```

## View Available Operators

Once the OperatorSource is deployed, the following command can be used to list the available operators (until an operator is pushed into quay, this list will be empty):

```
SOURCE_NAME=upstream-community-operators

kubectl get opsrc $SOURCE_NAME -o=custom-columns=NAME:.metadata.name,PACKAGES:.status.packages -n marketplace
```

# Metadata Validation

## Download the Operator Pull Request

Within the local clone of the `community-operators` repository, check out the pull request locally. The following commands will create a new local branch named with the value in `PR_BRANCH` as it downloads the PR changes and then switches to that branch:

> The PR_ID value is listed after the pull request name in GitHub. Do not include the #.

```
PR_BRANCH=my-operator-pr
PR_ID=12345

git fetch origin pull/$PR_ID/head:$PR_BRANCH
git checkout $PR_BRANCH
```

## Run Courier

Courier will verify the fields included in the Operator metadata. The fields can also be manually reviewed according to [the operator CSV documentation](https://github.com/operator-framework/community-operators/blob/master/docs/required-fields.md).

The following command will run Courier against the directory specified in `OPERATOR_DIR`. That value should point to the directory with the operator file bundle.

```
OPERATOR_DIR=./upstream-community-operators/synopsys

operator-courier verify $OPERATOR_DIR --ui_validate_io
```

If there is no output, the bundle passed Courier validation.

# Testing the Running Operator

## Push the Operator into Quay

The Operator will be built locally and pushed into the tester's namespace in [quay.io](http://quay.io).

> The value for `PACKAGE_NAME` *must* be the same as in the operator's `*package.yaml` file. Assuming `OPERATOR_DIR` is specified, this can be found by running `cat $OPERATOR_DIR/*.package.yaml`.

> The `PACKAGE_VERSION` is entirely up to the tester to decide.

```
OPERATOR_DIR=./upstream-community-operators/synopsys
QUAY_USERNAME=jdob
PACKAGE_NAME=<see note above>
PACKAGE_VERSION=<see note above>
TOKEN=<full token from quay, including quotes and the word basic>

operator-courier push $OPERATOR_DIR $QUAY_USERNAME $PACKAGE_NAME $PACKAGE_VERSION $TOKEN
```

Once that has completed, you should see it listed in your account's [Applications](https://quay.io/application/) tab.

> If the application has a lock icon, click through to the application and its Settings tab and select to make the application public.

## Redeploy the Operator Source

When operators are pushed to quay.io, the `OperatorSource` may not pick them up. Simply edit the source and remove the `status` field to trigger a redeployment and clear the cache:

```
SOURCE_NAME=upstream-community-operators

kubectl edit opsrc -n marketplace $SOURCE_NAME
```

Once that has been saved, check the marketplace namespace to ensure that the operator source pod is being redeployed:

```
kubectl get pods -n marketplace
```

## Create CatalogSourceConfig

Once the OperatorSource has been added, images will be pulled from quay.io. A `CatalogSourceConfig` needs to be created in the marketplace namespace to install those Operators.

An example CatalogSourceConfig is as follows:

```
apiVersion: operators.coreos.com/v1
kind: CatalogSourceConfig
metadata:
  name: upstream-community-operators
  namespace: marketplace
spec:
  targetNamespace: local-operators
  packages: descheduler,jaeger
  csDisplayName: "Upstream Community Operators"
  csPublisher: "Red Hat"
```

In the above example:

* `local-operators` is a namespace that OLM is watching.
* `packages` is a comma-separated list of operators that have been pushed to quay.io and should be deployable by this source.

Deploy te `CatalogSourceConfig` resource:

```
CATALOG_SOURCE=./catalog-source-config.yaml

kubectl apply -f
```

When this file is deployed, a `CatalogSourceConfig` resource is created in the namespace under `metadata.namespace` (in the above example, "marketplace").

```
kubectl get catalogsourceconfig -n marketplace
NAME                                           STATUS      MESSAGE                                       AGE
upstream-community-operators         Succeeded   The object has been successfully reconciled   93s
```

Additionally, a `CatalogSource` is created in the namespace indicated in `spec.targetNamespace` (in the above example, "local-operators"):

```
kubectl get catalogsource -n local-operators
NAME                           NAME                           TYPE   PUBLISHER   AGE
upstream-community-operators   Upstream Community Operators   grpc   Red Hat     3m32s
```

Note that there is no `CatalogSourceConfig` object present in the target namespace and there is no `CatalogSource` corresponding to this config in the metadata-defined namespace:

```
kubectl get catalogsourceconfig -n local-operators

kubectl get catalogsource -n marketplace
```

